// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutterrific_opentelemetry/src/trace/ui_span.dart';
import 'package:opentelemetry_api/opentelemetry_api.dart' as api;
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart' as sdk;

import '../flutterrific_otel.dart';

part 'ui_tracer_create.dart';

/// The main responsibility of the UITrace is to maintain span for and semantics
class UITracer implements sdk.Tracer {
  final sdk.TracerProvider _provider;
  final sdk.Tracer _delegate;
  final sdk.Sampler? _sampler;

  @override
  sdk.Sampler? get sampler => _sampler ?? _provider.sampler;

  UITracer._({
    required sdk.TracerProvider provider,
    required sdk.Tracer delegate,
    sdk.Sampler? sampler,
  }) : _provider = provider,
       _delegate = delegate,
       _sampler = sampler;

  @override
  String get name => _delegate.name;

  @override
  String? get schemaUrl => _delegate.schemaUrl;

  @override
  String? get version => _delegate.version;

  @override
  set enabled(bool enabled) => _delegate.enabled = enabled;

  @override
  api.Attributes? get attributes => _delegate.attributes;

  @override
  set attributes(api.Attributes? attributes) =>
      _delegate.attributes = attributes;

  @override
  bool get enabled => _delegate.enabled;

  @override
  get provider => _provider;

  @override
  sdk.Resource? get resource => _provider.resource;

  @override
  /// Create a UISpan that must be manually managed (ended)
  UISpan createSpan({
    required String name,
    UISpanType? uiSpanType,
    required api.SpanContext spanContext,
    api.APISpan? parentSpan,
    api.SpanKind kind = api.SpanKind.client,
    api.Attributes? attributes,
    List<api.SpanLink>? links,
    List<api.SpanEvent>? spanEvents,
    DateTime? startTime,
    bool? isRecording = true,
  }) {
    if (kDebugMode) {
      print('Tracer: Creating span with name: $name, kind: $kind');
    }

    sdk.Span delegateSpan = _delegate.createSpan(
      name: name,
      spanContext: spanContext,
      parentSpan: parentSpan,
      kind: kind,
      attributes: attributes,
      links: links,
      startTime: startTime,
      spanEvents: spanEvents,
      isRecording: isRecording,
    );

    return UISpanCreate.create(
      delegateSpan: delegateSpan,
      uiSpanType: uiSpanType,
    );
  }

  @override
  /// Start a span now with the given parent span (null for root)
  UISpan startSpan(
    String name, {
    UISpanType? uiSpanType,
    api.Context? context,
    api.SpanContext? spanContext,
    api.APISpan? parentSpan,
    api.SpanKind kind = api.SpanKind.client,
    api.Attributes? attributes,
    List<api.SpanLink>? links,
    bool? isRecording = true,
  }) {
    sdk.Span delegateSpan = _delegate.startSpan(
      name,
      context: context,
      spanContext: spanContext,
      parentSpan: parentSpan,
      kind: kind,
      attributes: attributes,
      links: links,
      isRecording: isRecording,
    );

    return UISpanCreate.create(
      delegateSpan: delegateSpan,
      uiSpanType: uiSpanType,
    );
  }

  /// Starts and ends a span that represents a navigation change
  void recordNavChange(String newRouteName, String newRoutePath, String newRouteKey, String newRouteArguments, Uint8List newRouteId, DateTime newRouteStartTime, String? previousRouteName, String? previousRoutePath, Uint8List? previousRouteId, sdk.NavigationAction newRouteChangeType, Duration? routeDuration) {
    UISpan span = FlutterOTel.tracer.startNavigationChangeSpan(
      newRouteName: newRouteName,
      newRoutePath: newRoutePath,
      newRouteKey: newRouteKey,
      newRouteArguments: newRouteArguments,
      newRouteId: newRouteId,
      newRouteStartTime: newRouteStartTime,
      previousRouteName: previousRouteName,
      previousRoutePath: previousRoutePath,
      previousRouteId: previousRouteId,
      routeChangeType: newRouteChangeType,
      routeDuration: routeDuration,
    );
    span.end();
    FlutterOTel.forceFlush();
  }

  /// Starts a span that describes a route change
  /// It's up to the caller to end the span
  UISpan startNavigationChangeSpan({
    required String newRouteName,
    required String newRoutePath,
    required String newRouteKey,
    required String newRouteArguments,
    required Uint8List newRouteId,
    required DateTime newRouteStartTime,
    required String? previousRouteName,
    required String? previousRoutePath,
    required Uint8List? previousRouteId,
    required api.NavigationAction routeChangeType,
    required Duration? routeDuration,
  }) {
    // TODO
    // if (!enabled) {
    //   return Span.empty();
    // }

    var attrMap = <String, Object>{
      api.NavigationSemantics.routeName.key: newRouteName,
      api.NavigationSemantics.routePath.key: newRoutePath,
      api.NavigationSemantics.routeKey.key: newRouteKey,
      api.NavigationSemantics.routeArguments.key: newRouteArguments,
      api.NavigationSemantics.routeId.key: newRouteId,
      api.NavigationSemantics.routeTimestamp.key: newRouteStartTime,
      api.NavigationSemantics.navigationAction.key: routeChangeType.toString(),
    };
    if (previousRouteName != null) {
      attrMap[api.NavigationSemantics.previousRouteName.key] = previousRouteName;
    }
    if (previousRoutePath != null) {
      attrMap[api.NavigationSemantics.previousRoutePath.key] = previousRoutePath;
    }
    if (previousRouteId != null) {
      attrMap[api.NavigationSemantics.previousRouteId.key] = previousRouteId;
    }
    if (routeDuration != null) {
      attrMap[api.NavigationSemantics.previousRouteDuration.key] = routeDuration;
    }
    final span = startSpan(
      api.NavigationSemantics.navigationAction.key,
      uiSpanType: UISpanType.navigation,
      attributes: attrMap.toAttributes(),
    );
    return span;
  }

