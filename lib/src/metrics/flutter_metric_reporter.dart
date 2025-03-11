// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// Base class for all metric types that includes required timestamp
abstract class BaseMetric {
  final DateTime timestamp;
  final Map<String, dynamic>? attributes;

  BaseMetric({DateTime? timestamp, this.attributes})
    : timestamp = timestamp ?? DateTime.now();
}

class PerformanceMetric extends BaseMetric {
  final String name;
  final Duration duration;

  PerformanceMetric({
    required this.name,
    required this.duration,
    super.attributes,
    super.timestamp,
  });
}

class PageLoadMetric extends BaseMetric {
  final String pageName;
  final Duration loadTime;
  final String? transitionType;

  PageLoadMetric({
    required this.pageName,
    required this.loadTime,
    this.transitionType,
    super.attributes,
    super.timestamp,
  });
}

class ErrorMetric extends BaseMetric {
  final String error;
  final StackTrace? stackTrace;

  ErrorMetric({
    required this.error,
    this.stackTrace,
    super.attributes,
    super.timestamp,
  });
}

class UserInteractionMetric extends BaseMetric {
  final String screenName;
  final String actionType;
  final Duration? responseTime;

  UserInteractionMetric({
    required this.screenName,
    required this.actionType,
    this.responseTime,
    super.attributes,
    super.timestamp,
  });
}

class NavigationMetric extends BaseMetric {
  final String? fromRoute;
  final String? toRoute;
  final String navigationType;
  final Duration? duration;

  NavigationMetric({
    this.fromRoute,
    this.toRoute,
    required this.navigationType,
    this.duration,
    super.attributes,
    super.timestamp,
  });
}

class PaintMetric extends BaseMetric {
  final String componentName;
  final Duration paintDuration;
  final String paintType; // 'first_paint', 'first_contentful_paint', 'largest_contentful_paint'

  PaintMetric({
    required this.componentName,
    required this.paintDuration,
    required this.paintType,
    super.attributes,
    super.timestamp,
  });
}

class LayoutShiftMetric extends BaseMetric {
  final String componentName;
  final double shiftScore;
  final String? cause; // e.g., 'animation', 'scroll', 'resize'

  LayoutShiftMetric({
    required this.componentName,
    required this.shiftScore,
    this.cause,
    super.attributes,
    super.timestamp,
  });
}

//TODO - rename and make a simpler API
class FlutterMetricReporter extends NavigatorObserver {
  static final FlutterMetricReporter _instance = FlutterMetricReporter._internal();
  factory FlutterMetricReporter() => _instance;

  FlutterMetricReporter._internal() {
    if (OTelLog.isLogMetrics()) OTelLog.logMetric('FlutterMetricReporter: Initializing...');
  }
  
  // Default Apdex score for the application
  // Apdex (Application Performance Index) is a standard to measure user satisfaction with response time
  // Range is 0-1, where 1 is perfect performance
  double _apdexScore = 0.75; // Default value
  
  /// Gets the current Apdex score for the application
  double get currentApdexScore => _apdexScore;
  
  /// Sets the current Apdex score for the application
  set currentApdexScore(double value) {
    if (value >= 0 && value <= 1) {
      _apdexScore = value;
    }
  }

  // Stream controllers for each metric type
  final _performanceController = StreamController<PerformanceMetric>.broadcast();
  final _pageLoadController = StreamController<PageLoadMetric>.broadcast();
  final _errorController = StreamController<ErrorMetric>.broadcast();
  final _interactionController = StreamController<UserInteractionMetric>.broadcast();
  final _navigationController = StreamController<NavigationMetric>.broadcast();
  final _paintController = StreamController<PaintMetric>.broadcast();
  final _layoutShiftController = StreamController<LayoutShiftMetric>.broadcast();

  // Public stream getters
  Stream<PerformanceMetric> get performanceStream => _performanceController.stream;
  Stream<PageLoadMetric> get pageLoadStream => _pageLoadController.stream;
  Stream<ErrorMetric> get errorStream => _errorController.stream;
  Stream<UserInteractionMetric> get interactionStream => _interactionController.stream;
  Stream<NavigationMetric> get navigationStream => _navigationController.stream;
  Stream<PaintMetric> get paintStream => _paintController.stream;
  Stream<LayoutShiftMetric> get layoutShiftStream => _layoutShiftController.stream;

  void reportPerformanceMetric(String name, Duration duration, {Map<String, dynamic>? attributes}) {
    if (OTelLog.isLogMetrics()) {
      OTelLog.logMetric('FlutterMetricReporter: Reporting performance metric: $name');
      OTelLog.logMetric('  Duration: ${duration.inMilliseconds}ms');
      OTelLog.logMetric('  Attributes: ${attributes ?? {}}');
    }
    final metric = PerformanceMetric(
      name: name,
      duration: duration,
      attributes: attributes,
    );
    _performanceController.add(metric);
    
    // For immediate metrics, force flush every time for mobile apps
    // This is not efficient but ensures metrics are sent before app termination
    OTel.meterProvider().forceFlush();
  }

  void reportPageLoad(String pageName, Duration loadTime, {
    String? transitionType,
    Map<String, dynamic>? attributes,
  }) {
    if (OTelLog.isLogMetrics()) OTelLog.logMetric('FlutterMetricReporter: Reporting page load: $pageName');
    _pageLoadController.add(PageLoadMetric(
      pageName: pageName,
      loadTime: loadTime,
      transitionType: transitionType,
      attributes: attributes,
    ));
  }

