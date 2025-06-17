// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'dart:ui';

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:meta/meta.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

part 'ui_span_create.dart';

enum UISpanType { appLifecycle, navigation, ui }

class UISpan implements Span {
  final Span _delegate;
  final UISpanType? _uiSpanType;
  final AppLifecycleState? _lifecycleState;

  UISpan._(Span delegate, {UISpanType? uiSpanType, AppLifecycleState? lifecycleState})
    : _delegate = delegate,
      _uiSpanType = uiSpanType,
    _lifecycleState = lifecycleState;

  /// If set, the type of span: Navigation, appLifecycle, etc.
  /// Spans created automatically by Flutterrific OTel have UISpanTypes
  /// but manual spans may not have a specific type
  UISpanType? get uiSpanType => _uiSpanType;

  /// Gets lifecycle state name from a UISpan with the UISpanType.appLifecycle
  AppLifecycleState? lifecycleState() => _lifecycleState;

  @override
  Resource? get resource => _delegate.resource;

  @override
  void end({DateTime? endTime, SpanStatusCode? spanStatus}) => _delegate.end();

  @override
  set attributes(Attributes newAttributes) =>
      _delegate.attributes = newAttributes;

  @override
  void addAttributes(Attributes attributes) =>
      _delegate.addAttributes(attributes);

  @override
  void addEvent(SpanEvent spanEvent, [Attributes? attributes]) => _delegate.addEvent(spanEvent);

  @override
  void addEventNow(String name, [Attributes? attributes]) =>
      _delegate.addEventNow(name, attributes);

  @override
  void addEvents(Map<String, Attributes?> spanEvents) =>
      _delegate.addEvents(spanEvents);

  @override
  void addLink(SpanContext spanContext, [Attributes? attributes]) =>
      _delegate.addLink(spanContext, attributes);

  @override
  void addSpanLink(SpanLink spanLink) => _delegate.addSpanLink(spanLink);

  @override
  DateTime? get endTime => _delegate.endTime;

  @override
  bool get isEnded => _delegate.isEnded;

  @override
  bool get isRecording => _delegate.isRecording;

  @override
  SpanKind get kind => _delegate.kind;

  @override
  String get name => _delegate.name;

  @override
  APISpan? get parentSpan => _delegate.parentSpan;

  @override
  void recordException(
    Object exception, {
    StackTrace? stackTrace,
    Attributes? attributes,
    bool? escaped,
  }) => _delegate.recordException(
    exception,
    stackTrace: stackTrace,
    attributes: attributes,
    escaped: escaped,
  );

  @override
  void setBoolAttribute(String name, bool value) =>
      _delegate.setBoolAttribute(name, value);

  @override
  void setBoolListAttribute(String name, List<bool> value) =>
      _delegate.setBoolListAttribute(name, value);

  @override
  void setDoubleAttribute(String name, double value) =>
      _delegate.setDoubleAttribute(name, value);

  @override
  void setDoubleListAttribute(String name, List<double> value) =>
      _delegate.setDoubleListAttribute(name, value);

  @override
  void setIntAttribute(String name, int value) =>
      _delegate.setIntAttribute(name, value);

  @override
  void setIntListAttribute(String name, List<int> value) =>
      _delegate.setIntListAttribute(name, value);

  @override
  void setStatus(SpanStatusCode statusCode, [String? description]) {
    _delegate.setStatus(statusCode, description);
  }

  @override
  void setStringAttribute<T>(String name, String value) =>
      _delegate.setStringAttribute(name, value);

  @override
  void setStringListAttribute<T>(String name, List<String> value) =>
      _delegate.setStringListAttribute(name, value);

  @override
  void setDateTimeAsStringAttribute(String name, DateTime value) =>
      _delegate.setDateTimeAsStringAttribute(name, value);

  @override
  SpanContext get spanContext => _delegate.spanContext;

  @override
  List<SpanEvent>? get spanEvents => _delegate.spanEvents;

  @override
  SpanId get spanId => _delegate.spanId;

  @override
  List<SpanLink>? get spanLinks => _delegate.spanLinks;

  @override
  DateTime get startTime => _delegate.startTime;

  @override
  SpanStatusCode get status => _delegate.status;

  @override
  String? get statusDescription => _delegate.statusDescription;

  @override
  void updateName(String name) => _delegate.updateName(name);

  @visibleForTesting
  @override
  // ignore: invalid_use_of_visible_for_testing_member
  Attributes get attributes => _delegate.attributes;

  @override
  InstrumentationScope get instrumentationScope =>
      _delegate.instrumentationScope;

  @override
  bool get isValid => _delegate.isValid;

  @override
  SpanContext? get parentSpanContext => _delegate.parentSpanContext;

  @override
  bool isInstanceOf(Type type) {
    return Type == this.runtimeType;
  }
}
