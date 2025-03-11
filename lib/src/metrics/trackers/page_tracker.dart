// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'dart:async';
import 'package:flutter/widgets.dart';
import '../flutter_metric_reporter.dart';

typedef PageMetricListener = void Function(PageLoadMetric metric);

class PageTracker {
  static final PageTracker _instance = PageTracker._internal();
  factory PageTracker() => _instance;

  final Map<String, List<Duration>> _pageLoadHistory = {};
  final List<PageMetricListener> _listeners = [];
  final Map<String, DateTime> _navigationStartTimes = {};

  late final StreamSubscription<PageLoadMetric> _pageLoadSubscription;
  late final StreamSubscription<NavigationMetric> _navigationSubscription;
  late final FlutterMetricReporter _reporter;

  PageTracker._internal() {
    debugPrint('PageTracker: Initializing...');
    _reporter = FlutterMetricReporter();

    _pageLoadSubscription = _reporter.pageLoadStream.listen((metric) {
      debugPrint('PageTracker: Received page load metric');
      _processPageLoadMetric(metric);
      _notifyListeners(metric);
    });

    _navigationSubscription = _reporter.navigationStream.listen((metric) {
      debugPrint('PageTracker: Received navigation metric for route: ${metric.toRoute}');
      if (metric.toRoute != null) {
        // Record the start time of navigation to calculate total transition time
        _navigationStartTimes[metric.toRoute!] = metric.timestamp;

        // If we have a fromRoute, we can calculate the transition duration
        if (metric.fromRoute != null) {
          debugPrint('PageTracker: Processing navigation from ${metric.fromRoute} to ${metric.toRoute}');
          final lastLoadTime = _pageLoadHistory[metric.fromRoute]?.lastOrNull;
          if (lastLoadTime != null) {
            // Report the complete navigation duration for the previous page
            _reporter.reportPageLoad(
              metric.fromRoute!,
              lastLoadTime,
              transitionType: metric.navigationType,
              attributes: {
                'to_route': metric.toRoute,
                'navigation_type': metric.navigationType,
                'total_transition_time': metric.timestamp.difference(_navigationStartTimes[metric.fromRoute]!),
              },
            );
          }
        }

        // Start tracking load time for the new page
        _reporter.reportPerformanceMetric(
          'page_navigation_start',
          Duration.zero,
          attributes: {
            'route': metric.toRoute,
            'from_route': metric.fromRoute,
            'navigation_type': metric.navigationType,
          },
        );
      }
    });
    debugPrint('PageTracker: Initialization complete');
  }

  void _processPageLoadMetric(PageLoadMetric metric) {
    debugPrint('PageTracker: Processing page load metric for ${metric.pageName}');
    if (!_pageLoadHistory.containsKey(metric.pageName)) {
      _pageLoadHistory[metric.pageName] = [];
    }
    _pageLoadHistory[metric.pageName]!.add(metric.loadTime);

    // Calculate the total transition time if we have a navigation start time
    final navigationStart = _navigationStartTimes[metric.pageName];
    if (navigationStart != null) {
      final totalTransitionTime = metric.timestamp.difference(navigationStart);
      debugPrint('PageTracker: Calculated total transition time: ${totalTransitionTime.inMilliseconds}ms');
      _reporter.reportPerformanceMetric(
        'total_page_transition',
        totalTransitionTime,
        attributes: {
          'page': metric.pageName,
          'transition_type': metric.transitionType,
          'load_time': metric.loadTime.inMilliseconds,
          'transition_overhead': totalTransitionTime.inMilliseconds - metric.loadTime.inMilliseconds,
        },
      );
      _navigationStartTimes.remove(metric.pageName);
    }
  }

  Duration? getAverageLoadTime(String pageName) {
    final times = _pageLoadHistory[pageName];
    if (times == null || times.isEmpty) return null;

    final total = times.reduce((a, b) => a + b);
    return Duration(microseconds: (total.inMicroseconds / times.length).round());
  }

  Map<String, Duration> getAllAverageLoadTimes() {
    final Map<String, Duration> averages = {};
    _pageLoadHistory.forEach((route, times) {
      if (times.isNotEmpty) {
        final total = times.reduce((a, b) => a + b);
        averages[route] = Duration(microseconds: (total.inMicroseconds / times.length).round());
      }
    });
    return averages;
  }

  Map<String, List<Duration>> getLoadTimeHistory() {
    return Map.unmodifiable(_pageLoadHistory);
  }

  void addListener(PageMetricListener listener) {
    debugPrint('PageTracker: Adding listener');
    _listeners.add(listener);
  }

  void removeListener(PageMetricListener listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(PageLoadMetric metric) {
    debugPrint('PageTracker: Notifying ${_listeners.length} listeners');
    for (final listener in _listeners) {
      listener(metric);
    }
  }

  void dispose() {
    _pageLoadSubscription.cancel();
    _navigationSubscription.cancel();
    _listeners.clear();
  }
}
