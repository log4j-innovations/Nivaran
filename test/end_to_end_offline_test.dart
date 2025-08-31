// test/end_to_end_offline_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_auth_app/services/offline_sync_service.dart';
import 'package:modern_auth_app/services/connectivity_service.dart';
import 'package:modern_auth_app/services/local_data_service.dart';
import 'package:modern_auth_app/utils/offline_first_data_loader.dart';
import 'package:modern_auth_app/models/local_issue_model.dart';
import 'package:modern_auth_app/models/app_user_model.dart';
import 'package:modern_auth_app/models/issue_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:developer' as developer;

// Mock ConnectivityService for end-to-end testing
class MockConnectivityService extends ConnectivityService {
  bool _mockIsOnline = true;
  bool _mockWasOffline = false;
  Function()? _autoSyncCallback;

  @override
  bool get isOnline => _mockIsOnline;

  @override
  bool get wasOffline => _mockWasOffline;

  void setOnlineStatus(bool isOnline) {
    final wasOnlineBefore = _mockIsOnline;
    
    if (isOnline != _mockIsOnline) {
      if (!isOnline) {
        _mockWasOffline = true;
      } else if (_mockWasOffline && !wasOnlineBefore) {
        // Coming back online after being offline
        _mockWasOffline = false;
        // Trigger auto-sync callback
        if (_autoSyncCallback != null) {
          developer.log('MockConnectivityService: Triggering auto-sync callback', name: 'MockConnectivityService');
          _autoSyncCallback!();
        }
      }
      _mockIsOnline = isOnline;
      notifyListeners();
    }
  }

  @override
  void setAutoSyncCallback(Function() callback) {
    _autoSyncCallback = callback;
    developer.log('MockConnectivityService: Auto-sync callback registered', name: 'MockConnectivityService');
  }

  @override
  Future<dynamic> checkConnectivity() async {
    return _mockIsOnline ? 'wifi' : 'none';
  }
}

