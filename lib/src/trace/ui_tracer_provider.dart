// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutterrific_opentelemetry/src/trace/ui_tracer.dart';

part 'ui_tracer_provider_create.dart';

class UITracerProvider implements TracerProvider {
  final TracerProvider _delegate;
  final Map<String, Tracer> _tracers = {};

  UITracerProvider._({required TracerProvider delegate}) : _delegate = delegate;

  @override
  Tracer getTracer(
    String name, {
    String? version,
    String? schemaUrl,
    Attributes? attributes,
    Sampler? sampler,
  }) {
    if (isShutdown) {
      throw StateError('TracerProvider has been shut down');
    }

    final key = '$name:${version ?? ''}';
    return _tracers.putIfAbsent(
      key,
      () =>
          UITracerCreate.create(
                delegate: _delegate.getTracer(
                  name,
                  version: version,
                  schemaUrl: schemaUrl,
                  attributes: attributes,
                ),
                provider: this,
                sampler: sampler,
              )
              as Tracer,
    );
  }

  /// Add a span processor
  @override
  void addSpanProcessor(SpanProcessor processor) {
    _delegate.addSpanProcessor(processor);
  }

  /// Get all registered span processors
  @override
  List<SpanProcessor> get spanProcessors => _delegate.spanProcessors;

  @override
  String get endpoint => _delegate.endpoint;

  @override
  set endpoint(String value) {
    _delegate.endpoint = value;
  }

  @override
  String get serviceName => _delegate.serviceName;

  @override
  set serviceName(String value) {
    _delegate.serviceName = value;
  }

  @override
  String? get serviceVersion => _delegate.serviceVersion;

  @override
  set serviceVersion(String? value) {
    _delegate.serviceVersion = value;
  }

  @override
  bool get enabled => _delegate.enabled;

  @override
  set enabled(bool value) {
    _delegate.enabled = value;
  }

  @override
  Sampler? get sampler => _delegate.sampler;

  @override
  set sampler(Sampler? value) => _delegate.sampler = value;

  @override
  bool get isShutdown => _delegate.isShutdown;

  @override
  set isShutdown(bool value) {
    _delegate.isShutdown = value;
  }

  @override
  Future<bool> shutdown() async {
    return _delegate.shutdown();
  }

  /// Flushes all the span processors
  @override
  forceFlush() async {
    _delegate.forceFlush();
  }

  @override
  Resource? get resource => _delegate.resource;

  @override
  set resource(Resource? resource) => _delegate.resource = resource;

  @override
  void ensureResourceIsSet() {
    _delegate.ensureResourceIsSet();
  }
}
