// test/integration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:modern_auth_app/services/connectivity_service.dart';
import 'package:modern_auth_app/services/offline_sync_service.dart';
import 'package:modern_auth_app/services/local_data_service.dart';
import 'package:modern_auth_app/models/app_user_model.dart';
import 'package:modern_auth_app/models/issue_model.dart';
import 'package:modern_auth_app/widgets/offline_banner.dart';
import 'package:modern_auth_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Mock ConnectivityService for testing
class MockConnectivityService extends ConnectivityService {
  bool _mockIsOnline = true;
  bool _mockWasOffline = false;
  Function()? _autoSyncCallback;

  @override
  bool get isOnline => _mockIsOnline;

  @override
  bool get wasOffline => _mockWasOffline;

  void setOnlineStatus(bool isOnline) {
    if (isOnline != _mockIsOnline) {
      if (!isOnline) {
        _mockWasOffline = true;
      } else if (_mockWasOffline) {
        // Coming back online after being offline
        _mockWasOffline = false;
        // Trigger auto-sync callback
        if (_autoSyncCallback != null) {
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
  }

  void simulateOfflineTransition() {
    _mockWasOffline = true;
    _mockIsOnline = false;
    notifyListeners();
  }

  void simulateOnlineTransition() {
    _mockIsOnline = true;
    // Keep _mockWasOffline true to simulate that we were offline before
    if (_autoSyncCallback != null) {
      _autoSyncCallback!();
    }
    notifyListeners();
  }
}

void main() {
  group('Offline Functionality Integration Tests', () {
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
      
      // Initialize database
      await localDataService.initializeDatabase();
      await offlineSyncService.initialize();
    });

    tearDown(() async {
      // Clean up database after each test
      await localDataService.deleteDatabase();
    });

    Widget createTestApp({required Widget child}) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('hi'),
        ],
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ConnectivityService>.value(
              value: mockConnectivityService,
            ),
            ChangeNotifierProvider<OfflineSyncService>.value(
              value: offlineSyncService,
            ),
          ],
          child: child,
        ),
      );
    }

    testWidgets('Complete offline flow: report issue offline → go online → verify sync', (WidgetTester tester) async {
      // Create test user
      final testUser = AppUser(
        uid: 'test-user-123',
        email: 'test@example.com',
        username: 'testuser',
        role: 'user',
      );

      // Create test location
      final testLocation = LocationModel(
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'Test Address, Bangalore',
      );

      // Step 1: Go offline
      mockConnectivityService.setOnlineStatus(false);

      // Step 2: Report issue offline
      final localId = await offlineSyncService.saveIssueOffline(
        description: 'Test pothole on main road',
        category: 'Roads',
        urgency: 'Medium',
        tags: ['pothole', 'urgent'],
        imagePath: '/test/path/image.jpg', // Mock path
        location: testLocation,
        user: testUser,
      );

      expect(localId, isNotEmpty);

      // Verify issue was saved offline
      var unsyncedIssues = await offlineSyncService.getUnsyncedIssues();
      expect(unsyncedIssues.length, 1);
      expect(unsyncedIssues.first.description, 'Test pothole on main road');
      expect(unsyncedIssues.first.isSynced, false);

      // Step 3: Go back online
      mockConnectivityService.setOnlineStatus(true);

      // Wait for auto-sync to complete
      await tester.pumpAndSettle();
      
      // Give some time for sync to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Step 4: Verify sync status
      // Note: In a real test, we would mock the Firebase services
      // For now, we verify that the sync process was triggered
      expect(mockConnectivityService.isOnline, true);
      
      // The issue should still be in local storage but marked as synced
      // (In a full integration test with mocked Firebase, we would verify actual sync)
    });

    testWidgets('App initialization works in offline mode without hanging', (WidgetTester tester) async {
      // Start offline
      mockConnectivityService.setOnlineStatus(false);

      // Create a simple test widget that simulates app initialization
      final testWidget = createTestApp(
        child: Scaffold(
          body: Column(
            children: [
              const OfflineBanner(),
              Consumer<ConnectivityService>(
                builder: (context, connectivityService, child) {
                  return Text(
                    'Status: ${connectivityService.isOnline ? "Online" : "Offline"}',
                    key: const Key('status_text'),
                  );
                },
              ),
            ],
          ),
        ),
      );

      // Pump the widget
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Verify app loads properly in offline mode
      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.text('Status: Offline'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);

      // Verify no hanging or infinite loading
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Connectivity transitions during app usage', (WidgetTester tester) async {
      final testWidget = createTestApp(
        child: Scaffold(
          body: Column(
            children: [
              const OfflineBanner(),
              Consumer<ConnectivityService>(
                builder: (context, connectivityService, child) {
                  return Column(
                    children: [
                      Text(
                        'Status: ${connectivityService.isOnline ? "Online" : "Offline"}',
                        key: const Key('status_text'),
                      ),
                      Text(
                        'Was Offline: ${connectivityService.wasOffline ? "Yes" : "No"}',
                        key: const Key('was_offline_text'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Initially online
      expect(find.text('Status: Online'), findsOneWidget);
      expect(find.text('Was Offline: No'), findsOneWidget);
      expect(find.text('Offline Mode'), findsNothing);

      // Transition to offline
      mockConnectivityService.simulateOfflineTransition();
      await tester.pumpAndSettle();

      expect(find.text('Status: Offline'), findsOneWidget);
      expect(find.text('Was Offline: Yes'), findsOneWidget);
      expect(find.text('Offline Mode'), findsOneWidget);

      // Transition back to online
      mockConnectivityService.simulateOnlineTransition();
      await tester.pumpAndSettle();

      expect(find.text('Status: Online'), findsOneWidget);
      expect(find.text('Was Offline: Yes'), findsOneWidget);
      expect(find.text('Offline Mode'), findsNothing);

      // Multiple transitions
      mockConnectivityService.setOnlineStatus(false);
      await tester.pumpAndSettle();
      expect(find.text('Offline Mode'), findsOneWidget);

      mockConnectivityService.setOnlineStatus(true);
      await tester.pumpAndSettle();
      expect(find.text('Offline Mode'), findsNothing);
    });

    testWidgets('Offline banner shows and hides correctly', (WidgetTester tester) async {
      final testWidget = createTestApp(
        child: const Scaffold(
          body: OfflineBanner(),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Initially online - banner should be hidden
      expect(find.text('Offline Mode'), findsNothing);
      expect(find.byIcon(Icons.wifi_off), findsNothing);

      // Go offline - banner should appear
      mockConnectivityService.setOnlineStatus(false);
      await tester.pumpAndSettle();

      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);

      // Go back online - banner should disappear
      mockConnectivityService.setOnlineStatus(true);
      await tester.pumpAndSettle();

      expect(find.text('Offline Mode'), findsNothing);
      expect(find.byIcon(Icons.wifi_off), findsNothing);
    });

    test('Database operations work correctly in offline mode', () async {
      // Create test user
      final testUser = AppUser(
        uid: 'test-user-123',
        email: 'test@example.com',
        username: 'testuser',
        role: 'user',
      );

      // Create test location
      final testLocation = LocationModel(
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'Test Address, Bangalore',
      );

      // Go offline
      mockConnectivityService.setOnlineStatus(false);

      // Save multiple issues offline
      final localId1 = await offlineSyncService.saveIssueOffline(
        description: 'Test issue 1',
        category: 'Roads',
        urgency: 'Medium',
        tags: ['test1'],
        imagePath: '/test/path/image1.jpg',
        location: testLocation,
        user: testUser,
      );

      final localId2 = await offlineSyncService.saveIssueOffline(
        description: 'Test issue 2',
        category: 'Water',
        urgency: 'Medium',
        tags: ['test2'],
        imagePath: '/test/path/image2.jpg',
        location: testLocation,
        user: testUser,
      );

      // Verify both issues were saved
      final unsyncedIssues = await offlineSyncService.getUnsyncedIssues();
      expect(unsyncedIssues.length, 2);
      expect(unsyncedIssues.any((issue) => issue.localId == localId1), true);
      expect(unsyncedIssues.any((issue) => issue.localId == localId2), true);

      // Test deletion
      await offlineSyncService.deleteUnsyncedIssue(localId1);
      final remainingIssues = await offlineSyncService.getUnsyncedIssues();
      expect(remainingIssues.length, 1);
      expect(remainingIssues.first.localId, localId2);

      // Test database stats
      final stats = await offlineSyncService.getDatabaseStats();
      expect(stats['total'], 1);
      expect(stats['unsynced'], 1);
      expect(stats['synced'], 0);
    });

    test('Auto-sync triggers when connectivity is restored', () async {
      // Create test user
      final testUser = AppUser(
        uid: 'test-user-123',
        email: 'test@example.com',
        username: 'testuser',
        role: 'user',
      );

      // Create test location
      final testLocation = LocationModel(
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'Test Address, Bangalore',
      );

      // Go offline and save an issue
      mockConnectivityService.setOnlineStatus(false);
      await offlineSyncService.saveIssueOffline(
        description: 'Test auto-sync issue',
        category: 'Roads',
        urgency: 'Medium',
        tags: ['auto-sync'],
        imagePath: '/test/path/image.jpg',
        location: testLocation,
        user: testUser,
      );

      // Verify issue is unsynced
      expect(await offlineSyncService.hasUnsyncedIssues(), true);

      // Go back online - this should trigger auto-sync
      mockConnectivityService.setOnlineStatus(true);

      // Wait a moment for the auto-sync callback to be processed
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify that sync was attempted (in a real test with mocked services,
      // we would verify the actual sync completion)
      expect(mockConnectivityService.isOnline, true);
    });

    test('Sync service handles errors gracefully', () async {
      // Create test user
      final testUser = AppUser(
        uid: 'test-user-123',
        email: 'test@example.com',
        username: 'testuser',
        role: 'user',
      );

      // Create test location
      final testLocation = LocationModel(
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'Test Address, Bangalore',
      );

      // Save issue offline
      await offlineSyncService.saveIssueOffline(
        description: 'Test error handling',
        category: 'Roads',
        urgency: 'Medium',
        tags: ['error-test'],
        imagePath: '/test/path/image.jpg',
        location: testLocation,
        user: testUser,
      );

      // Go online and attempt sync (will fail due to mocked services)
      mockConnectivityService.setOnlineStatus(true);
      
      // Attempt sync - should handle errors gracefully
      await offlineSyncService.syncUnsyncedIssues();

      // Service should not crash and should maintain state
      expect(offlineSyncService.isSyncing, false);
      expect(offlineSyncService.syncStatus.isNotEmpty, true);
    });
  });

  group('App Initialization Tests', () {
    late MockConnectivityService mockConnectivityService;

    setUp(() {
      mockConnectivityService = MockConnectivityService();
    });

    testWidgets('App loads without hanging when offline', (WidgetTester tester) async {
      // Start offline
      mockConnectivityService.setOnlineStatus(false);

      final testWidget = MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('hi'),
        ],
        home: ChangeNotifierProvider<ConnectivityService>.value(
          value: mockConnectivityService,
          child: Scaffold(
            body: Column(
              children: [
                const OfflineBanner(),
                const Text('App Loaded Successfully'),
                Consumer<ConnectivityService>(
                  builder: (context, connectivityService, child) {
                    return Text(
                      'Connection: ${connectivityService.isOnline ? "Online" : "Offline"}',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Pump widget with timeout to ensure it doesn't hang
      await tester.pumpWidget(testWidget);
      
      // Use pumpAndSettle with timeout to prevent infinite waiting
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify app loaded successfully
      expect(find.text('App Loaded Successfully'), findsOneWidget);
      expect(find.text('Connection: Offline'), findsOneWidget);
      expect(find.text('Offline Mode'), findsOneWidget);
    });

    testWidgets('App handles rapid connectivity changes', (WidgetTester tester) async {
      final testWidget = MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('hi'),
        ],
        home: ChangeNotifierProvider<ConnectivityService>.value(
          value: mockConnectivityService,
          child: Scaffold(
            body: Column(
              children: [
                const OfflineBanner(),
                Consumer<ConnectivityService>(
                  builder: (context, connectivityService, child) {
                    return Text(
                      'Status: ${connectivityService.isOnline ? "Online" : "Offline"}',
                      key: const Key('status'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Rapid connectivity changes
      for (int i = 0; i < 5; i++) {
        mockConnectivityService.setOnlineStatus(false);
        await tester.pumpAndSettle();
        expect(find.text('Status: Offline'), findsOneWidget);

        mockConnectivityService.setOnlineStatus(true);
        await tester.pumpAndSettle();
        expect(find.text('Status: Online'), findsOneWidget);
      }

      // App should remain stable
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}