  /// Creates and immediately ends a span for a user interaction
  void recordUserInteraction(
    String screenName,
    api.OTelSemantic interactionType, {
    String? targetName,
    Duration? responseTime,
    Attributes? attributes,
  }) {
    if (!enabled) {
      return;
    }

    final spanName = 'interaction.$screenName.$interactionType';
    var interactionAttributes = <String, Object>{
            api.NavigationSemantics.routeName.key: screenName,
            api.InteractionSemantics.interactionType.key: interactionType.key,
            if (targetName != null)
              api.InteractionSemantics.interactionTarget.key: targetName,
            if (responseTime != null)
              api.InteractionSemantics.inputDelay.key:
                  responseTime.inMilliseconds,
          }.toAttributes();
    if (attributes != null) {
      interactionAttributes =
          interactionAttributes.copyWithAttributes(attributes);
    }
    final span = _delegate.startSpan(
      spanName,
      kind: api.SpanKind.client,
      attributes:
          interactionAttributes,
    );

    if (responseTime != null) {
      // Set the end time based on the response time
      span.end(endTime: span.startTime.add(responseTime));
    } else {
      span.end();
    }
  }

  /// Records an error within the current context
  void recordError(
    String context,
    dynamic error,
    StackTrace? stackTrace, {
    Map<String, dynamic>? attributes,
  }) {
    if (!enabled) {
      return;
    }

    final span = _delegate.startSpan(
      'error.$context',
      kind: api.SpanKind.client,
      attributes:
          <String, Object>{
            'error.context': context,
            api.ErrorSemantics.errorType.key: error.runtimeType.toString(),
            api.ErrorSemantics.errorMessage.key: error.toString(),
            ...?attributes,
          }.toAttributes(),
    );

    span.recordException(error, stackTrace: stackTrace, escaped: true);

    span.setStatus(api.SpanStatusCode.Error, error.toString());
    span.end();
  }

  /// Records a performance metric
  void recordPerformanceMetric(
    String name,
    Duration duration, {
    Map<String, dynamic>? attributes,
  }) {
    if (!enabled) {
      return;
    }

    final span = _delegate.startSpan(
      'perf.$name',
      kind: api.SpanKind.client,
      attributes:
          <String, Object>{
            'perf.metric.name': name,
            api.PerformanceSemantics.renderDuration.key:
                duration.inMilliseconds,
            ...?attributes,
          }.toAttributes(),
    );

    span.end(endTime: span.startTime.add(duration));
  }

  /// Creates and ends a span that records the change in lifecycle.  These are
  /// automatically on [FlutterOTel.initialize] to create the rootSpan.
  /// By default is called by [FlutterOTel]'s AppLifecycleObserver if the
  /// app resumes after a configurable timeout.
  /// This should be ended quickly
  UISpan startAppLifecycleSpan({
    required api.AppLifecycleStates? newState,
    required Uint8List newStateId,
    required DateTime startTime,
    required api.AppLifecycleStates? previousState,
    required Uint8List? previousStateId,
    required Duration? previousStateDuration,
  }) {
    var appId = FlutterOTel.appName; // Need to get from app info
    var attributeMap = <String, Object>{
      api.AppInfoSemantics.appId.key: appId,
      api.AppInfoSemantics.appName.key: FlutterOTel.appName,
      api.AppLifecycleSemantics.appLifecycleState.key: newState ?? 'start',
      api.AppLifecycleSemantics.appLifecycleStateId.key: newStateId,
      api.AppLifecycleSemantics.appLifecycleTimestamp.key: startTime,
    };
    if (previousState != null) {
      attributeMap[api.AppLifecycleSemantics.appLifecyclePreviousState.key] =
          previousState;
    }
    if (previousStateId != null) {
      attributeMap[api.AppLifecycleSemantics.appLifecyclePreviousStateId.key] =
          previousStateId;
    }
    if (previousStateDuration != null) {
      attributeMap[api.AppLifecycleSemantics.appLifecycleDuration.key] =
          previousStateDuration;
    }

    return startSpan(
      api.AppLifecycleSemantics.appLifecycleChange.key,
      uiSpanType: UISpanType.appLifecycle,
      attributes: attributeMap.toAttributes(),
    );
  }

}