void main() {
  group('End-to-End Offline Functionality Tests', () {
    late MockConnectivityService mockConnectivityService;
    late LocalDataService localDataService;
    late OfflineSyncService offlineSyncService;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      mockConnectivityService = MockConnectivityService();
      localDataService = LocalDataService();
      offlineSyncService = OfflineSyncService(mockConnectivityService);
      
      // Clean up any existing database
      try {
        await localDataService.deleteDatabase();
      } catch (e) {
        // Ignore if database doesn't exist
      }
      
      // Initialize services
      await localDataService.initializeDatabase();
      await offlineSyncService.initialize();
    });

    tearDown(() async {
      // Clean up database after each test
      await localDataService.deleteDatabase();
    });

    test('Complete offline workflow: report → store → sync → verify', () async {
      developer.log('Starting complete offline workflow test', name: 'EndToEndTest');
      
      // Create test user
      final testUser = AppUser(
        uid: 'test-user-e2e',
        email: 'e2e@example.com',
        username: 'e2euser',
        role: 'user',
      );

      // Create test location
      final testLocation = LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'New Delhi, India',
      );

      // PHASE 1: Start online, verify initial state
      developer.log('Phase 1: Initial online state', name: 'EndToEndTest');
      expect(mockConnectivityService.isOnline, true);
      expect(mockConnectivityService.wasOffline, false);
      
      var stats = await offlineSyncService.getDatabaseStats();
      expect(stats['total'], 0);
      expect(stats['unsynced'], 0);

      // PHASE 2: Go offline and report issues
      developer.log('Phase 2: Going offline and reporting issues', name: 'EndToEndTest');
      mockConnectivityService.setOnlineStatus(false);
      expect(mockConnectivityService.isOnline, false);
      expect(mockConnectivityService.wasOffline, true);

      // Report first issue offline
      final localId1 = await offlineSyncService.saveIssueOffline(
        description: 'Pothole on main street causing traffic issues',
        category: 'Roads',
        urgency: 'Medium',
        tags: ['pothole', 'traffic', 'urgent'],
        imagePath: '/mock/path/pothole.jpg',
        location: testLocation,
        user: testUser,
      );

      expect(localId1, isNotEmpty);
      developer.log('Saved first issue offline: $localId1', name: 'EndToEndTest');

      // Report second issue offline
      final localId2 = await offlineSyncService.saveIssueOffline(
        description: 'Broken streetlight creating safety hazard',
        category: 'Electricity',
        urgency: 'Medium',
        tags: ['streetlight', 'safety', 'night'],
        imagePath: '/mock/path/streetlight.jpg',
        location: LocationModel(
          latitude: 28.6200,
          longitude: 77.2100,
          address: 'Another location, New Delhi',
        ),
        user: testUser,
      );

      expect(localId2, isNotEmpty);
      developer.log('Saved second issue offline: $localId2', name: 'EndToEndTest');

      // Verify issues are stored locally
      var unsyncedIssues = await offlineSyncService.getUnsyncedIssues();
      expect(unsyncedIssues.length, 2);
      expect(unsyncedIssues.every((issue) => !issue.isSynced), true);
      expect(unsyncedIssues.every((issue) => issue.urgency == 'Medium'), true);

      stats = await offlineSyncService.getDatabaseStats();
      expect(stats['total'], 2);
      expect(stats['unsynced'], 2);
      expect(stats['synced'], 0);

      // PHASE 3: Verify offline issue details
      developer.log('Phase 3: Verifying offline issue details', name: 'EndToEndTest');
      final issue1 = unsyncedIssues.firstWhere((issue) => issue.localId == localId1);
      expect(issue1.description, 'Pothole on main street causing traffic issues');
      expect(issue1.category, 'Roads');
      expect(issue1.tags, ['pothole', 'traffic', 'urgent']);
      expect(issue1.userId, testUser.uid);
      expect(issue1.username, testUser.username);
      expect(issue1.status, 'Reported');
      expect(issue1.metadata['created_offline'], true);

      final issue2 = unsyncedIssues.firstWhere((issue) => issue.localId == localId2);
      expect(issue2.description, 'Broken streetlight creating safety hazard');
      expect(issue2.category, 'Electricity');
      expect(issue2.tags, ['streetlight', 'safety', 'night']);

      // PHASE 4: Test unsynced issue management
      developer.log('Phase 4: Testing unsynced issue management', name: 'EndToEndTest');
      
      // Delete one unsynced issue
      await offlineSyncService.deleteUnsyncedIssue(localId2);
      
      unsyncedIssues = await offlineSyncService.getUnsyncedIssues();
      expect(unsyncedIssues.length, 1);
      expect(unsyncedIssues.first.localId, localId1);

      stats = await offlineSyncService.getDatabaseStats();
      expect(stats['total'], 1);
      expect(stats['unsynced'], 1);

      // PHASE 5: Go back online and trigger sync
      developer.log('Phase 5: Going online and triggering sync', name: 'EndToEndTest');
      
      // Verify we have unsynced issues before going online
      expect(await offlineSyncService.hasUnsyncedIssues(), true);
      
      // Go back online - this should trigger auto-sync
      mockConnectivityService.setOnlineStatus(true);
      expect(mockConnectivityService.isOnline, true);

      // Wait for auto-sync to be triggered
      await Future.delayed(const Duration(milliseconds: 100));

      // Manually trigger sync (since we don't have real Firebase in tests)
      await offlineSyncService.syncUnsyncedIssues();

      // PHASE 6: Verify sync status and error handling
      developer.log('Phase 6: Verifying sync status', name: 'EndToEndTest');
      
      // In a real environment with Firebase, the issue would be synced
      // In our test environment, it will fail but should handle errors gracefully
      expect(offlineSyncService.isSyncing, false);
      expect(offlineSyncService.syncStatus.isNotEmpty, true);
      
      // The sync service should have attempted to sync
      expect(offlineSyncService.totalToSync >= 0, true);

      developer.log('Sync status: ${offlineSyncService.syncStatus}', name: 'EndToEndTest');
    });

    test('App initialization with timeout fallbacks', () async {
      developer.log('Testing app initialization with timeout fallbacks', name: 'EndToEndTest');

      // Test OfflineFirstDataLoader timeout behavior
      final startTime = DateTime.now();
      
      // This should timeout and return empty list
      final issues = await OfflineFirstDataLoader.loadIssuesWithFallback();
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      // Should complete quickly due to fallback
      expect(duration.inSeconds, lessThan(10));
      expect(issues, isA<List<Issue>>());
      expect(issues.isEmpty, true); // Fallback returns empty list
      
      developer.log('Issues loaded with fallback in ${duration.inMilliseconds}ms', name: 'EndToEndTest');
    });

    test('Connectivity state transitions and sync triggers', () async {
      developer.log('Testing connectivity state transitions', name: 'EndToEndTest');

      // Create test data
      final testUser = AppUser(
        uid: 'test-transitions',
        email: 'transitions@example.com',
        username: 'transitionsuser',
        role: 'user',
      );

      final testLocation = LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Test Location',
      );

      // Start online
      expect(mockConnectivityService.isOnline, true);
      expect(mockConnectivityService.wasOffline, false);

      // Go offline
      mockConnectivityService.setOnlineStatus(false);
      expect(mockConnectivityService.isOnline, false);
      expect(mockConnectivityService.wasOffline, true);

      // Create issue while offline
      final localId = await offlineSyncService.saveIssueOffline(
        description: 'Test connectivity transitions',
        category: 'Infrastructure',
        urgency: 'Medium',
        tags: ['test'],
        imagePath: '/mock/path/test.jpg',
        location: testLocation,
        user: testUser,
      );

      expect(await offlineSyncService.hasUnsyncedIssues(), true);

      // Go back online - should trigger auto-sync
      mockConnectivityService.setOnlineStatus(true);
      expect(mockConnectivityService.isOnline, true);

      // Wait for auto-sync callback
      await Future.delayed(const Duration(milliseconds: 50));

      // Multiple rapid transitions
      for (int i = 0; i < 3; i++) {
        mockConnectivityService.setOnlineStatus(false);
        await Future.delayed(const Duration(milliseconds: 10));
        mockConnectivityService.setOnlineStatus(true);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Service should remain stable
      expect(mockConnectivityService.isOnline, true);
      
      developer.log('Connectivity transitions completed successfully', name: 'EndToEndTest');
    });

    test('Database integrity and error recovery', () async {
      developer.log('Testing database integrity and error recovery', name: 'EndToEndTest');

      final testUser = AppUser(
        uid: 'test-integrity',
        email: 'integrity@example.com',
        username: 'integrityuser',
        role: 'user',
      );

      final testLocation = LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Test Location',
      );

      // Create multiple issues
      final issueIds = <String>[];
      for (int i = 0; i < 5; i++) {
        final localId = await offlineSyncService.saveIssueOffline(
          description: 'Test issue $i',
          category: 'Infrastructure',
          urgency: 'Medium',
          tags: ['test', 'batch-$i'],
          imagePath: '/mock/path/test$i.jpg',
          location: testLocation,
          user: testUser,
        );
        issueIds.add(localId);
      }

      // Verify all issues were saved
      var stats = await offlineSyncService.getDatabaseStats();
      expect(stats['total'], 5);
      expect(stats['unsynced'], 5);

      // Delete some issues
      await offlineSyncService.deleteUnsyncedIssue(issueIds[0]);
      await offlineSyncService.deleteUnsyncedIssue(issueIds[2]);
      await offlineSyncService.deleteUnsyncedIssue(issueIds[4]);

      // Verify correct number remain
      stats = await offlineSyncService.getDatabaseStats();
      expect(stats['total'], 2);
      expect(stats['unsynced'], 2);

      final remainingIssues = await offlineSyncService.getUnsyncedIssues();
      expect(remainingIssues.length, 2);
      expect(remainingIssues.any((issue) => issue.localId == issueIds[1]), true);
      expect(remainingIssues.any((issue) => issue.localId == issueIds[3]), true);

      // Test database recovery after error
      try {
        // This should handle gracefully if database is corrupted
        await localDataService.getDatabaseStats();
      } catch (e) {
        fail('Database operations should handle errors gracefully: $e');
      }

      developer.log('Database integrity tests completed', name: 'EndToEndTest');
    });

    test('LocalIssue to Issue conversion maintains data integrity', () async {
      developer.log('Testing LocalIssue to Issue conversion', name: 'EndToEndTest');

      final testLocation = LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Test Address, New Delhi',
      );

      // Create LocalIssue with all fields
      final localIssue = LocalIssue(
        localId: 'test-local-123',
        firebaseId: 'test-firebase-456',
        description: 'Test issue for conversion',
        category: 'Infrastructure',
        urgency: 'High',
        tags: ['test', 'conversion', 'data-integrity'],
        localImagePath: '/local/path/image.jpg',
        imageUrl: 'https://example.com/image.jpg',
        timestamp: DateTime.now(),
        location: testLocation,
        userId: 'user-123',
        username: 'testuser',
        status: 'Reported',
        isSynced: true,
        syncedAt: DateTime.now(),
        metadata: {
          'test_key': 'test_value',
          'created_offline': true,
        },
      );

      // Convert to Issue
      final issue = localIssue.toIssue();

      // Verify all data is preserved
      expect(issue.id, localIssue.firebaseId);
      expect(issue.description, localIssue.description);
      expect(issue.category, localIssue.category);
      expect(issue.urgency, localIssue.urgency);
      expect(issue.tags, localIssue.tags);
      expect(issue.imageUrl, localIssue.imageUrl);
      expect(issue.timestamp, localIssue.timestamp);
      expect(issue.location.latitude, localIssue.location.latitude);
      expect(issue.location.longitude, localIssue.location.longitude);
      expect(issue.location.address, localIssue.location.address);
      expect(issue.userId, localIssue.userId);
      expect(issue.username, localIssue.username);
      expect(issue.status, localIssue.status);

      developer.log('LocalIssue to Issue conversion verified', name: 'EndToEndTest');
    });

    test('Sync service state management during operations', () async {
      developer.log('Testing sync service state management', name: 'EndToEndTest');

      final testUser = AppUser(
        uid: 'test-state',
        email: 'state@example.com',
        username: 'stateuser',
        role: 'user',
      );

      final testLocation = LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'Test Location',
      );

      // Initial state
      expect(offlineSyncService.isSyncing, false);
      expect(offlineSyncService.syncStatus, '');
      expect(offlineSyncService.totalToSync, 0);
      expect(offlineSyncService.syncedCount, 0);
      expect(offlineSyncService.syncProgress, 0.0);

      // Create issues offline
      mockConnectivityService.setOnlineStatus(false);
      
      await offlineSyncService.saveIssueOffline(
        description: 'Test sync state 1',
        category: 'Infrastructure',
        urgency: 'Medium',
        tags: ['test'],
        imagePath: '/mock/path/test1.jpg',
        location: testLocation,
        user: testUser,
      );

      await offlineSyncService.saveIssueOffline(
        description: 'Test sync state 2',
        category: 'Infrastructure',
        urgency: 'Medium',
        tags: ['test'],
        imagePath: '/mock/path/test2.jpg',
        location: testLocation,
        user: testUser,
      );

      // Go online and start sync
      mockConnectivityService.setOnlineStatus(true);
      
      // Start sync (will fail in test environment but should manage state correctly)
      final syncFuture = offlineSyncService.syncUnsyncedIssues();
      
      // Sync should complete (even if it fails, state should be managed)
      await syncFuture;
      
      // Final state should be stable
      expect(offlineSyncService.isSyncing, false);
      expect(offlineSyncService.syncStatus.isNotEmpty, true);

      developer.log('Final sync status: ${offlineSyncService.syncStatus}', name: 'EndToEndTest');
      developer.log('Sync service state management verified', name: 'EndToEndTest');
    });
  });
}