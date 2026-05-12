// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart';

void main() {
  /// This is a minimal demo. For a full one, see `wondrous_opentelemetry`.
  ///
  /// Initialization sets up:
  /// - Service identity (`serviceName`, optional `tracerName`).
  /// - Auto-instrumentation for app lifecycle, navigation, and user
  ///   interactions (opt out per signal via `enableAutoLogEvents: false`
  ///   etc. on `FlutterOTel.initialize`).
  /// - Platform resource detection (OS, device, app metadata).
  /// - OTel `Resource` attributes that flow into every span and log.
  const appName = 'flutterrific_example_app';
  FlutterOTel.initialize(
    // The "service" for a Flutter client is the app itself.
    serviceName: appName,
    // Default tracer is `app-ui`. Add additional tracers via
    // `OTel.tracerProvider().getTracer('repositories')`, etc., when you
    // want to separate spans by component.
    tracerName: '$appName-ui',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterrificOTel Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'FlutterrificOTel Demo Home'),
      // For navigation tracing across screens, add
      // `navigatorObservers: [FlutterOTel.routeObserver]` here (or pass
      // the same observer to `GoRouter(observers: ...)`).
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool _isLoading = false;

  void _incrementCounter() {
    // Manual interaction tracking. The `withOTelButtonTracking`
    // extension (used on the network-request button below) is the
    // ergonomic way; this raw form is useful when you need to attach
    // extra context.
    FlutterOTel.interactionTracker.trackButtonClick(
      context,
      'increment_button',
    );

    setState(() {
      _counter++;
    });
  }

  Future<void> _simulateNetworkRequest() async {
    setState(() {
      _isLoading = true;
    });

    // Example of manually creating a client span for an HTTP-style
    // operation. Attributes use the OTel semantic-convention typed
    // enums via `attributesFromSemanticMap` — the shorthand that drops
    // the `.key` suffix on every entry. Mixing different semconv
    // namespaces in one map is fine; every semconv enum implements
    // `OTelSemantic`.
    //
    // The span is wrapped with `tracer.withSpanAsync` so it is
    // *active* across every `await` inside the closure — any nested
    // instrumentation that reads `Context.current.span` (e.g. another
    // library that auto-attaches HTTP child spans) will correctly
    // find this span as its parent. `withSpanAsync` uses Zone-based
    // context propagation, which is the Dart-idiomatic way to carry
    // a value across async boundaries.
    final tracer = FlutterOTel.tracer;
    final span = tracer.startSpan(
      'fetch_data',
      kind: SpanKind.client,
      attributes: OTel.attributesFromSemanticMap({
        Http.requestMethod: 'GET',
        Url.urlPath: '/api/data',
        Url.urlScheme: 'https',
      }),
    );

    try {
      await tracer.withSpanAsync(span, () async {
        // Simulate network delay. Any code inside this closure sees
        // `Context.current.span == span` — including across the
        // `await`.
        await Future.delayed(const Duration(seconds: 2));

        // Successful response — set status attributes + record an
        // event with the standard HTTP response keys.
        span
          ..setIntAttribute(Http.responseStatusCode.key, 200)
          ..setIntAttribute(Http.responseBodySize.key, 1024)
          ..addEventNow(
            'data_received',
            OTel.attributesFromSemanticMap({
              Http.responseStatusCode: 200,
              Http.responseBodySize: 1024,
            }),
          )
          ..setStatus(SpanStatusCode.Ok);
      });
    } catch (e, stackTrace) {
      // `withSpanAsync` rethrows after the closure finishes — record
      // the exception and set the error status here so the span
      // carries both before we end it.
      span
        ..recordException(e, stackTrace: stackTrace)
        ..setStatus(SpanStatusCode.Error, e.toString());
    } finally {
      // End the span exactly once, regardless of which branch ran.
      span.end();
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        // Wrap with error boundary to catch rendering errors as OTel
        // span events / log records on the surrounding tracer/logger.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            // Widget extension: emits an `interaction.*` span every
            // time the button fires, plus an auto-log event when
            // `enableAutoLogEvents: true` (the default).
            ElevatedButton(
              onPressed: _isLoading ? null : _simulateNetworkRequest,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Simulate Network Request'),
            ).withOTelButtonTracking('network_request_button'),
            const SizedBox(height: 20),
            // Text field tracking — fires on focus change + submit.
            TextField(
              decoration: const InputDecoration(
                labelText: 'Enter something',
                border: OutlineInputBorder(),
              ),
            ).withOTelTextFieldTracking('demo_text_field'),
          ],
        ).withOTelErrorBoundary('home_page'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
