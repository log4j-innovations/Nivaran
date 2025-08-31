import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMTokenRefreshService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Force refresh FCM token and clean up old tokens
  static Future<Map<String, dynamic>> forceRefreshToken() async {
    final results = <String, dynamic>{};

    try {
      final user = _auth.currentUser;
      if (user == null) {
        results['error'] = 'No authenticated user';
        return results;
      }

      log('🔄 Starting FCM token refresh...', name: 'FCMRefresh');

      // Step 1: Clean up old tokens from Firestore
      await _cleanupOldTokens(user.uid);
      results['old_tokens_cleaned'] = true;

      // Step 2: Delete current FCM token to force refresh
      try {
        await _messaging.deleteToken();
        log('🗑️ Deleted old FCM token', name: 'FCMRefresh');
        await Future.delayed(Duration(seconds: 3)); // Wait for deletion
        results['old_token_deleted'] = true;
      } catch (e) {
        log('⚠️ Could not delete old token: $e', name: 'FCMRefresh');
        results['old_token_delete_error'] = e.toString();
      }

      // Step 3: Request fresh permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      results['permission_status'] = settings.authorizationStatus.toString();

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        results['error'] = 'Permissions not granted';
        return results;
      }

      // Step 4: Get fresh token with validation
      String? newToken;
      for (int attempt = 1; attempt <= 5; attempt++) {
        try {
          log(
            '🔄 Getting fresh token, attempt $attempt...',
            name: 'FCMRefresh',
          );
          newToken = await _messaging.getToken();

          if (newToken != null && _isValidToken(newToken)) {
            log(
              '✅ Valid fresh token obtained: ${newToken.substring(0, 20)}...',
              name: 'FCMRefresh',
            );
            break;
          } else {
            log('⚠️ Invalid token on attempt $attempt', name: 'FCMRefresh');
            newToken = null;
          }

          await Future.delayed(Duration(seconds: 2));
        } catch (e) {
          log(
            '❌ Error getting token on attempt $attempt: $e',
            name: 'FCMRefresh',
          );
          await Future.delayed(Duration(seconds: 2));
        }
      }

      if (newToken == null) {
        results['error'] = 'Failed to get valid fresh token';
        return results;
      }

      results['new_token'] = newToken;
      results['token_length'] = newToken.length;
      results['token_preview'] = '${newToken.substring(0, 20)}...';

      // Step 5: Store fresh token in Firestore
      await _storeTokenInFirestore(user.uid, newToken);
      results['token_stored'] = true;

      // Step 6: Verify token was stored
      final verification = await _verifyTokenStored(user.uid, newToken);
      results['token_verified'] = verification;

      results['success'] = true;
      results['message'] = 'FCM token refreshed successfully!';

      log('🎉 FCM token refresh completed successfully!', name: 'FCMRefresh');
      return results;
    } catch (e, stackTrace) {
      results['error'] = e.toString();
      results['stack_trace'] = stackTrace.toString();
      log('❌ Error in FCM token refresh: $e', name: 'FCMRefresh');
      return results;
    }
  }

  /// Validate if token has correct format
  static bool _isValidToken(String token) {
    return token.isNotEmpty &&
        token.length > 100 &&
        token.contains(':') &&
        !token.contains(' ') &&
        token.split(':').length >= 4;
  }

  /// Clean up old tokens from Firestore
  static Future<void> _cleanupOldTokens(String userId) async {
    try {
      // Clean from FCM tokens collection
      final fcmTokensRef = _firestore.collection('fcmTokens').doc(userId);
      await fcmTokensRef.delete();
      log('🧹 Cleaned FCM tokens collection', name: 'FCMRefresh');

      // Clean from user document
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({'notificationTokens': FieldValue.delete()});
      log('🧹 Cleaned user document tokens', name: 'FCMRefresh');
    } catch (e) {
      log('⚠️ Error cleaning old tokens: $e', name: 'FCMRefresh');
    }
  }

  /// Store token in Firestore
  static Future<void> _storeTokenInFirestore(
    String userId,
    String token,
  ) async {
    try {
      // Store in FCM tokens collection
      await _firestore.collection('fcmTokens').doc(userId).set({
        'userId': userId,
        'tokens': [token],
        'lastUpdated': FieldValue.serverTimestamp(),
        'tokenRefreshedAt': FieldValue.serverTimestamp(),
      });

      // Also store in user document as backup
      await _firestore.collection('users').doc(userId).update({
        'notificationTokens': [token],
        'lastTokenRefresh': FieldValue.serverTimestamp(),
      });

      log('💾 Fresh token stored in Firestore', name: 'FCMRefresh');
    } catch (e) {
      log('❌ Error storing token: $e', name: 'FCMRefresh');
      rethrow;
    }
  }

  /// Verify token was stored correctly
  static Future<bool> _verifyTokenStored(String userId, String token) async {
    try {
      final fcmDoc = await _firestore.collection('fcmTokens').doc(userId).get();
      if (fcmDoc.exists) {
        final tokens = fcmDoc.data()?['tokens'] as List<dynamic>?;
        return tokens?.contains(token) ?? false;
      }
      return false;
    } catch (e) {
      log('❌ Error verifying token: $e', name: 'FCMRefresh');
      return false;
    }
  }

  /// Get current token status
  static Future<Map<String, dynamic>> getTokenStatus() async {
    final status = <String, dynamic>{};

    try {
      final user = _auth.currentUser;
      if (user == null) {
        status['error'] = 'No authenticated user';
        return status;
      }

      // Get current token
      final currentToken = await _messaging.getToken();
      status['has_current_token'] = currentToken != null;
      status['current_token_valid'] =
          currentToken != null ? _isValidToken(currentToken) : false;
      status['current_token_length'] = currentToken?.length ?? 0;
      status['current_token_preview'] =
          currentToken != null ? '${currentToken.substring(0, 20)}...' : null;

      // Check Firestore storage
      final fcmDoc =
          await _firestore.collection('fcmTokens').doc(user.uid).get();
      status['stored_in_fcm_collection'] = fcmDoc.exists;

      if (fcmDoc.exists) {
        final storedTokens = fcmDoc.data()?['tokens'] as List<dynamic>?;
        status['stored_tokens_count'] = storedTokens?.length ?? 0;
        status['current_token_in_storage'] =
            storedTokens?.contains(currentToken) ?? false;
      }

      return status;
    } catch (e) {
      status['error'] = e.toString();
      return status;
    }
  }
}
