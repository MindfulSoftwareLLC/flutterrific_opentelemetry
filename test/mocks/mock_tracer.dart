// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutterrific_opentelemetry/src/trace/ui_span.dart';
import 'package:flutterrific_opentelemetry/src/trace/ui_tracer.dart';
import 'package:mockito/mockito.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart' as sdk;

class MockSpan extends Mock implements UISpan {}

class MockUITracer extends Mock implements UITracer {
  bool _enabled = true;
  final sdk.TracerProvider _tracerProvider;
  final List<UISpan> _createdSpans = [];

  MockUITracer({required sdk.TracerProvider tracerProvider})
      : _tracerProvider = tracerProvider;

  @override
  UISpan startSpan(
    String name, {
    UISpanType? uiSpanType,
    Context? context,
    SpanContext? spanContext,
    APISpan? parentSpan,
    SpanKind kind = SpanKind.client,
    Attributes? attributes,
    List<SpanLink>? links,
    bool? isRecording = true,
  }) {
    final span = MockSpan();
    _createdSpans.add(span);
    return span;
  }

  @override
  UISpan startAppLifecycleSpan({
    required AppLifecycleStates? newState,
    required Uint8List newStateId,
    required DateTime startTime,
    required AppLifecycleStates? previousState,
    required Uint8List? previousStateId,
    required Duration? previousStateDuration,
  }) {
    final span = MockSpan();
    _createdSpans.add(span);
    return span;
  }

  @override
  bool get enabled => _enabled;

  @override
  set enabled(bool enabled) {
    _enabled = enabled;
  }

  @override
  sdk.TracerProvider get provider => _tracerProvider;

  List<UISpan> get createdSpans => _createdSpans;
}
