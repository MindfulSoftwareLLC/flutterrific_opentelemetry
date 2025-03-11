// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'dart:async';
import '../flutter_metric_reporter.dart';

typedef PaintMetricListener = void Function(PaintMetric metric);

class PaintTracker {
  static final PaintTracker _instance = PaintTracker._internal();
  factory PaintTracker() => _instance;

  final Map<String, Map<String, Duration>> _componentPaintHistory = {};
  final Map<String, DateTime> _firstPaintTimes = {};
  final Map<String, PaintMetric> _largestContentfulPaints = {};
  final List<PaintMetricListener> _listeners = [];

  late final StreamSubscription<PaintMetric> _paintSubscription;
  late final StreamSubscription<PerformanceMetric> _performanceSubscription;
  late final FlutterMetricReporter _reporter;

  PaintTracker._internal() {
    _reporter = FlutterMetricReporter();

    _paintSubscription = _reporter.paintStream.listen((metric) {
      _processPaintMetric(metric);
      _notifyListeners(metric);
    });

    _performanceSubscription = _reporter.performanceStream.listen((metric) {
      if (metric.name == 'component_build_time') {
        final componentName = metric.attributes?['component_name'] as String?;
        if (componentName != null) {
          _reporter.reportPaint(
            componentName,
            metric.duration,
            _determineContentfulPaintType(componentName, metric.duration),
            attributes: {
              ...?metric.attributes,
              'is_rebuild': _firstPaintTimes.containsKey(componentName),
            },
          );
        }
      }
    });
  }

  String _determineContentfulPaintType(String componentName, Duration duration) {
    if (!_firstPaintTimes.containsKey(componentName)) {
      _firstPaintTimes[componentName] = DateTime.now();
      return 'first_paint';
    }

    final existingLCP = _largestContentfulPaints[componentName];
    if (existingLCP == null || duration > existingLCP.paintDuration) {
      _largestContentfulPaints[componentName] = PaintMetric(
        componentName: componentName,
        paintDuration: duration,
        paintType: 'largest_contentful_paint',
      );
      return 'largest_contentful_paint';
    }

    return 'paint';
  }

  void _processPaintMetric(PaintMetric metric) {
    if (!_componentPaintHistory.containsKey(metric.componentName)) {
      _componentPaintHistory[metric.componentName] = {};
    }
    _componentPaintHistory[metric.componentName]![metric.paintType] = metric.paintDuration;

    if (metric.paintType == 'first_paint' || metric.paintType == 'first_contentful_paint') {
      _firstPaintTimes[metric.componentName] = metric.timestamp;
    }
  }

  Duration? getAveragePaintTime(String componentName, String paintType) {
    return _componentPaintHistory[componentName]?[paintType];
  }

  PaintMetric? getLargestContentfulPaint(String componentName) {
    return _largestContentfulPaints[componentName];
  }

  Map<String, Duration> getFirstPaintTimes() {
    Map<String, Duration> times = {};
    _firstPaintTimes.forEach((component, timestamp) {
      times[component] = _componentPaintHistory[component]?['first_paint'] ?? Duration.zero;
    });
    return times;
  }

  Map<String, Duration> getFirstContentfulPaintTimes() {
    Map<String, Duration> times = {};
    _componentPaintHistory.forEach((component, metrics) {
      if (metrics.containsKey('first_contentful_paint')) {
        times[component] = metrics['first_contentful_paint']!;
      }
    });
    return times;
  }

  void addListener(PaintMetricListener listener) {
    _listeners.add(listener);
  }

  void removeListener(PaintMetricListener listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(PaintMetric metric) {
    for (final listener in _listeners) {
      listener(metric);
    }
  }

  void dispose() {
    _paintSubscription.cancel();
    _performanceSubscription.cancel();
    _listeners.clear();
  }
}
