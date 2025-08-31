// lib/services/performance_monitor_service.dart
import 'dart:developer' as developer;
import 'package:flutter/scheduler.dart';

/// Service to monitor and track app performance metrics
class PerformanceMonitorService {
  static final PerformanceMonitorService _instance =
      PerformanceMonitorService._internal();
  factory PerformanceMonitorService() => _instance;
  PerformanceMonitorService._internal();

  // Performance metrics
  final Map<String, List<Duration>> _operationTimings = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, Duration> _averageTimings = {};

  // Frame rate monitoring
  int _frameCount = 0;
  DateTime? _lastFrameTime;
  double _currentFPS = 0.0;

  // Performance thresholds
  static const Duration _slowOperationThreshold = Duration(milliseconds: 100);
  static const Duration _verySlowOperationThreshold = Duration(
    milliseconds: 500,
  );
  static const double _lowFPSThreshold = 30.0;

  /// Start monitoring frame rate
  void startFrameRateMonitoring() {
    SchedulerBinding.instance.addPersistentFrameCallback((timeStamp) {
      _onFrame(timeStamp);
    });
  }

  /// Handle frame callback
  void _onFrame(Duration timeStamp) {
    _frameCount++;
    final now = DateTime.now();

    if (_lastFrameTime != null) {
      final frameDuration = now.difference(_lastFrameTime!);
      if (frameDuration.inMilliseconds > 0) {
        _currentFPS = 1000.0 / frameDuration.inMilliseconds;

        // Log low FPS warnings
        if (_currentFPS < _lowFPSThreshold) {
          developer.log(
            'Low FPS detected: ${_currentFPS.toStringAsFixed(1)} FPS',
            name: 'PerformanceMonitor',
            level: 900, // Warning level
          );
        }
      }
    }

    _lastFrameTime = now;
  }

  /// Start timing an operation
  void startOperation(String operationName) {
    if (!_operationTimings.containsKey(operationName)) {
      _operationTimings[operationName] = [];
      _operationCounts[operationName] = 0;
    }

    // Store start time in the operation name
    _operationTimings['${operationName}_start'] = [
      DateTime.now().difference(DateTime(1970)),
    ];
  }

  /// End timing an operation
  void endOperation(String operationName) {
    final startKey = '${operationName}_start';
    if (_operationTimings.containsKey(startKey)) {
      final startTime = _operationTimings[startKey]!.first;
      final endTime = DateTime.now().difference(DateTime(1970));
      final duration = endTime - startTime;

      // Store timing
      _operationTimings[operationName]!.add(duration);
      _operationCounts[operationName] =
          (_operationCounts[operationName] ?? 0) + 1;

      // Calculate average
      final timings = _operationTimings[operationName]!;
      final totalDuration = timings.fold(
        Duration.zero,
        (prev, curr) => prev + curr,
      );
      _averageTimings[operationName] = Duration(
        microseconds: totalDuration.inMicroseconds ~/ timings.length,
      );

      // Log slow operations
      if (duration > _verySlowOperationThreshold) {
        developer.log(
          'Very slow operation: $operationName took ${duration.inMilliseconds}ms',
          name: 'PerformanceMonitor',
          level: 1000, // Error level
        );
      } else if (duration > _slowOperationThreshold) {
        developer.log(
          'Slow operation: $operationName took ${duration.inMilliseconds}ms',
          name: 'PerformanceMonitor',
          level: 900, // Warning level
        );
      }

      // Clean up start time
      _operationTimings.remove(startKey);
    }
  }

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{
      'frameRate': {
        'current': _currentFPS,
        'threshold': _lowFPSThreshold,
        'isLow': _currentFPS < _lowFPSThreshold,
      },
      'operations': {},
      'summary': {
        'totalOperations': _operationCounts.values.fold(
          0,
          (sum, count) => sum + count,
        ),
        'slowOperations': 0,
        'verySlowOperations': 0,
      },
    };

