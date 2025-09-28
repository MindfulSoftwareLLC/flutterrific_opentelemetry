// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import '../flutterrific_otel.dart';

part 'ui_meter_create.dart';

/// UIMeter extends the standard Meter to provide UI-specific functionality
/// for Flutter applications.
class UIMeter implements Meter {
  /// The underlying delegate Meter
  final APIMeter _delegate;

  /// Creates a new UIMeter instance.
  UIMeter._(this._delegate);

  // Forward all required properties and methods to the delegate
  @override
  String get name => _delegate.name;

  @override
  String? get version => _delegate.version;

  @override
  String? get schemaUrl => _delegate.schemaUrl;

  // The provider property isn't directly accessible in APIMeter,
  // so we provide a reasonable implementation
  @override
  MeterProvider get provider => FlutterOTel.meterProvider;

  @override
  bool get enabled => _delegate.enabled;

  @override
  Attributes get attributes => _delegate.attributes ?? OTel.attributes();

  @override
  Counter<T> createCounter<T extends num>({
    required String name,
    String? description,
    String? unit,
  }) {
    return _delegate.createCounter<T>(
          name: name,
          description: description,
          unit: unit,
        )
        as Counter<T>;
  }

  @override
  Histogram<T> createHistogram<T extends num>({
    required String name,
    String? description,
    String? unit,
    List<double>? boundaries,
  }) {
    return _delegate.createHistogram<T>(
          name: name,
          description: description,
          unit: unit,
          boundaries: boundaries,
        )
        as Histogram<T>;
  }

  @override
  UpDownCounter<T> createUpDownCounter<T extends num>({
    required String name,
    String? description,
    String? unit,
  }) {
    return _delegate.createUpDownCounter<T>(
          name: name,
          description: description,
          unit: unit,
        )
        as UpDownCounter<T>;
  }

  @override
  Gauge<T> createGauge<T extends num>({
    required String name,
    String? description,
    String? unit,
  }) {
    return _delegate.createGauge(
          name: name,
          description: description,
          unit: unit,
        )
        as Gauge<T>;
  }

  @override
  ObservableCounter<T> createObservableCounter<T extends num>({
    required String name,
    String? description,
    String? unit,
    ObservableCallback<T>? callback,
  }) {
    return _delegate.createObservableCounter<T>(
          name: name,
          description: description,
          unit: unit,
          callback: callback,
        )
        as ObservableCounter<T>;
  }

  @override
  ObservableGauge<T> createObservableGauge<T extends num>({
    required String name,
    String? description,
    String? unit,
    ObservableCallback<T>? callback,
  }) {
    return _delegate.createObservableGauge<T>(
          name: name,
          description: description,
          unit: unit,
          callback: callback,
        )
        as ObservableGauge<T>;
  }

  @override
  ObservableUpDownCounter<T> createObservableUpDownCounter<T extends num>({
    required String name,
    String? description,
    String? unit,
    ObservableCallback<T>? callback,
  }) {
    return _delegate.createObservableUpDownCounter<T>(
          name: name,
          description: description,
          unit: unit,
          callback: callback,
        )
        as ObservableUpDownCounter<T>;
  }

  /// Records a UI observation with the given value and attributes.
  /// This is a UI-specific extension method that can be used to track
  /// various UI metrics that don't fit neatly into the standard instrument types.
  void recordObservation(num value, Attributes attributes) {
    // We'll use a histogram for general observations since it provides
    // the most complete picture of the data
    createHistogram<double>(
      name: 'ui.observation',
      description: 'General UI observation',
      unit: '{value}',
    ).record(value.toDouble(), attributes);
  }

  /// Creates a screen-specific counter for tracking UI events.
  Counter<T> createScreenCounter<T extends num>({
    required String name,
    required String screen,
    String? description,
    String? unit,
  }) {
    final counter = createCounter<T>(
      name: 'screen.$screen.$name',
      description: description ?? 'Counter for $name on screen $screen',
      unit: unit,
    );

    // Add the screen attribute automatically to all measurements
    return _ScreenBoundCounter<T>(counter, screen);
  }

  /// Creates a screen-specific histogram for tracking UI timing metrics.
  Histogram<T> createScreenHistogram<T extends num>({
    required String name,
    required String screen,
    String? description,
    String? unit,
  }) {
    final histogram = createHistogram<T>(
      name: 'screen.$screen.$name',
      description: description ?? 'Histogram for $name on screen $screen',
      unit: unit ?? 'ms',
    );

    // Add the screen attribute automatically to all measurements
    return _ScreenBoundHistogram<T>(histogram, screen);
  }

