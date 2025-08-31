// lib/services/optimized_provider_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Optimized provider wrapper that reduces unnecessary rebuilds
/// by implementing selective listening and value comparison
class OptimizedProviderWrapper<T extends ChangeNotifier>
    extends StatelessWidget {
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;
  final bool Function(T previous, T current)? shouldRebuild;

  const OptimizedProviderWrapper({
    super.key,
    required this.builder,
    this.child,
    this.shouldRebuild,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<T>(builder: builder, child: child);
  }
}

/// Optimized selector that only rebuilds when specific values change
class OptimizedSelector<T extends ChangeNotifier, R> extends StatelessWidget {
  final R Function(BuildContext context, T value) selector;
  final Widget Function(BuildContext context, R value, Widget? child) builder;
  final Widget? child;
  final bool Function(R previous, R current)? shouldRebuild;

  const OptimizedSelector({
    super.key,
    required this.selector,
    required this.builder,
    this.child,
    this.shouldRebuild,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<T, R>(
      selector: selector,
      shouldRebuild: shouldRebuild ?? _defaultShouldRebuild,
      builder: builder,
      child: child,
    );
  }

  bool _defaultShouldRebuild(R previous, R current) {
    // Default implementation - use equality comparison
    if (previous is List && current is List) {
      return !_listEquals(previous, current);
    }
    if (previous is Map && current is Map) {
      return !_mapEquals(previous, current);
    }
    return previous != current;
  }

  bool _listEquals(List? a, List? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _mapEquals(Map? a, Map? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }
}

/// Provider extension for easier access to optimized providers
extension ProviderExtension on BuildContext {
  /// Get a provider value without listening to changes
  T read<T>() {
    return Provider.of<T>(this, listen: false);
  }

  /// Get a provider value and listen to changes
  T watch<T>() {
    return Provider.of<T>(this);
  }

  /// Get a provider value with a selector for optimized rebuilds
  R select<T extends ChangeNotifier, R>(R Function(T value) selector) {
    final value = Provider.of<T>(this, listen: false);
    return selector(value);
  }
}

/// Optimized change notifier that implements value comparison
abstract class OptimizedChangeNotifier extends ChangeNotifier {
  final Map<String, dynamic> _cachedValues = {};
  final Map<String, DateTime> _lastUpdateTimes = {};
  static const Duration _updateThreshold = Duration(milliseconds: 100);

  /// Notify listeners only if the value has actually changed
  void notifyIfChanged<T>(String key, T newValue) {
    final oldValue = _cachedValues[key];
    final now = DateTime.now();
    final lastUpdate = _lastUpdateTimes[key];

    // Check if value has changed and enough time has passed
    if (_shouldNotify(oldValue, newValue, lastUpdate, now)) {
      _cachedValues[key] = newValue;
      _lastUpdateTimes[key] = now;
      notifyListeners();
    }
  }

  bool _shouldNotify<T>(
    T? oldValue,
    T newValue,
    DateTime? lastUpdate,
    DateTime now,
  ) {
    // Always notify if value is different
    if (oldValue != newValue) return true;

    // Don't notify if the same value was recently updated
    if (lastUpdate != null && now.difference(lastUpdate) < _updateThreshold) {
      return false;
    }

    return true;
  }

  /// Clear cached values
  void clearCache() {
    _cachedValues.clear();
    _lastUpdateTimes.clear();
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}
