// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import '../../flutterrific_opentelemetry.dart';
import 'trackers/page_tracker.dart';
import 'trackers/paint_tracker.dart';
import 'trackers/shift_tracker.dart';
import 'trackers/apdex_tracker.dart';
import 'trackers/user_input_tracker.dart';
import 'trackers/error_tracker.dart';
import 'listeners/console_metrics_listener.dart';

class MetricsService {
  static void dispose() {
    if (OTelLog.isLogMetrics()) {
      OTelLog.logMetric('MetricsService: Disposing and flushing metrics');
    }

    // Force flush metrics before disposing
    OTel.meterProvider().forceFlush();

    // Dispose in reverse order of initialization
    ConsoleMetricsListener().dispose();

    // Dispose of all trackers
    PageTracker().dispose();
    PaintTracker().dispose();
    ShiftTracker().dispose();
    ApdexTracker().dispose();
    UserInputTracker().dispose();
    ErrorTracker().dispose();

    // Dispose of the metric reporter last
    FlutterMetricReporter().dispose();

    // Final flush after everything is disposed
    OTel.meterProvider().forceFlush();
  }

  // Utility method to check if metrics are flowing
  static void debugPrintMetricsStatus() {
    final reporter = FlutterMetricReporter();
    final console = ConsoleMetricsListener();

    if (OTelLog.isLogMetrics()) {
      OTelLog.logMetric("Metrics debug status check");
    }

    // Force a test metric to verify the pipeline
    reporter.reportPerformanceMetric(
      'metrics_test',
      Duration(milliseconds: 100),
      attributes: {'test': true, 'debug': 'true'},
    );

    // Force metrics to be exported immediately
    OTel.meterProvider().forceFlush();

    if (OTelLog.isLogMetrics()) {
      OTelLog.logMetric("Forced metric flush after test metric");
    }
  }
}