  /// Creates a page load timer
  Histogram<double> createPageLoadTimer({
    required String pageName,
    String? description,
  }) {
    return createHistogram<double>(
      name: 'page.load_time',
      description: description ?? 'Load time for page $pageName',
      unit: 'ms',
    );
  }

  /// Creates a frame duration histogram
  Histogram<double> createFrameDurationHistogram({String? description}) {
    return createHistogram<double>(
      name: 'frame.duration',
      description: description ?? 'Frame render duration',
      unit: 'ms',
    );
  }
}

/// A Counter that automatically adds a screen attribute to all measurements.
class _ScreenBoundCounter<T extends num> implements Counter<T> {
  final Counter<T> _delegate;
  final String _screen;

  _ScreenBoundCounter(this._delegate, this._screen);

  @override
  void add(T value, [Attributes? attributes]) {
    // Add the screen attribute to the provided attributes
    final screenAttributes =
        attributes == null
            ? <String, Object>{'screen': _screen}.toAttributes()
            : attributes.copyWithStringAttribute('screen', _screen);

    _delegate.add(value, screenAttributes);
  }

  // Forward all other methods and properties to the delegate
  @override
  void addWithMap(T value, Map<String, Object> attributes) {
    final mapWithScreen = Map<String, Object>.from(attributes);
    mapWithScreen['screen'] = _screen;
    _delegate.addWithMap(value, mapWithScreen);
  }

  @override
  T getValue([Attributes? attributes]) {
    return _delegate.getValue(attributes);
  }

  @override
  void reset() {
    _delegate.reset();
  }

  @override
  List<MetricPoint<T>> collectPoints() {
    return _delegate.collectPoints();
  }

  @override
  String get name => _delegate.name;

  @override
  String? get description => _delegate.description;

  @override
  String? get unit => _delegate.unit;

  @override
  APIMeter get meter => _delegate.meter;

  @override
  bool get enabled => _delegate.enabled;

  // Implement type-checking properties
  @override
  bool get isCounter => true;

  @override
  bool get isGauge => false;

  @override
  bool get isHistogram => false;

  @override
  bool get isUpDownCounter => false;

  @override
  List<Metric> collectMetrics() {
    // Forward to the delegate if it supports collecting metrics
    return _delegate.collectMetrics();
  }
}

/// A Histogram that automatically adds a screen attribute to all measurements.
class _ScreenBoundHistogram<T extends num>
    implements Histogram<T>, SDKInstrument {
  final Histogram<T> _delegate;
  final String _screen;

  _ScreenBoundHistogram(this._delegate, this._screen);

  @override
  void record(T value, [Attributes? attributes]) {
    // Add the screen attribute to the provided attributes
    final screenAttributes =
        attributes == null
            ? <String, Object>{'screen': _screen}.toAttributes()
            : attributes.copyWithStringAttribute('screen', _screen);

    _delegate.record(value, screenAttributes);
  }

  // Forward all other methods and properties to the delegate
  @override
  void recordWithMap(T value, Map<String, Object> attributes) {
    final mapWithScreen = Map<String, Object>.from(attributes);
    mapWithScreen['screen'] = _screen;
    _delegate.recordWithMap(value, mapWithScreen);
  }

  @override
  List<MetricPoint<HistogramValue>> collectPoints() {
    return _delegate.collectPoints();
  }

  @override
  void reset() {
    _delegate.reset();
  }

  @override
  List<double>? get boundaries => _delegate.boundaries;

  @override
  String get name => _delegate.name;

  @override
  String? get description => _delegate.description;

  @override
  String? get unit => _delegate.unit;

  @override
  APIMeter get meter => _delegate.meter;

  @override
  bool get enabled => _delegate.enabled;

  // Implement type-checking properties
  @override
  bool get isCounter => false;

  @override
  bool get isGauge => false;

  @override
  bool get isHistogram => true;

  @override
  bool get isUpDownCounter => false;

  @override
  List<Metric> collectMetrics() {
    // Forward to the delegate if it supports collecting metrics
    return _delegate.collectMetrics();
  }

  @override
  HistogramValue getValue([Attributes? attributes]) =>
      _delegate.getValue(attributes);
}
