// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'dart:async';
import '../flutter_metric_reporter.dart';

typedef ErrorMetricListener = void Function(ErrorMetric metric);

class ErrorSummary {
  final String errorType;
  final int occurrences;
  final DateTime firstOccurrence;
  final DateTime lastOccurrence;
  final List<String> affectedComponents;
  final Map<String, int> attributeFrequency;

  ErrorSummary({
    required this.errorType,
    required this.occurrences,
    required this.firstOccurrence,
    required this.lastOccurrence,
    required this.affectedComponents,
    required this.attributeFrequency,
  });
}

class ErrorTracker {
  static final ErrorTracker _instance = ErrorTracker._internal();
  factory ErrorTracker() => _instance;

  final List<ErrorMetric> _errorHistory = [];
  final Map<String, List<ErrorMetric>> _errorsByComponent = {};
  final List<ErrorMetricListener> _listeners = [];

  // Track error rates for anomaly detection
  final Map<String, List<int>> _errorRates = {};
  static const _errorRateWindow = Duration(minutes: 5);
  Timer? _errorRateTimer;

  late final StreamSubscription<ErrorMetric> _errorSubscription;
  late final StreamSubscription<PaintMetric> _paintErrorSubscription;
  late final FlutterMetricReporter _reporter;

  ErrorTracker._internal() {
    _reporter = FlutterMetricReporter();

    _errorSubscription = _reporter.errorStream.listen((metric) {
      _processError(metric);
      _notifyListeners(metric);
    });

    _paintErrorSubscription = _reporter.paintStream.listen((metric) {
      if (metric.attributes?['error'] != null) {
        _reporter.reportError(
          'Paint Error',
          attributes: {
            'component': metric.componentName,
            'paint_type': metric.paintType,
            'error': metric.attributes!['error'],
          },
        );
      }
    });

    // Start error rate monitoring
    _startErrorRateMonitoring();
  }

  void _processError(ErrorMetric error) {
    _errorHistory.add(error);

    // Group by component if available
    final component = error.attributes?['component'] as String?;
    if (component != null) {
      if (!_errorsByComponent.containsKey(component)) {
        _errorsByComponent[component] = [];
      }
      _errorsByComponent[component]!.add(error);
    }

    // Update error rates
    final errorType = _categorizeError(error);
    if (!_errorRates.containsKey(errorType)) {
      _errorRates[errorType] = [];
    }
    _errorRates[errorType]!.add(DateTime.now().millisecondsSinceEpoch);

    // Check for anomalous error rates
    _checkErrorRateAnomaly(errorType);
  }

  String _categorizeError(ErrorMetric error) {
    // Categorize based on stack trace and attributes
    if (error.stackTrace?.toString().contains('painting') ?? false) {
      return 'paint_error';
    }
    if (error.attributes?['type'] == 'network') {
      return 'network_error';
    }
    if (error.attributes?['component'] != null) {
      return 'component_error.${error.attributes!['component']}';
    }
    return 'general_error';
  }

  void _startErrorRateMonitoring() {
    _errorRateTimer?.cancel();
    _errorRateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = DateTime.now();
      final cutoff = now.subtract(_errorRateWindow);
      final cutoffMs = cutoff.millisecondsSinceEpoch;

      // Clean up old error entries and check rates
      _errorRates.forEach((type, timestamps) {
        timestamps.removeWhere((ts) => ts < cutoffMs);
        _checkErrorRateAnomaly(type);
      });

      // Remove empty error types
      _errorRates.removeWhere((_, timestamps) => timestamps.isEmpty);
    });
  }

  void _checkErrorRateAnomaly(String errorType) {
    final timestamps = _errorRates[errorType];
    if (timestamps == null || timestamps.isEmpty) return;

    // Calculate error rate per minute
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    final recentErrors = timestamps.where(
      (ts) => ts > oneMinuteAgo.millisecondsSinceEpoch
    ).length;

    // Alert if error rate exceeds threshold (e.g., more than 5 errors per minute)
    if (recentErrors >= 5) {
      _reporter.reportError(
        'High Error Rate Detected',
        attributes: {
          'error_type': errorType,
          'error_rate': recentErrors,
          'window': '1 minute',
        },
      );
    }
  }

  ErrorSummary getErrorSummary(String errorType) {
    final errors = _errorHistory.where(
      (e) => _categorizeError(e) == errorType
    ).toList();

    if (errors.isEmpty) {
      throw ArgumentError('No errors found for type: $errorType');
    }

    // Collect affected components
    final components = <String>{};
    final attributeFreq = <String, int>{};

    for (final error in errors) {
      if (error.attributes != null) {
        error.attributes!.forEach((key, value) {
          final attrKey = '$key:$value';
          attributeFreq[attrKey] = (attributeFreq[attrKey] ?? 0) + 1;
        });

        if (error.attributes!.containsKey('component')) {
          components.add(error.attributes!['component'] as String);
        }
      }
    }

    return ErrorSummary(
      errorType: errorType,
      occurrences: errors.length,
      firstOccurrence: errors.first.timestamp,
      lastOccurrence: errors.last.timestamp,
      affectedComponents: components.toList(),
      attributeFrequency: attributeFreq,
    );
  }

  List<ErrorMetric> getErrorsForComponent(String component) {
    return List.unmodifiable(_errorsByComponent[component] ?? []);
  }

  Map<String, int> getErrorCountByType() {
    final counts = <String, int>{};
    for (final error in _errorHistory) {
      final type = _categorizeError(error);
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  void addListener(ErrorMetricListener listener) {
    _listeners.add(listener);
  }

  void removeListener(ErrorMetricListener listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(ErrorMetric metric) {
    for (final listener in _listeners) {
      listener(metric);
    }
  }

  void dispose() {
    _errorSubscription.cancel();
    _paintErrorSubscription.cancel();
    _errorRateTimer?.cancel();
    _listeners.clear();
  }
}
