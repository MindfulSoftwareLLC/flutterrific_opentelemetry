// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import '../flutterrific_otel.dart';
import 'ui_meter.dart';
import 'flutter_metric_reporter.dart';

/// Bridge class to connect FlutterMetricReporter metrics to OpenTelemetry metrics
class OTelMetricsBridge {
  OTelMetricsBridge._();

  static final instance = OTelMetricsBridge._();

  bool _initialized = false;

  // Lazy-loaded meters
  UIMeter? _performanceMeter;
  UIMeter? _navigationMeter;
  UIMeter? _errorMeter;
  UIMeter? _userInteractionMeter;
  UIMeter? _paintMeter;

  // Lazy-loaded instruments
  Counter<int>? _errorCounter;
  Histogram<double>? _frameTimeHistogram;
  Histogram<double>? _pageLoadTimeHistogram;
  Histogram<double>? _navTimeHistogram;
  Histogram<double>? _interactionTimeHistogram;
  Histogram<double>? _paintTimeHistogram;
  Histogram<double>? _layoutShiftHistogram;
  ObservableGauge<double>? _apdexScoreGauge;

  /// Initialize the metrics bridge by subscribing to metrics streams
  void initialize() {
    if (_initialized) return;

    if (OTelLog.isLogMetrics()) {
      OTelLog.logMetric('Initializing OTelMetricsBridge');
    }

    final reporter = FlutterMetricReporter();

    // Subscribe to performance metrics
    reporter.performanceStream.listen(_handlePerformanceMetric);

    // Subscribe to page load metrics
    reporter.pageLoadStream.listen(_handlePageLoadMetric);

    // Subscribe to navigation metrics
    reporter.navigationStream.listen(_handleNavigationMetric);

    // Subscribe to error metrics
    reporter.errorStream.listen(_handleErrorMetric);

    // Subscribe to user interaction metrics
    reporter.interactionStream.listen(_handleUserInteractionMetric);

    // Subscribe to paint metrics
    reporter.paintStream.listen(_handlePaintMetric);

    // Subscribe to layout shift metrics
    reporter.layoutShiftStream.listen(_handleLayoutShiftMetric);

    // Setup observable gauge for Apdex score
    _setupApdexGauge();

    _initialized = true;
  }

  /// Setup the Apdex gauge
  void _setupApdexGauge() {
    _apdexScoreGauge = _getPerformanceMeter().createObservableGauge<double>(
      name: 'flutter.apdex.score',
      description: 'Application Performance Index score',
      unit: '{score}',
      callback: (APIObservableResult<double> result) {
        // Get the current Apdex score from the reporter
        final apdexScore = FlutterMetricReporter().currentApdexScore;

        // Record the observation
        result.observe(apdexScore, OTel.attributes());
      },
    );
  }

  /// Record route change events
  void recordRouteChange({required String name, required String action}) {
    if (!_initialized) return;

    final attributes =
        <String, Object>{
          'route.name': name,
          'route.action': action,
        }.toAttributes();

    _getNavigationMeter()
        .createCounter<int>(
          name: 'flutter.navigation.route_change',
          description: 'Route change events',
          unit: '{events}',
        )
        .add(1, attributes);
  }

  /// Record lifecycle state changes
  void recordLifecycleState(String state) {
    if (!_initialized) return;

    // Add a lifecycle state attribute
    final attributes =
        <String, Object>{'lifecycle.state': state}.toAttributes();

    // Record the state change timestamp
    final now = DateTime.now().millisecondsSinceEpoch;
    _getNavigationMeter()
        .createHistogram<double>(
          name: 'flutter.lifecycle.state_change',
          description: 'Lifecycle state changes',
          unit: 'ms',
        )
        .record(now.toDouble(), attributes);
  }

  // Lazy getters for meters

  UIMeter _getPerformanceMeter() {
    return _performanceMeter ??= FlutterOTel.meter(
      name: 'flutter.performance',
      version: '1.0.0',
    );
  }

  UIMeter _getNavigationMeter() {
    return _navigationMeter ??= FlutterOTel.meter(
      name: 'flutter.navigation',
      version: '1.0.0',
    );
  }

  UIMeter _getErrorMeter() {
    return _errorMeter ??= FlutterOTel.meter(
      name: 'flutter.errors',
      version: '1.0.0',
    );
  }

  UIMeter _getUserInteractionMeter() {
    return _userInteractionMeter ??= FlutterOTel.meter(
      name: 'flutter.interaction',
      version: '1.0.0',
    );
  }

  UIMeter _getPaintMeter() {
    return _paintMeter ??= FlutterOTel.meter(
      name: 'flutter.paint',
      version: '1.0.0',
    );
  }

  // Lazy getters for instruments

  Histogram<double> _getFrameTimeHistogram() {
    return _frameTimeHistogram ??= _getPerformanceMeter()
        .createHistogram<double>(
          name: 'flutter.frame.duration',
          description: 'Measures Flutter frame rendering times',
          unit: 'ms',
        );
  }

