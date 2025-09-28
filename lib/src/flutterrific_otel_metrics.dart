// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart' as sdk;
import 'flutterrific_otel.dart';
import 'metrics/otel_metrics_bridge.dart';

/// Extension methods for FlutterOTel related to metrics functionality.
/// Note: These are not actual extensions but helper methods that should be added
/// directly to the FlutterOTel class.
class FlutterOTelMetrics {
  /// Get the metrics reporter for recording metrics
  static OTelMetricsBridge get metricReporter => OTelMetricsBridge.instance;

  /// Records a metric using the metrics system
  static void recordMetric({
    required String name,
    required num value,
    String? unit,
    String metricType = 'histogram',
    Map<String, Object>? attributes,
  }) {
    final meter = FlutterOTel.meter(name: 'flutter.metrics');
    final attrs = attributes?.toAttributes() ?? sdk.OTel.attributes();

    switch (metricType.toLowerCase()) {
      case 'counter':
        meter
            .createCounter(
              name: name,
              description: 'Custom flutter metric',
              unit: unit,
            )
            .add(value, attrs);
        break;
      case 'gauge':
        meter
            .createGauge(
              name: name,
              description: 'Custom flutter metric',
              unit: unit,
            )
            .record(value, attrs);
        break;
      case 'histogram':
      default:
        meter
            .createHistogram(
              name: name,
              description: 'Custom flutter metric',
              unit: unit,
            )
            .record(value, attrs);
        break;
    }
  }

  /// Records a performance metric (convenience method)
  static void recordPerformanceMetric(
    String name,
    Duration duration, {
    Map<String, Object>? attributes,
  }) {
    recordMetric(
      name: 'perf.$name',
      value: duration.inMilliseconds,
      unit: 'ms',
      metricType: 'histogram',
      attributes: {'perf.metric.name': name, ...?attributes},
    );
  }

  /// Records a navigation timing metric
  static void recordNavigationMetric(
    String fromRoute,
    String toRoute,
    Duration duration, {
    Map<String, Object>? attributes,
  }) {
    recordMetric(
      name: 'navigation.duration',
      value: duration.inMilliseconds,
      unit: 'ms',
      metricType: 'histogram',
      attributes: {
        'navigation.from_route': fromRoute,
        'navigation.to_route': toRoute,
        ...?attributes,
      },
    );
  }

  /// Records a user interaction metric
  static void recordInteractionMetric(
    String type,
    Duration? responseTime, {
    String? screen,
    Map<String, Object>? attributes,
  }) {
    if (responseTime == null) return;

    recordMetric(
      name: 'interaction.response_time',
      value: responseTime.inMilliseconds,
      unit: 'ms',
      metricType: 'histogram',
      attributes: {
        'interaction.type': type,
        if (screen != null) 'screen': screen,
        ...?attributes,
      },
    );
  }

  /// Records an error count metric
  static void recordError(
    String errorType, {
    String? message,
    String? location,
    Map<String, Object>? attributes,
  }) {
    recordMetric(
      name: 'error.count',
      value: 1,
      unit: '{errors}',
      metricType: 'counter',
      attributes: {
        'error.type': errorType,
        if (message != null) 'error.message': message,
        if (location != null) 'error.location': location,
        ...?attributes,
      },
    );
  }
}
