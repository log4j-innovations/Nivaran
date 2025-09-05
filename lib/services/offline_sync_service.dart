// lib/services/offline_sync_service.dart
import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/local_issue_model.dart';
import '../models/issue_model.dart';
import '../models/app_user_model.dart';
import 'local_data_service.dart';
import 'connectivity_service.dart';
import 'firestore_service.dart';
import 'image_upload_service.dart';

class OfflineSyncService extends ChangeNotifier {
  final LocalDataService _localDataService = LocalDataService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  late final ConnectivityService _connectivityService;

  bool _isSyncing = false;
  String _syncStatus = '';
  int _totalToSync = 0;
  int _syncedCount = 0;

  // Singleton pattern
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService(ConnectivityService connectivityService) {
    _instance._connectivityService = connectivityService;
    return _instance;
  }
  OfflineSyncService._internal();

  bool get isSyncing => _isSyncing;
  String get syncStatus => _syncStatus;
  double get syncProgress =>
      _totalToSync > 0 ? _syncedCount / _totalToSync : 0.0;
  int get totalToSync => _totalToSync;
  int get syncedCount => _syncedCount;

  // Check if there are unsynced issues without loading them
  Future<bool> hasUnsyncedIssues() async {
    try {
      final stats = await _localDataService.getDatabaseStats();
      return stats['unsynced']! > 0;
    } catch (e) {
      developer.log(
        'Error checking for unsynced issues: $e',
        name: 'OfflineSyncService',
      );
      return false;
    }
  }

  // Initialize the service
  Future<void> initialize() async {
    try {
      await _localDataService.initializeDatabase();

      // Register for auto-sync when connectivity is restored
      _connectivityService.setAutoSyncCallback(() {
        _triggerAutoSync();
      });

      developer.log(
        'OfflineSyncService initialized with auto-sync callback',
        name: 'OfflineSyncService',
      );
    } catch (e) {
      developer.log(
        'Error initializing OfflineSyncService: $e',
        name: 'OfflineSyncService',
      );
      rethrow;
    }
  }

  // Trigger automatic sync when connectivity is restored
  void _triggerAutoSync() async {
    developer.log(
      'Auto-sync triggered by connectivity restoration',
      name: 'OfflineSyncService',
    );

    // Check if there are unsynced issues before starting sync
    final unsyncedIssues = await getUnsyncedIssues();
    if (unsyncedIssues.isNotEmpty) {
      developer.log(
        'Found ${unsyncedIssues.length} unsynced issues, starting auto-sync',
        name: 'OfflineSyncService',
      );
      await syncUnsyncedIssues();
    } else {
      developer.log(
        'No unsynced issues found, skipping auto-sync',
        name: 'OfflineSyncService',
      );
    }
  }

  // Save issue offline with local image storage
  Future<String> saveIssueOffline({
    required String description,
    required String category,
    required String urgency,
    required List<String> tags,
    required String imagePath,
    required LocationModel location,
    required AppUser user,
  }) async {
    try {
      developer.log('Saving issue offline', name: 'OfflineSyncService');

      // Generate unique local ID
      final localId = const Uuid().v4();

      // Store image locally
      final localImagePath = await _storeImageLocally(imagePath, localId);

      // Create LocalIssue
      final localIssue = LocalIssue(
        localId: localId,
        description: description,
        category: category,
        urgency: urgency, // Will be "Medium" for offline issues
        tags: tags,
        localImagePath: localImagePath,
        timestamp: DateTime.now(),
        location: location,
        userId: user.uid,
        username: user.username ?? 'Unknown User',
        status: 'Reported',
        isSynced: false,
        metadata: {'created_offline': true, 'app_version': '2.0.2'},
      );

      // Save to local database
      await _localDataService.insertIssue(localIssue);

      developer.log(
        'Issue saved offline with ID: $localId',
        name: 'OfflineSyncService',
      );
      return localId;
    } catch (e) {
      developer.log(
        'Error saving issue offline: $e',
        name: 'OfflineSyncService',
      );
      rethrow;
    }
  }

  // Store image locally in app documents directory
  Future<String> _storeImageLocally(String sourcePath, String localId) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final offlineImagesDir = Directory('${appDocDir.path}/offline_images');