  void reportError(String error, {StackTrace? stackTrace, Map<String, dynamic>? attributes}) {
    if (OTelLog.isLogMetrics()) OTelLog.logMetric('FlutterMetricReporter: Reporting error: $error');
    _errorController.add(ErrorMetric(
      error: error,
      stackTrace: stackTrace,
      attributes: attributes,
    ));
  }

  String? _getRouteName(Route<dynamic>? route) {
    if (route == null) return null;
    // Try to get the most meaningful name for the route
    return route.settings.name ??
           (route.settings.arguments as Map<String, dynamic>?)?['path'] ??
           route.toString();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (OTelLog.isLogMetrics()) OTelLog.logMetric('FlutterMetricReporter: didPush - attempting to get route name');
    super.didPush(route, previousRoute);
    final routeName = _getRouteName(route);
    if (OTelLog.isLogMetrics()) OTelLog.logMetric('FlutterMetricReporter: didPush with route name: $routeName');
    if (routeName != null) {
      final startTime = DateTime.now();
      // Report initial page load metric
      reportPerformanceMetric(
        'page_load_start',
        Duration.zero,
        attributes: {
          'route': routeName,
          'from_route': _getRouteName(previousRoute),
          'navigation_type': 'push',
        },
      );

      // Add a post-frame callback to measure the actual render time
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final loadDuration = DateTime.now().difference(startTime);
        reportPageLoad(
          routeName,
          loadDuration,
          transitionType: 'push',
          attributes: {
            'from_route': _getRouteName(previousRoute),
          },
        );
      });
    }
    _trackNavigation('push', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final routeName = _getRouteName(previousRoute);
    if (OTelLog.isLogMetrics()) OTelLog.logMetric('FlutterMetricReporter: didPop with route name: $routeName');
    super.didPop(route, previousRoute);
    if (routeName != null) {
      final startTime = DateTime.now();
      // Report navigation metric
      reportPerformanceMetric(
        'page_transition_start',
        Duration.zero,
        attributes: {
          'route': routeName,
          'from_route': _getRouteName(route),
          'navigation_type': 'pop',
        },
      );

      // Measure transition completion
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final transitionDuration = DateTime.now().difference(startTime);
        reportPageLoad(
          routeName,
          transitionDuration,
          transitionType: 'pop',
          attributes: {
            'from_route': _getRouteName(route),
          },
        );
      });
    }
    _trackNavigation('pop', previousRoute, route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final routeName = _getRouteName(newRoute);
    if (OTelLog.isLogMetrics()) OTelLog.logMetric('FlutterMetricReporter: didReplace with route name: $routeName');
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (routeName != null) {
      final startTime = DateTime.now();
      reportPerformanceMetric(
        'page_replace_start',
        Duration.zero,
        attributes: {
          'route': routeName,
          'from_route': _getRouteName(oldRoute),
          'navigation_type': 'replace',
        },
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final replaceDuration = DateTime.now().difference(startTime);
        reportPageLoad(
          routeName,
          replaceDuration,
          transitionType: 'replace',
          attributes: {
            'from_route': _getRouteName(oldRoute),
          },
        );
      });
    }
    _trackNavigation('replace', newRoute, oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final routeName = _getRouteName(previousRoute);
    if (OTelLog.isLogMetrics()) OTelLog.logMetric('FlutterMetricReporter: didRemove with route name: $routeName');
    super.didRemove(route, previousRoute);
    _trackNavigation('remove', previousRoute, route);
  }

  void _trackNavigation(String type, Route<dynamic>? toRoute, Route<dynamic>? fromRoute) {
    final toRouteName = _getRouteName(toRoute);
    final fromRouteName = _getRouteName(fromRoute);
    if (OTelLog.isLogMetrics()) OTelLog.logMetric('FlutterMetricReporter: Tracking navigation: $type from $fromRouteName to $toRouteName');

    if (toRouteName != null || fromRouteName != null) {
      _navigationController.add(NavigationMetric(
        fromRoute: fromRouteName,
        toRoute: toRouteName,
        navigationType: type,
      ));
    }
  }


  void reportUserInteraction(String screenName, String actionType, {
    Duration? responseTime,
    Map<String, dynamic>? attributes,
  }) {
    if (OTelLog.isLogMetrics()) OTelLog.logMetric('FlutterMetricReporter: Reporting user interaction: $screenName - $actionType');
    _interactionController.add(UserInteractionMetric(
      screenName: screenName,
      actionType: actionType,
      responseTime: responseTime,
      attributes: attributes,
    ));
  }

  void reportPaint(String componentName, Duration paintDuration, String paintType, {
    Map<String, dynamic>? attributes,
  }) {
    if (OTelLog.isLogMetrics()) OTelLog.logMetric('FlutterMetricReporter: Reporting paint: $componentName - $paintType');
    _paintController.add(PaintMetric(
      componentName: componentName,
      paintDuration: paintDuration,
      paintType: paintType,
      attributes: attributes,
    ));
  }

  void reportLayoutShift(String componentName, double shiftScore, {
    String? cause,
    Map<String, dynamic>? attributes,
  }) {
    if (OTelLog.isLogMetrics()) OTelLog.logMetric('FlutterMetricReporter: Reporting layout shift: $componentName');
    _layoutShiftController.add(LayoutShiftMetric(
      componentName: componentName,
      shiftScore: shiftScore,
      cause: cause,
      attributes: attributes,
    ));
  }

  void dispose() {
    if (OTelLog.isLogMetrics()) OTelLog.logMetric('FlutterMetricReporter: Disposing...');
    _performanceController.close();
    _pageLoadController.close();
    _errorController.close();
    _interactionController.close();
    _navigationController.close();
    _paintController.close();
    _layoutShiftController.close();
  }
}
