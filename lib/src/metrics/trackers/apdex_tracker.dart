// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'dart:async';
import '../flutter_metric_reporter.dart';

typedef ApdexScoreListener = void Function(String component, double score, Duration period);

class ApdexResult {
  final String componentName;
  final int satisfiedCount;
  final int toleratingCount;
  final int frustratingCount;
  final Duration period;
  final DateTime timestamp;

  ApdexResult({
    required this.componentName,
    required this.satisfiedCount,
    required this.toleratingCount,
    required this.frustratingCount,
    required this.period,
    required this.timestamp,
  });

  double get score => (satisfiedCount + (toleratingCount / 2)) / totalCount;
  int get totalCount => satisfiedCount + toleratingCount + frustratingCount;
}

class ApdexTracker {
  static final ApdexTracker _instance = ApdexTracker._internal();
  factory ApdexTracker() => _instance;

  // Default thresholds
  static const defaultTargetDuration = Duration(milliseconds: 500);
  static const defaultToleratingDuration = Duration(seconds: 2);

  final Map<String, List<Duration>> _responseTimeHistory = {};
  final Map<String, Duration> _targetThresholds = {};
  final Map<String, Duration> _toleratingThresholds = {};
  final List<ApdexScoreListener> _listeners = [];
  final Map<String, Timer> _reportingTimers = {};

  late final StreamSubscription<PerformanceMetric> _performanceSubscription;
  late final StreamSubscription<UserInteractionMetric> _interactionSubscription;
  late final FlutterMetricReporter _reporter;

  static const _reportingPeriod = Duration(minutes: 1);

  ApdexTracker._internal() {
    _reporter = FlutterMetricReporter();

    _performanceSubscription = _reporter.performanceStream.listen((metric) {
      _processResponseTime(metric.name, metric.duration);
    });

    _interactionSubscription = _reporter.interactionStream.listen((metric) {
      if (metric.responseTime != null) {
        _processResponseTime('${metric.screenName}.${metric.actionType}', metric.responseTime!);
      }
    });
  }

  void setThresholds(String component, {
    Duration? targetDuration,
    Duration? toleratingDuration,
  }) {
    if (targetDuration != null) {
      _targetThresholds[component] = targetDuration;
    }
    if (toleratingDuration != null) {
      _toleratingThresholds[component] = toleratingDuration;
    }

    // Start periodic reporting for this component if not already started
    if (!_reportingTimers.containsKey(component)) {
      _reportingTimers[component] = Timer.periodic(_reportingPeriod, (_) {
        final result = calculateApdexScore(component);
        if (result != null) {
          _notifyListeners(component, result.score, _reportingPeriod);
        }
      });
    }
  }

  void _processResponseTime(String component, Duration responseTime) {
    if (!_responseTimeHistory.containsKey(component)) {
      _responseTimeHistory[component] = [];
      // Set default thresholds for new components
      _targetThresholds[component] = defaultTargetDuration;
      _toleratingThresholds[component] = defaultToleratingDuration;
    }

    _responseTimeHistory[component]!.add(responseTime);

    // Calculate and report current Apdex score
    final result = calculateApdexScore(component);
    if (result != null) {
      _notifyListeners(component, result.score, _reportingPeriod);
    }
  }

  ApdexResult? calculateApdexScore(String component, {Duration? period}) {
    final responseTimes = _responseTimeHistory[component];
    if (responseTimes == null || responseTimes.isEmpty) return null;

    final targetThreshold = _targetThresholds[component] ?? defaultTargetDuration;
    final toleratingThreshold = _toleratingThresholds[component] ?? defaultToleratingDuration;

    // Filter responses within the specified period
    final now = DateTime.now();
    final periodStart = now.subtract(period ?? _reportingPeriod);

    var satisfied = 0;
    var tolerating = 0;
    var frustrating = 0;

    for (final time in responseTimes) {
      if (time <= targetThreshold) {
        satisfied++;
      } else if (time <= toleratingThreshold) {
        tolerating++;
      } else {
        frustrating++;
      }
    }

    return ApdexResult(
      componentName: component,
      satisfiedCount: satisfied,
      toleratingCount: tolerating,
      frustratingCount: frustrating,
      period: period ?? _reportingPeriod,
      timestamp: now,
    );
  }

  Map<String, ApdexResult> calculateAllApdexScores({Duration? period}) {
    final Map<String, ApdexResult> results = {};
    for (final component in _responseTimeHistory.keys) {
      final result = calculateApdexScore(component, period: period);
      if (result != null) {
        results[component] = result;
      }
    }
    return results;
  }

  void addListener(ApdexScoreListener listener) {
    _listeners.add(listener);
  }

  void removeListener(ApdexScoreListener listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(String component, double score, Duration period) {
    for (final listener in _listeners) {
      listener(component, score, period);
    }
  }

  void dispose() {
    _performanceSubscription.cancel();
    _interactionSubscription.cancel();
    _reportingTimers.forEach((_, timer) => timer.cancel());
    _reportingTimers.clear();
    _listeners.clear();
  }
}
