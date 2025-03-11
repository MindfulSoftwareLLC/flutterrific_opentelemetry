// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart' as sdk;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutterrific_opentelemetry/src/flutterrific_otel.dart';
import 'package:opentelemetry_api/opentelemetry_api.dart';

import '../flutterrific_otel_metrics.dart';
import '../trace/ui_span.dart';

/// Observer for app lifecycle events.  This is added to the application
/// on FlutterOTel.initialize().  See the README for an explanation.
class OTelLifecycleObserver with widgets.WidgetsBindingObserver {
  Uint8List? currentAppLifecycleId;
  AppLifecycleStates? currentAppLifecycleState;
  DateTime? currentAppLifecycleStartTime;

  OTelLifecycleObserver() {
    _appLifecycleChanged(newState: null);
  }

  void _appLifecycleChanged({required widgets.AppLifecycleState? newState}) {
    final startTime = DateTime.now();
    final newStateId = sdk.OTel.spanId().bytes;
    Duration? duration;
    if (currentAppLifecycleState != null) {
      duration = currentAppLifecycleStartTime!.difference(startTime);
      // Record metrics for lifecycle events
      FlutterOTelMetrics.metricReporter.recordLifecycleState(
        currentAppLifecycleState!.name,
      );
    }
    var newSemanticState =
        newState == null
            ? AppLifecycleStates.active
            : AppLifecycleStates.appLifecycleStateFor(newState.name);
    UISpan span = FlutterOTel.tracer.startAppLifecycleSpan(
      newState: newSemanticState,
      startTime: startTime,
      newStateId: newStateId,
      previousState: currentAppLifecycleState,
      previousStateId: currentAppLifecycleId,
      previousStateDuration: duration,
    );
    span.end();
    FlutterOTel.forceFlush();
    FlutterOTel.currentAppLifecycleId = newStateId;
    currentAppLifecycleStartTime = startTime;
    currentAppLifecycleId = newStateId;
    currentAppLifecycleState = newSemanticState;
  }

  @override
  void didChangeAppLifecycleState(widgets.AppLifecycleState state) {
    _appLifecycleChanged(newState: state);
  }

  void dispose() {
    // Force flush to ensure data is sent
    sdk.OTel.tracerProvider().forceFlush();
  }
}
