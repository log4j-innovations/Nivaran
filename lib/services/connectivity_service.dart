import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService with ChangeNotifier {
  static ConnectivityService? _instance;
  static ConnectivityService get instance {
    _instance ??= ConnectivityService._internal();
    return _instance!;
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  bool _wasOffline = false;
  bool _isInitialized = false;

  // Debouncing mechanism to prevent excessive notifications
  Timer? _debounceTimer;
  static const Duration _debounceDelay = Duration(milliseconds: 500);
  ConnectivityResult? _lastNotifiedStatus;

  bool get isOnline => _isOnline;
  bool get wasOffline => _wasOffline;

  Stream<ConnectivityResult> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  ConnectivityService._internal();

  factory ConnectivityService() {
    return instance;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _checkInitialConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _isInitialized = true;
  }

  Future<ConnectivityResult> checkConnectivity() {
    return _connectivity.checkConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      ConnectivityResult result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('ConnectivityService: Error checking initial connectivity: $e');
      // Assume offline if we can't check connectivity
      _updateConnectionStatus(ConnectivityResult.none);
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    bool newStatus = result != ConnectivityResult.none;
    
    debugPrint('ConnectivityService: Connection status changed - Result: $result, Online: $newStatus');
    
    if (newStatus != _isOnline) {
      if (!newStatus) {
        markOfflineTransition();
      } else {
        markOnlineTransition();
      }
      _isOnline = newStatus;
      
      // Debounce notifications to prevent excessive rebuilds
      _debounceConnectivityChange(result);
    }
  }

  // Debounce connectivity changes to prevent excessive notifications
  void _debounceConnectivityChange(ConnectivityResult result) {
    // Cancel existing timer
    _debounceTimer?.cancel();
    
    // Only notify if status is different from last notification
    if (result != _lastNotifiedStatus) {
      _debounceTimer = Timer(_debounceDelay, () {
        _lastNotifiedStatus = result;
        notifyListeners();
      });
    }
  }

  /// Called when transitioning from online to offline
  void markOfflineTransition() {
    _wasOffline = true;
    debugPrint('ConnectivityService: Transitioned to offline mode');
  }

  /// Called when transitioning from offline to online
  void markOnlineTransition() {
    if (_wasOffline) {
      debugPrint('ConnectivityService: Transitioned back online after being offline');
      // Trigger sync when coming back online
      _triggerAutoSync();
    }
    _wasOffline = false;
  }

  /// Callback for auto-sync when connectivity is restored
  void Function()? _onConnectivityRestored;

  /// Set callback for auto-sync when connectivity is restored
  void setAutoSyncCallback(void Function() callback) {
    _onConnectivityRestored = callback;
  }

  /// Trigger auto-sync when connectivity is restored
  void _triggerAutoSync() {
    if (_onConnectivityRestored != null) {
      debugPrint('ConnectivityService: Triggering auto-sync');
      _onConnectivityRestored!();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _isInitialized = false;
    super.dispose();
  }
}