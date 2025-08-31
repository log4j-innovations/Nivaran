// lib/utils/offline_first_data_loader.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/issue_model.dart';
import '../models/app_user_model.dart';
import '../models/notification_model.dart';

/// Utility class to prevent Firebase operations from hanging when offline
/// by implementing timeout-based fallbacks to cached/local data
class OfflineFirstDataLoader {
  static const Duration firebaseTimeout = Duration(seconds: 5);
  
  /// Generic method to load data with fallback mechanism
  static Future<T> loadWithFallback<T>({
    required Future<T> Function() onlineLoader,
    required Future<T> Function() offlineLoader,
    Duration timeout = firebaseTimeout,
  }) async {
    try {
      developer.log("OfflineFirstDataLoader: Attempting online load with ${timeout.inSeconds}s timeout", 
          name: "OfflineFirstDataLoader");
      
      return await onlineLoader().timeout(timeout);
    } on TimeoutException {
      developer.log("OfflineFirstDataLoader: Online load timed out, falling back to offline data", 
          name: "OfflineFirstDataLoader");
      return await offlineLoader();
    } catch (e) {
      developer.log("OfflineFirstDataLoader: Online load failed with error: $e, falling back to offline data", 
          name: "OfflineFirstDataLoader");
      return await offlineLoader();
    }
  }

  /// Load issues with timeout fallback to empty list
  static Future<List<Issue>> loadIssuesWithFallback() async {
    return loadWithFallback<List<Issue>>(
      onlineLoader: () async {
        final snapshot = await FirebaseFirestore.instance
            .collection('issues')
            .orderBy('timestamp', descending: true)
            .limit(50) // Limit to prevent large downloads
            .get();
        
        return snapshot.docs.map((doc) {
          final issueData = doc.data();
          return Issue.fromFirestore(issueData, doc.id);
        }).toList();
      },
      offlineLoader: () async {
        // Return empty list for now - will be enhanced in later tasks with local storage
        developer.log("OfflineFirstDataLoader: Returning empty issues list for offline mode", 
            name: "OfflineFirstDataLoader");
        return <Issue>[];
      },
    );
  }

  /// Load user profile with timeout fallback to cached profile
  static Future<AppUser?> loadUserProfileWithFallback(User authUser) async {
    return loadWithFallback<AppUser?>(
      onlineLoader: () async {
        final tokenResult = await authUser.getIdTokenResult(true);
        final claims = tokenResult.claims;

        final userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(authUser.uid)
            .get();

        if (userDoc.exists) {
          return AppUser.fromFirestore(userDoc, authUser, claims);
        } else {
          // Create basic profile if doesn't exist
          final basicProfile = AppUser(
            uid: authUser.uid,
            email: authUser.email ?? '',
            username: claims?['name'] as String? ?? 
                     authUser.displayName?.split(' ').first ?? 
                     authUser.email?.split('@').first ?? 'User',
            fullName: claims?['name'] as String? ?? 
                     authUser.displayName ?? 
                     authUser.email?.split('@').first,
            role: claims?['role'] as String? ?? 'user',
            department: claims?['department'] as String?,
            profilePhotoUrl: authUser.photoURL,
            createdAt: Timestamp.now(),
          );
          
          // Try to save but don't wait for it
          FirebaseFirestore.instance
              .collection("users")
              .doc(authUser.uid)
              .set(basicProfile.toMap(), SetOptions(merge: true))
              .catchError((error) => developer.log("Failed to save basic profile: $error"));
          
          return basicProfile;
        }
      },
      offlineLoader: () async {
        // Try to load cached profile data
        final prefs = await SharedPreferences.getInstance();
        final cachedUid = prefs.getString('cached_user_uid');
        
        if (cachedUid == authUser.uid) {
          // Return a basic profile based on auth user data
          developer.log("OfflineFirstDataLoader: Returning cached profile for ${authUser.uid}", 
              name: "OfflineFirstDataLoader");
          
          return AppUser(
            uid: authUser.uid,
            email: authUser.email ?? '',
            username: authUser.displayName?.split(' ').first ?? 
                     authUser.email?.split('@').first ?? 'User',
            fullName: authUser.displayName ?? authUser.email?.split('@').first,
            role: 'user', // Default role when offline
            department: null,
            profilePhotoUrl: authUser.photoURL,
            createdAt: Timestamp.now(),
          );
        }
        
        return null;
      },
    );
  }

  /// Load notifications with timeout fallback to empty list
  static Future<List<NotificationModel>> loadNotificationsWithFallback(String userId) async {
    return loadWithFallback<List<NotificationModel>>(
      onlineLoader: () async {
        final snapshot = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(20)
            .get();
        
        return snapshot.docs.map((doc) {
          return NotificationModel.fromFirestore(doc);
        }).toList();
      },
      offlineLoader: () async {
        // Return empty list for now - will be enhanced in later tasks
        developer.log("OfflineFirstDataLoader: Returning empty notifications list for offline mode", 
            name: "OfflineFirstDataLoader");
        return <NotificationModel>[];
      },
    );
  }

  /// Create a timeout-wrapped stream that falls back to empty stream
  static Stream<T> createTimeoutStream<T>({
    required Stream<T> Function() streamBuilder,
    required T fallbackValue,
    Duration timeout = firebaseTimeout,
  }) {
    final controller = StreamController<T>();
    
    // Start with fallback value
    controller.add(fallbackValue);
    
    // Try to get real stream with timeout
    Timer? timeoutTimer;
    StreamSubscription? subscription;
    
    timeoutTimer = Timer(timeout, () {
      developer.log("OfflineFirstDataLoader: Stream timed out, using fallback value", 
          name: "OfflineFirstDataLoader");
      if (!controller.isClosed) {
        controller.add(fallbackValue);
      }
    });
    
    try {
      subscription = streamBuilder().listen(
        (data) {
          timeoutTimer?.cancel();
          if (!controller.isClosed) {
            controller.add(data);
          }
        },
        onError: (error) {
          timeoutTimer?.cancel();
          developer.log("OfflineFirstDataLoader: Stream error: $error, using fallback", 
              name: "OfflineFirstDataLoader");
          if (!controller.isClosed) {
            controller.add(fallbackValue);
          }
        },
      );
    } catch (e) {
      timeoutTimer.cancel();
      developer.log("OfflineFirstDataLoader: Failed to create stream: $e, using fallback", 
          name: "OfflineFirstDataLoader");
      if (!controller.isClosed) {
        controller.add(fallbackValue);
      }
    }
    
    controller.onCancel = () {
      timeoutTimer?.cancel();
      subscription?.cancel();
    };
    
    return controller.stream;
  }
}