  Histogram<double> _getPageLoadTimeHistogram() {
    return _pageLoadTimeHistogram ??= _getPerformanceMeter()
        .createHistogram<double>(
          name: 'flutter.page.load_time',
          description: 'Measures Flutter page load times',
          unit: 'ms',
        );
  }

  Histogram<double> _getNavTimeHistogram() {
    return _navTimeHistogram ??= _getNavigationMeter().createHistogram<double>(
      name: 'flutter.navigation.duration',
      description: 'Measures Flutter navigation transition times',
      unit: 'ms',
    );
  }

  Counter<int> _getErrorCounter() {
    return _errorCounter ??= _getErrorMeter().createCounter<int>(
      name: 'flutter.errors.count',
      description: 'Counts Flutter application errors',
      unit: '{errors}',
    );
  }

  Histogram<double> _getInteractionTimeHistogram() {
    return _interactionTimeHistogram ??= _getUserInteractionMeter()
        .createHistogram<double>(
          name: 'flutter.interaction.response_time',
          description: 'Measures Flutter user interaction response times',
          unit: 'ms',
        );
  }

  Histogram<double> _getPaintTimeHistogram() {
    return _paintTimeHistogram ??= _getPaintMeter().createHistogram<double>(
      name: 'flutter.paint.duration',
      description: 'Measures Flutter paint operation durations',
      unit: 'ms',
    );
  }

  Histogram<double> _getLayoutShiftHistogram() {
    return _layoutShiftHistogram ??= _getPerformanceMeter()
        .createHistogram<double>(
          name: 'flutter.layout.shift_score',
          description: 'Measures Flutter layout shift scores',
          unit: '{score}',
        );
  }

  /// Handle performance metrics
  void _handlePerformanceMetric(PerformanceMetric metric) {
    if (!_initialized) return;

    if (OTelLog.isLogMetrics()) {
      OTelLog.logMetric(
        'OTelMetricsBridge: Processing performance metric: ${metric.name}',
      );
    }

    // Create attributes for this measurement
    final attributes = <String, Object>{'name': metric.name}.toAttributes();

    // Record frame time in histogram
    _getFrameTimeHistogram().record(
      metric.duration.inMilliseconds.toDouble(),
      attributes,
    );
  }

  /// Handle page load metrics
  void _handlePageLoadMetric(PageLoadMetric metric) {
    if (!_initialized) return;

    // Create attributes
    final attributes =
        <String, Object>{
          'page': metric.pageName,
          'transition_type': metric.transitionType ?? 'unknown',
        }.toAttributes();

    // Record the page load time
    _getPageLoadTimeHistogram().record(
      metric.loadTime.inMilliseconds.toDouble(),
      attributes,
    );
  }

  /// Handle navigation metrics
  void _handleNavigationMetric(NavigationMetric metric) {
    if (!_initialized) return;

    // Create attributes
    final attributes =
        <String, Object>{
          'from_route': metric.fromRoute ?? 'unknown',
          'to_route': metric.toRoute ?? 'unknown',
          'nav_type': metric.navigationType,
        }.toAttributes();

    // Record the navigation time
    if (metric.duration != null) {
      _getNavTimeHistogram().record(
        metric.duration!.inMilliseconds.toDouble(),
        attributes,
      );
    }
  }

  /// Handle error metrics
  void _handleErrorMetric(ErrorMetric metric) {
    if (!_initialized) return;

    // Create attributes
    final attributes =
        <String, Object>{
          'error_type': metric.error,
          'error_stack': metric.stackTrace?.toString() ?? 'none',
        }.toAttributes();

    // Increment the error counter
    _getErrorCounter().add(1, attributes);
  }

  /// Handle user interaction metrics
  void _handleUserInteractionMetric(UserInteractionMetric metric) {
    if (!_initialized) return;

    // Create attributes
    final attributes =
        <String, Object>{
          'interaction_type': metric.actionType,
          'screen': metric.screenName,
        }.toAttributes();

    // Record the interaction response time
    if (metric.responseTime != null) {
      _getInteractionTimeHistogram().record(
        metric.responseTime!.inMilliseconds.toDouble(),
        attributes,
      );
    }
  }

  /// Handle paint metrics
  void _handlePaintMetric(PaintMetric metric) {
    if (!_initialized) return;

    // Create attributes
    final attributes =
        <String, Object>{
          'component': metric.componentName,
          'paint_type': metric.paintType,
        }.toAttributes();

    // Record the paint time
    _getPaintTimeHistogram().record(
      metric.paintDuration.inMilliseconds.toDouble(),
      attributes,
    );
  }

  /// Handle layout shift metrics
  void _handleLayoutShiftMetric(LayoutShiftMetric metric) {
    if (!_initialized) return;

    // Create attributes
    final attributes =
        <String, Object>{
          'component': metric.componentName,
          'cause': metric.cause ?? 'unknown',
        }.toAttributes();

    // Record the layout shift score
    _getLayoutShiftHistogram().record(metric.shiftScore, attributes);
  }
}