    // Add operation details
    for (final operation in _operationTimings.keys) {
      if (!operation.endsWith('_start')) {
        final timings = _operationTimings[operation]!;
        final count = _operationCounts[operation] ?? 0;
        final average = _averageTimings[operation];

        if (timings.isNotEmpty) {
          final slowCount =
              timings.where((t) => t > _slowOperationThreshold).length;
          final verySlowCount =
              timings.where((t) => t > _verySlowOperationThreshold).length;

          report['operations'][operation] = {
            'count': count,
            'average': average?.inMilliseconds,
            'slowCount': slowCount,
            'verySlowCount': verySlowCount,
            'recentTimings':
                timings.take(5).map((t) => t.inMilliseconds).toList(),
          };

          report['summary']['slowOperations'] += slowCount;
          report['summary']['verySlowOperations'] += verySlowCount;
        }
      }
    }

    return report;
  }

  /// Reset all performance metrics
  void resetMetrics() {
    _operationTimings.clear();
    _operationCounts.clear();
    _averageTimings.clear();
    _frameCount = 0;
    _lastFrameTime = null;
    _currentFPS = 0.0;
    developer.log('Performance metrics reset', name: 'PerformanceMonitor');
  }

  /// Log performance summary
  void logPerformanceSummary() {
    final report = getPerformanceReport();

    developer.log('=== Performance Summary ===', name: 'PerformanceMonitor');
    developer.log(
      'Current FPS: ${report['frameRate']['current'].toStringAsFixed(1)}',
      name: 'PerformanceMonitor',
    );
    developer.log(
      'Total Operations: ${report['summary']['totalOperations']}',
      name: 'PerformanceMonitor',
    );
    developer.log(
      'Slow Operations: ${report['summary']['slowOperations']}',
      name: 'PerformanceMonitor',
    );
    developer.log(
      'Very Slow Operations: ${report['summary']['verySlowOperations']}',
      name: 'PerformanceMonitor',
    );

    if (report['operations'].isNotEmpty) {
      developer.log('Operation Details:', name: 'PerformanceMonitor');
      for (final entry in report['operations'].entries) {
        final op = entry.value as Map<String, dynamic>;
        developer.log(
          '  ${entry.key}: ${op['count']} calls, avg: ${op['average']}ms, slow: ${op['slowCount']}',
          name: 'PerformanceMonitor',
        );
      }
    }
  }

  /// Check if performance is acceptable
  bool get isPerformanceAcceptable {
    final report = getPerformanceReport();
    return report['frameRate']['current'] >= _lowFPSThreshold &&
        report['summary']['verySlowOperations'] == 0;
  }

  /// Get recommendations for performance improvement
  List<String> getPerformanceRecommendations() {
    final recommendations = <String>[];
    final report = getPerformanceReport();

    if (report['frameRate']['current'] < _lowFPSThreshold) {
      recommendations.add(
        'Frame rate is low. Consider reducing widget rebuilds and optimizing animations.',
      );
    }

    if (report['summary']['verySlowOperations'] > 0) {
      recommendations.add(
        'Very slow operations detected. Review and optimize database queries and network calls.',
      );
    }

    if (report['summary']['slowOperations'] > 0) {
      recommendations.add(
        'Slow operations detected. Consider implementing caching and background processing.',
      );
    }

    return recommendations;
  }
}

/// Mixin for easy performance monitoring in services
mixin PerformanceMonitoring {
  final PerformanceMonitorService _performanceMonitor =
      PerformanceMonitorService();

  /// Monitor a function execution
  Future<T> monitorOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    _performanceMonitor.startOperation(operationName);
    try {
      final result = await operation();
      return result;
    } finally {
      _performanceMonitor.endOperation(operationName);
    }
  }

  /// Monitor a synchronous function execution
  T monitorSyncOperation<T>(String operationName, T Function() operation) {
    _performanceMonitor.startOperation(operationName);
    try {
      final result = operation();
      return result;
    } finally {
      _performanceMonitor.endOperation(operationName);
    }
  }
}