      // Create directory if it doesn't exist
      if (!await offlineImagesDir.exists()) {
        await offlineImagesDir.create(recursive: true);
      }

      // Copy image to local storage with unique name
      final sourceFile = File(sourcePath);
      final extension = sourcePath.split('.').last;
      final localImagePath =
          '${offlineImagesDir.path}/${localId}_original.$extension';

      await sourceFile.copy(localImagePath);

      developer.log(
        'Image stored locally: $localImagePath',
        name: 'OfflineSyncService',
      );
      return localImagePath;
    } catch (e) {
      developer.log(
        'Error storing image locally: $e',
        name: 'OfflineSyncService',
      );
      rethrow;
    }
  }

  // Get all unsynced issues
  Future<List<LocalIssue>> getUnsyncedIssues() async {
    try {
      return await _localDataService.getUnsyncedIssues();
    } catch (e) {
      developer.log(
        'Error getting unsynced issues: $e',
        name: 'OfflineSyncService',
      );
      return [];
    }
  }

  // Delete unsynced issue
  Future<void> deleteUnsyncedIssue(String localId) async {
    try {
      // Get the issue first to delete its local image
      final issue = await _localDataService.getLocalIssue(localId);
      if (issue != null && issue.localImagePath != null) {
        final imageFile = File(issue.localImagePath!);
        if (await imageFile.exists()) {
          await imageFile.delete();
          developer.log(
            'Deleted local image: ${issue.localImagePath}',
            name: 'OfflineSyncService',
          );
        }
      }

      // Delete from database
      await _localDataService.deleteLocalIssue(localId);
      developer.log(
        'Deleted unsynced issue: $localId',
        name: 'OfflineSyncService',
      );

      notifyListeners();
    } catch (e) {
      developer.log(
        'Error deleting unsynced issue: $e',
        name: 'OfflineSyncService',
      );
      rethrow;
    }
  }

  // Sync all unsynced issues when connectivity is restored
  Future<void> syncUnsyncedIssues() async {
    if (_isSyncing) {
      developer.log('Sync already in progress', name: 'OfflineSyncService');
      return;
    }

    try {
      // Check connectivity
      final connectivityResult = await _connectivityService.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        developer.log(
          'No connectivity, skipping sync',
          name: 'OfflineSyncService',
        );
        return;
      }

      _isSyncing = true;
      _syncedCount = 0;
      _syncStatus = 'Starting sync...';
      notifyListeners();

      final unsyncedIssues = await _localDataService.getUnsyncedIssues();
      _totalToSync = unsyncedIssues.length;

      if (_totalToSync == 0) {
        _syncStatus = 'All issues are up to date';
        _isSyncing = false;
        notifyListeners();
        developer.log('No issues to sync', name: 'OfflineSyncService');
        return;
      }

      developer.log(
        'Starting sync of ${_totalToSync} issues',
        name: 'OfflineSyncService',
      );
      _syncStatus =
          'Syncing $_totalToSync issue${_totalToSync > 1 ? 's' : ''}...';
      notifyListeners();

      int failedCount = 0;
      for (final issue in unsyncedIssues) {
        try {
          _syncStatus = 'Syncing issue ${_syncedCount + 1} of $_totalToSync...';
          notifyListeners();

          await _syncSingleIssue(issue);
          _syncedCount++;

          developer.log(
            'Synced issue ${issue.localId} (${_syncedCount}/$_totalToSync)',
            name: 'OfflineSyncService',
          );
        } catch (e) {
          failedCount++;
          developer.log(
            'Failed to sync issue ${issue.localId}: $e',
            name: 'OfflineSyncService',
          );
          await _localDataService.updateIssueSyncError(
            issue.localId,
            e.toString(),
          );
        }
      }

      // Set final sync status message
      if (failedCount == 0) {
        _syncStatus =
            'Sync complete! $_syncedCount issue${_syncedCount > 1 ? 's' : ''} synced successfully';
      } else if (_syncedCount > 0) {
        _syncStatus =
            'Sync completed with issues: $_syncedCount synced, $failedCount failed';
      } else {
        _syncStatus = 'Sync failed: Unable to sync any issues';
      }

      developer.log(
        'Sync completed: $_syncedCount/$_totalToSync issues synced, $failedCount failed',
        name: 'OfflineSyncService',
      );
    } catch (e) {
      _syncStatus = 'Sync failed: $e';
      developer.log('Sync failed: $e', name: 'OfflineSyncService');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Sync a single issue
  Future<void> _syncSingleIssue(LocalIssue localIssue) async {
    try {
      String? imageUrl;

      // Upload image if it exists locally
      if (localIssue.localImagePath != null) {
        final imageFile = File(localIssue.localImagePath!);
        if (await imageFile.exists()) {
          imageUrl = await _imageUploadService.uploadImage(imageFile);
          if (imageUrl == null) {
            throw Exception('Failed to upload image');
          }
        }
      }

      // Prepare issue data for Firebase
      final issueData = {
        'description': localIssue.description,
        'category': localIssue.category,
        'urgency': localIssue.urgency,
        'tags': localIssue.tags.isNotEmpty ? localIssue.tags : null,
        'imageUrl': imageUrl ?? '',
        'timestamp': localIssue.timestamp,
        'location': {
          'latitude': localIssue.location.latitude,
          'longitude': localIssue.location.longitude,
          'address': localIssue.location.address,
        },
        'userId': localIssue.userId,
        'username': localIssue.username,
        'status': localIssue.status,
        'isUnresolved': true,
        'assignedDepartment': _getDefaultDepartment(localIssue.category),
        'upvotes': 0,
        'downvotes': 0,
        'voters': {},
        'commentsCount': 0,
        'affectedUsersCount': 1,
        'affectedUserIds': [localIssue.userId],
        'metadata': {
          ...localIssue.metadata,
          'synced_from_offline': true,
          'original_timestamp': localIssue.timestamp.toIso8601String(),
        },
      };

      // Add to Firebase
      final firebaseId = await _firestoreService.addIssueWithId(issueData);

      // Update local issue as synced
      await _localDataService.updateIssueSync(localIssue.localId, firebaseId);

      // Clean up local image after successful sync
      if (localIssue.localImagePath != null) {
        final imageFile = File(localIssue.localImagePath!);
        if (await imageFile.exists()) {
          await imageFile.delete();
          developer.log(
            'Cleaned up local image after sync: ${localIssue.localImagePath}',
            name: 'OfflineSyncService',
          );
        }
      }
    } catch (e) {
      developer.log(
        'Error syncing single issue: $e',
        name: 'OfflineSyncService',
      );
      rethrow;
    }
  }

  // Get default department for category (simplified mapping)
  String _getDefaultDepartment(String category) {
    switch (category.toLowerCase()) {
      case 'roads':
      case 'traffic':
        return 'Public Works Department';
      case 'water':
      case 'drainage':
        return 'Water Department';
      case 'electricity':
        return 'Electricity Board';
      case 'waste':
      case 'sanitation':
        return 'Sanitation Department';
      case 'parks':
        return 'Parks Department';
      default:
        return 'General Administration';
    }
  }

  // Cache online issues for offline viewing
  Future<void> cacheIssuesForOffline(List<Issue> issues) async {
    try {
      await _localDataService.cacheOnlineIssues(issues);
      developer.log(
        'Cached ${issues.length} issues for offline viewing',
        name: 'OfflineSyncService',
      );
    } catch (e) {
      developer.log('Error caching issues: $e', name: 'OfflineSyncService');
    }
  }

  // Get cached issues for offline viewing
  Future<List<Issue>> getCachedIssues() async {
    try {
      final localIssues = await _localDataService.getCachedIssues();
      return localIssues.map((localIssue) => localIssue.toIssue()).toList();
    } catch (e) {
      developer.log(
        'Error getting cached issues: $e',
        name: 'OfflineSyncService',
      );
      return [];
    }
  }

  // Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    return await _localDataService.getDatabaseStats();
  }

  // Clean up old cached data
  Future<void> cleanupOldCache({int daysToKeep = 7}) async {
    try {
      await _localDataService.clearOldCache(daysToKeep: daysToKeep);
      developer.log('Cleaned up old cached data', name: 'OfflineSyncService');
    } catch (e) {
      developer.log('Error cleaning up cache: $e', name: 'OfflineSyncService');
    }
  }
}
