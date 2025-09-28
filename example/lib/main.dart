// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart';

void main() {
  /// This is a minimal demo, for a full demo see
  /// wondrous_opentelemetry
  String appName = 'flutterrific_example_app';
  FlutterOTel.initialize(
    //the 'service' for Flutter is the client
    serviceName: appName,
    // the deafult tracer is the app-ui
    // You can use OTel to create other tracers for different
    // parts of the app, for repositories or services, etc.
    // or use one tracer for the whole app.
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
      // Add OpenTelemetry with just one line!
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
    // You can manually track interactions
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

    // Example of manually creating a span for a specific operation
    final tracer = FlutterOTel.tracer;
    final span = tracer.startSpan(
      'fetch_data',
      kind: SpanKind.client,
      attributes:
          <String, Object>{
            'operation.type': 'network_request',
            'endpoint': '/api/data',
          }.toAttributes(),
    );

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Add event to the span
      span.addEventNow(
        'data_received',
        {'bytes_received': 1024, 'response_code': 200}.toAttributes(),
      );

      // End span successfully
      span.end();
    } catch (e, stackTrace) {
      // Record error in span
      span.recordException(e, stackTrace: stackTrace);
      span.setStatus(SpanStatusCode.Error, e.toString());
      span.end(); // End span with error
    } finally {
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
        // Wrap with error boundary to catch rendering errors
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            // Using widget extension to track user interaction
            ElevatedButton(
              onPressed: _isLoading ? null : _simulateNetworkRequest,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Simulate Network Request'),
            ).withOTelButtonTracking('network_request_button'),
            const SizedBox(height: 20),
            // Using widget extension to track text input
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
