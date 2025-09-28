// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import '../util/platform_detection.dart';

import 'ui_meter.dart';

part 'ui_meter_provider_create.dart';

/// UIMeterProvider extends the standard SDK MeterProvider to provide UI-specific
/// functionality for Flutter applications.
class UIMeterProvider implements MeterProvider {
  /// The underlying SDK MeterProvider
  final MeterProvider _delegate;

  /// Registry of active instruments across all meters
  final Map<String, Set<SDKInstrument>> _instruments = {};

  /// Creates a new UIMeterProvider instance.
  UIMeterProvider._(this._delegate);

  /// Creates an appropriate metric exporter based on the current platform
  ///
  /// This will return an HTTP exporter for web and a gRPC exporter for native platforms
  MetricExporter createPlatformMetricExporter(
    String endpoint, {
    bool insecure = false,
  }) {
    return PlatformDetection.createMetricExporter(
      endpoint: endpoint,
      insecure: insecure,
    );
  }

  @override
  APIMeter getMeter({
    required String name,
    String? version,
    String? schemaUrl,
    Attributes? attributes,
  }) {
    // Get the base meter from the delegate
    final apiMeter =
        _delegate.getMeter(
              name: name,
              version: version,
              schemaUrl: schemaUrl,
              attributes: attributes,
            )
            as Meter;

    // Wrap it in our UIMeter
    return UIMeterCreate.create(delegate: apiMeter);
  }

  /// Registers an instrument with this provider
  ///
  /// This allows the provider to track all active instruments for metrics collection
  @override
  void registerInstrument(String meterName, SDKInstrument instrument) {
    // Delegate to the underlying MeterProvider if it supports registering instruments
    try {
      _delegate.registerInstrument(meterName, instrument);
      return; // Successfully delegated
    } catch (e) {
      // Fallback to local implementation if the delegate doesn't support it
      if (OTelLog.isLogMetrics()) {
        OTelLog.logMetric(
          'UIMeterProvider: Could not delegate registerInstrument, using local implementation',
        );
      }
    }

    // Local implementation
    if (!_instruments.containsKey(meterName)) {
      _instruments[meterName] = {};
    }

    _instruments[meterName]!.add(instrument);

    if (OTelLog.isLogMetrics()) {
      OTelLog.logMetric(
        'UIMeterProvider: Registered instrument "${instrument.name}" for meter "$meterName"',
      );
    }
  }

  /// Collects all metrics from all instruments across all meters
  ///
  /// This is called by metric readers to gather the current metrics
  @override
  Future<List<Metric>> collectAllMetrics() async {
    // Delegate to the underlying MeterProvider if it supports collecting metrics
    try {
      final metrics = await (_delegate as dynamic).collectAllMetrics();
      if (metrics is List<Metric>) {
        return metrics;
      }
    } catch (e) {
      // Fallback to local implementation if the delegate doesn't support it
      if (OTelLog.isLogMetrics()) {
        OTelLog.logMetric(
          'UIMeterProvider: Could not delegate collectAllMetrics, using local implementation',
        );
      }
    }

    // Local implementation
    if (isShutdown) {
      return [];
    }

    final allMetrics = <Metric>[];

    // Collect from each meter's instruments
    for (final entry in _instruments.entries) {
      final meterName = entry.key;
      final instruments = entry.value;

      if (OTelLog.isLogMetrics()) {
        OTelLog.logMetric(
          'UIMeterProvider: Collecting metrics from ${instruments.length} instruments in meter "$meterName"',
        );
      }

      // Collect metrics from each instrument
      for (final instrument in instruments) {
        try {
          final metrics = instrument.collectMetrics();
          if (metrics.isNotEmpty) {
            allMetrics.addAll(metrics);

            if (OTelLog.isLogMetrics()) {
              OTelLog.logMetric(
                'UIMeterProvider: Collected ${metrics.length} metrics from instrument "${instrument.name}"',
              );
            }
          }
        } catch (e) {
          if (OTelLog.isLogMetrics()) {
            OTelLog.logMetric(
              'UIMeterProvider: Error collecting metrics from instrument "${instrument.name}": $e',
            );
          }
        }
      }
    }

    if (OTelLog.isLogMetrics()) {
      OTelLog.logMetric(
        'UIMeterProvider: Collected ${allMetrics.length} total metrics',
      );
    }

    return allMetrics;
  }

  // Forward all other methods and properties to the delegate
  @override
  void addMetricReader(MetricReader reader) {
    _delegate.addMetricReader(reader);
  }

  @override
  void addView(View view) {
    _delegate.addView(view);
  }

  @override
  Future<bool> forceFlush() {
    return _delegate.forceFlush();
  }

  @override
  Future<bool> shutdown() {
    return _delegate.shutdown();
  }

  @override
  Resource? get resource => _delegate.resource;

  @override
  String get endpoint => _delegate.endpoint;

  @override
  String get serviceName => _delegate.serviceName;

  @override
  String? get serviceVersion => _delegate.serviceVersion;

  @override
  bool get isShutdown => _delegate.isShutdown;

  @override
  bool get enabled => _delegate.enabled;

  @override
  List<MetricReader> get metricReaders => _delegate.metricReaders;

  @override
  List<View> get views => _delegate.views;

  /// Returns the delegate MeterProvider for direct access when needed
  @override
  MeterProvider get delegate => _delegate;

  @override
  set enabled(bool value) {
    // TODO: implement enabled
  }

  @override
  set endpoint(String value) {
    // TODO: implement endpoint
  }

  @override
  set isShutdown(bool value) {
    // TODO: implement isShutdown
  }

  @override
  set resource(Resource? value) {
    // TODO: implement resource
  }

  @override
  set serviceName(String value) {
    // TODO: implement serviceName
  }

  @override
  set serviceVersion(String? value) {
    // TODO: implement serviceVersion
  }
}
