// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'dart:async';
import '../flutter_metric_reporter.dart';

typedef ShiftMetricListener = void Function(LayoutShiftMetric metric);

class ShiftTracker {
  static final ShiftTracker _instance = ShiftTracker._internal();
  factory ShiftTracker() => _instance;

  final Map<String, List<LayoutShiftMetric>> _shiftHistory = {};
  final Map<String, double> _cumulativeShiftScores = {};
  final List<ShiftMetricListener> _listeners = [];

  late final StreamSubscription<LayoutShiftMetric> _shiftSubscription;
  late final StreamSubscription<PerformanceMetric> _performanceSubscription;
  late final FlutterMetricReporter _reporter;

  // Window for grouping related layout shifts
  static const _sessionWindowDuration = Duration(milliseconds: 1000);
  DateTime? _lastShiftTime;
  double _currentSessionScore = 0.0;

  ShiftTracker._internal() {
    _reporter = FlutterMetricReporter();

    _shiftSubscription = _reporter.layoutShiftStream.listen((metric) {
      _processShiftMetric(metric);
      _notifyListeners(metric);
    });

    _performanceSubscription = _reporter.performanceStream.listen((metric) {
      if (metric.name.contains('animation') || metric.name.contains('scroll')) {
        _checkForLayoutShift(metric);
      }
    });
  }

  void _processShiftMetric(LayoutShiftMetric metric) {
    // Initialize history for component if needed
    if (!_shiftHistory.containsKey(metric.componentName)) {
      _shiftHistory[metric.componentName] = [];
      _cumulativeShiftScores[metric.componentName] = 0.0;
    }

    _shiftHistory[metric.componentName]!.add(metric);

    // Update cumulative score within session windows
    final now = DateTime.now();
    if (_lastShiftTime != null &&
        now.difference(_lastShiftTime!) > _sessionWindowDuration) {
      // New session window, update cumulative score
      _cumulativeShiftScores[metric.componentName] =
          _cumulativeShiftScores[metric.componentName]! + _currentSessionScore;
      _currentSessionScore = metric.shiftScore;
    } else {
      _currentSessionScore += metric.shiftScore;
    }
    _lastShiftTime = now;
  }

  void _checkForLayoutShift(PerformanceMetric metric) {
    final componentName = metric.attributes?['component_name'] as String?;
    if (componentName != null && metric.duration > Duration.zero) {
      // Calculate a shift score based on performance duration
      // This is a simplified approximation - in a web context we'd use actual layout shift calculations
      double shiftScore = metric.duration.inMilliseconds / 100.0;
      if (shiftScore > 0.01) { // Only report significant shifts
        _reporter.reportLayoutShift(
          componentName,
          shiftScore,
          cause: metric.name.contains('animation') ? 'animation' : 'scroll',
          attributes: metric.attributes,
        );
      }
    }
  }

  double getCumulativeLayoutShift(String componentName) {
    return _cumulativeShiftScores[componentName] ?? 0.0;
  }

  Map<String, double> getAllCumulativeLayoutShifts() {
    return Map.unmodifiable(_cumulativeShiftScores);
  }

  List<LayoutShiftMetric>? getShiftHistory(String componentName) {
    return _shiftHistory[componentName]?.toList();
  }

  double getCurrentSessionScore() {
    return _currentSessionScore;
  }

  void addListener(ShiftMetricListener listener) {
    _listeners.add(listener);
  }

  void removeListener(ShiftMetricListener listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(LayoutShiftMetric metric) {
    for (final listener in _listeners) {
      listener(metric);
    }
  }

  void dispose() {
    _shiftSubscription.cancel();
    _performanceSubscription.cancel();
    _listeners.clear();
  }
}
