// lib/screens/feed/issues_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:developer' as developer;
import 'package:modern_auth_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart'; // Add provider import
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../widgets/issue_card.dart'; // Uses IssueCard
import '../../models/issue_model.dart';
import '../../services/location_service.dart';
import '../../services/connectivity_service.dart'; // Import ConnectivityService
import '../../utils/location_utils.dart';
import '../../utils/offline_first_data_loader.dart';

class IssuesListScreen extends StatefulWidget {
  const IssuesListScreen({super.key});

  @override
  State<IssuesListScreen> createState() => _IssuesListScreenState();
}

class _IssuesListScreenState extends State<IssuesListScreen> {
  String _currentLocationDisplay = "Nearby";
  bool _isFetchingLocation = false;
  bool _isProximityFilterEnabled = true; // Default to enabled
  final LocationService _locationService = LocationService();
  Position? _currentPosition; // Store current position for filtering
  static const double _proximityRadiusKm = 10.0; // 10km radius for proximity filtering

  bool _isOffline = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to safely access context after initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeConnectivity();
        _fetchCurrentLocationAndUpdateDisplay();
      }
    });
  }

  Future<void> _initializeConnectivity() async {
    try {
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
      
      _checkConnectivityAndLoadIssues();
      _connectivitySubscription = connectivityService.connectivityStream.listen((result) {
        final isOffline = result == ConnectivityResult.none;
        if (_isOffline != isOffline) {
          setState(() {
            _isOffline = isOffline;
          });
          _checkConnectivityAndLoadIssues(); // Re-check and load when connectivity changes
        }
      });
    } catch (e) {
      developer.log('Error initializing connectivity: $e', name: 'IssuesListScreen');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivityAndLoadIssues() async {
    try {
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
      final connectivityResult = await connectivityService.checkConnectivity();
      if (mounted) {
        setState(() {
          _isOffline = connectivityResult == ConnectivityResult.none;
        });
      }
    } catch (e) {
      developer.log('Error checking connectivity: $e', name: 'IssuesListScreen');
      if (mounted) {
        setState(() {
          _isOffline = true; // Assume offline if we can't check
        });
      }
    }
  }


  Future<void> _requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }
    if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is permanently denied. Please enable it in settings.'),
            action: SnackBarAction(label: 'Open Settings', onPressed: openAppSettings),
          ),
        );
      }
    }
  }

  Future<void> _fetchCurrentLocationAndUpdateDisplay() async {
    if (!mounted) return;
    
    // Store ScaffoldMessenger reference early to avoid widget lifecycle issues
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    setState(() {
      _isFetchingLocation = true;
      _currentLocationDisplay = "Fetching location...";
    });

    await _requestLocationPermission();

    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Location permission denied. Showing general feed.')),
        );
        setState(() {
          _currentLocationDisplay = "All Issues";
          _isProximityFilterEnabled = false; // Disable proximity filter if no permission
          _isFetchingLocation = false;
        });
      }
      return;
    }

    try {
      final Position? position = await _locationService.getCurrentPosition();

      if (position != null) {
        // Store position for filtering
        _currentPosition = position;

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (mounted && placemarks.isNotEmpty) {
          final Placemark place = placemarks.first;
          String displayAddress = "";

          if (place.street != null && place.street!.isNotEmpty) {
            displayAddress += place.street!;
          } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
            displayAddress += place.thoroughfare!;
          }

          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            if (displayAddress.isNotEmpty) displayAddress += ", ";
            displayAddress += place.subLocality!;
          } else if (place.locality != null && place.locality!.isNotEmpty) {
            if (displayAddress.isNotEmpty) displayAddress += ", ";
            displayAddress += place.locality!;
          }

          if (displayAddress.isEmpty) {
            displayAddress = place.locality ?? place.administrativeArea ?? "Location";
          }

          if (displayAddress.length > 30) {
            displayAddress = '${displayAddress.substring(0, 27)}...';
          }

          if (mounted) {
            setState(() {
              _currentLocationDisplay = _isProximityFilterEnabled
                  ? "${displayAddress.isNotEmpty ? displayAddress : "Unnamed Area"} (10km radius)"
                  : displayAddress.isNotEmpty ? displayAddress : "Unnamed Area";
            });
          }
        } else if (mounted) {
          setState(() {
            _currentLocationDisplay = _isProximityFilterEnabled
                ? "Current Location (10km radius)"
                : "Location";
          });
        }
      } else if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Could not fetch location data.')),
        );
        setState(() {
          _currentLocationDisplay = "Location Unavailable";
          _isProximityFilterEnabled = false; // Disable proximity filter if location unavailable
        });
      }
    } catch (e) {
      developer.log('Error fetching location in IssuesListScreen: ${e.toString()}', name: 'IssuesListScreen');
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Error determining location: Check permissions and services.')),
        );
        setState(() {
          _currentLocationDisplay = "Location Error";
          _isProximityFilterEnabled = false; // Disable proximity filter on error
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isFetchingLocation ? l10n!.location : _currentLocationDisplay,
                style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Toggle for proximity filter
          Tooltip(
            message: _isProximityFilterEnabled ? "Showing issues within 10km" : "Showing all issues",
            child: Switch(
              value: _isProximityFilterEnabled,
              onChanged: (value) {
                setState(() {
                  _isProximityFilterEnabled = value;
                  if (value && _currentPosition == null) {
                    // If enabling proximity filter but no position, fetch it
                    _fetchCurrentLocationAndUpdateDisplay();
                  }
                });
              },
            ),
          ),
        ],
      ),
      body: _isOffline ? _buildOfflineBody(l10n) : _buildOnlineBody(l10n),
    );
  }

  Widget _buildOfflineBody(AppLocalizations? l10n) {
    return const Center(child: Text("You are offline. Please check your connection."));
  }

  Widget _buildOnlineBody(AppLocalizations? l10n) {
    // Use OfflineFirstDataLoader to create a timeout-wrapped stream
    return StreamBuilder<List<Issue>>(
      stream: OfflineFirstDataLoader.createTimeoutStream<List<Issue>>(
        streamBuilder: () => FirebaseFirestore.instance
            .collection('issues')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs.map((doc) {
                final issueData = doc.data();
                return Issue.fromFirestore(issueData, doc.id);
              }).toList();
            }),
        fallbackValue: <Issue>[],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isFetchingLocation) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          developer.log('Firestore Error: ${snapshot.error}', name: 'IssuesListScreen');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Unable to load issues. Please check your connection.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Trigger rebuild to retry
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final allIssues = snapshot.data ?? [];
        
        if (allIssues.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No issues reported yet. Be the first!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Apply proximity filter if enabled and location is available
        List<Issue> displayedIssues = allIssues;
        if (_isProximityFilterEnabled && _currentPosition != null) {
          displayedIssues = allIssues.where((issue) {
            return LocationUtils.isLocationWithinRadius(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              issue.location.latitude,
              issue.location.longitude,
              _proximityRadiusKm
            );
          }).toList();
        }

        if (displayedIssues.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No issues found in your area.',
                  style: TextStyle(color: Colors.grey),
                ),
                if (_isProximityFilterEnabled) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isProximityFilterEnabled = false;
                      });
                    },
                    child: Text(l10n?.issuesFeed ?? 'Show All Issues'),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: displayedIssues.length,
          itemBuilder: (context, index) {
            final issue = displayedIssues[index];
            // Each issue is rendered using IssueCard, which handles image display
            return IssueCard(issue: issue);
          },
        );
      },
    );
  }
}
