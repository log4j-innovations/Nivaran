// lib/screens/main_app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/user_profile_service.dart';
import '../services/offline_sync_service.dart';
import 'feed/issues_list_screen.dart';
import 'report/camera_capture_screen.dart';
import 'profile/account_screen.dart';
import 'map/map_view_screen.dart';
import 'notifications/notifications_screen.dart';
import 'impact/community_impact_screen.dart';
import '../widgets/offline_banner.dart';
import '../widgets/sync_status_widget.dart';
import '../utils/update_checker.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';

class MainAppScaffold extends StatefulWidget {
  final int? initialTabIndex;

  const MainAppScaffold({super.key, this.initialTabIndex});

  @override
  State<MainAppScaffold> createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends State<MainAppScaffold>
    with WidgetsBindingObserver {
  late int _selectedIndex;
  User? _currentUser;
  bool _hasCheckedUpdate = false;

  // Widget options for bottom navigation
  static final List<Widget> _widgetOptions = <Widget>[
    const IssuesListScreen(),
    const CameraCaptureScreen(),
    const MapViewScreen(),
    const NotificationsScreen(),
    const CommunityImpactScreen(), // Added Community Impact Dashboard
    AccountScreen(key: UniqueKey()),
  ];

  void _initializeWidgetOptions() {
    _widgetOptions.clear();
    _widgetOptions.add(const IssuesListScreen());
    _widgetOptions.add(const CameraCaptureScreen());
    _widgetOptions.add(const MapViewScreen());
    _widgetOptions.add(const NotificationsScreen());
    _widgetOptions.add(
      const CommunityImpactScreen(),
    ); // Added Community Impact Dashboard
    _widgetOptions.add(AccountScreen(key: UniqueKey()));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUser = FirebaseAuth.instance.currentUser;

    // Set initial tab index (notifications tab is index 3)
    _selectedIndex = widget.initialTabIndex ?? 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _performInitialChecks();
      }
    });

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
        if (user == null && ModalRoute.of(context)?.settings.name == '/app') {
          developer.log(
            "MainAppScaffold: User logged out, AuthWrapper should navigate.",
            name: "MainAppScaffold",
          );
        }
      }
    });

    // Listen to sync status changes and show snackbar notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final offlineSyncService = Provider.of<OfflineSyncService>(
          context,
          listen: false,
        );
        offlineSyncService.addListener(() {
          if (mounted && offlineSyncService.syncStatus.isNotEmpty) {
            // Show snackbar for important sync status updates
            if (offlineSyncService.syncStatus.contains('complete') ||
                offlineSyncService.syncStatus.contains('failed') ||
                (offlineSyncService.isSyncing &&
                    offlineSyncService.totalToSync > 0)) {
              SyncStatusSnackBar.show(context, offlineSyncService);
            }
          }
        });
      }
    });
  }

  Future<void> _performInitialChecks() async {
    // Store the context and service reference before any async operations
    if (!mounted) return;

    // Store references early to avoid widget lifecycle issues
    final currentContext = context;
    UserProfileService? userProfileService;
    try {
      userProfileService = Provider.of<UserProfileService>(
        currentContext,
        listen: false,
      );
    } catch (e) {
      developer.log(
        "MainAppScaffold: Could not get UserProfileService: $e",
        name: "MainAppScaffold",
      );
      return;
    }

    if (mounted && !_hasCheckedUpdate) {
      developer.log(
        "MainAppScaffold: Performing initial update check.",
        name: "MainAppScaffold",
      );
      if (!mounted) return;

      // Use timeout for update check to prevent hanging
      try {
        await UpdateChecker.checkForUpdate(
          currentContext,
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        developer.log(
          "MainAppScaffold: Update check timed out or failed: $e",
          name: "MainAppScaffold",
        );
      }

      if (mounted) setState(() => _hasCheckedUpdate = true);
    }

    // Fetch the user's profile if it's not already loaded
    // The UserProfileService now uses OfflineFirstDataLoader internally, so this won't hang
    if (!mounted) return;
    if (_currentUser != null &&
        userProfileService.currentUserProfile?.uid != _currentUser!.uid &&
        !userProfileService.isLoadingProfile) {
      developer.log(
        "MainAppScaffold: Initial profile fetch triggered because current user profile doesn't match auth user or is null.",
        name: "MainAppScaffold",
      );
      await userProfileService.fetchAndSetCurrentUserProfile();
    } else if (_currentUser != null &&
        userProfileService.currentUserProfile == null &&
        !userProfileService.isLoadingProfile) {
      developer.log(
        "MainAppScaffold: Current user exists but profile is null, attempting fetch.",
        name: "MainAppScaffold",
      );
      await userProfileService.fetchAndSetCurrentUserProfile();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      developer.log("MainAppScaffold: App Resumed.", name: "MainAppScaffold");
      if (mounted) {
        _hasCheckedUpdate = false;
        _performInitialChecks();
      }
    } else if (state == AppLifecycleState.paused) {
      developer.log("MainAppScaffold: App Paused.", name: "MainAppScaffold");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProfileService, OfflineSyncService>(
      builder: (context, userProfileService, offlineSyncService, child) {
        final userProfile = userProfileService.currentUserProfile;
        final isOnline = context.read<ConnectivityService>().isOnline;

        // Initialize widget options if not already done
        if (_widgetOptions.isEmpty) {
          _initializeWidgetOptions();
        }

        if (_currentUser == null) {
          developer.log(
            "MainAppScaffold: Current user is null, showing loading. AuthWrapper should redirect.",
            name: "MainAppScaffold",
          );
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                semanticsLabel: "Authenticating...",
              ),
            ),
          );
        }

        // Check if UserProfile is loading. If so, show loading indicator for the whole scaffold.
        // This prevents individual screens from trying to access a null profile prematurely.
        if (userProfileService.isLoadingProfile &&
            userProfileService.currentUserProfile == null) {
          developer.log(
            "MainAppScaffold: UserProfileService is loading initial profile. Showing loading screen.",
            name: "MainAppScaffold",
          );
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                semanticsLabel: "Loading user profile...",
              ),
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              // Offline banner will only show when app is offline
              const OfflineBanner(),

              // Sync status widget will show when syncing or after sync completion
              const SyncStatusWidget(showOnlyWhenSyncing: false),

              // Main content area
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _widgetOptions,
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 0
                      ? Icons.list_alt_rounded
                      : Icons.list_alt_outlined,
                ),
                label: AppLocalizations.of(context)!.feed,
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 1
                      ? Icons.camera_alt
                      : Icons.camera_alt_outlined,
                ),
                label: AppLocalizations.of(context)!.report,
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 2 ? Icons.map : Icons.map_outlined,
                ),
                label: AppLocalizations.of(context)!.map,
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 3
                      ? Icons.notifications
                      : Icons.notifications_outlined,
                ),
                label: AppLocalizations.of(context)!.notifications,
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 4
                      ? Icons.bar_chart
                      : Icons.bar_chart_outlined,
                ),
                label: AppLocalizations.of(context)!.communityImpact,
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 5 ? Icons.person : Icons.person_outlined,
                ),
                label: AppLocalizations.of(context)!.profile,
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey[600],
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            backgroundColor: Colors.white,
            elevation: 8.0,
            selectedFontSize: 12.0,
            unselectedFontSize: 10.0,
          ),
        );
      },
    );
  }
}
