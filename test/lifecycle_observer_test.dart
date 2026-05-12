// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart';

import 'testing_utils/test_otel_helper.dart';

class MockLifecycleApp extends StatefulWidget {
  final Function(AppLifecycleState)? onStateChange;

  const MockLifecycleApp({super.key, this.onStateChange});

  @override
  State<MockLifecycleApp> createState() => _MockLifecycleAppState();
}

class _MockLifecycleAppState extends State<MockLifecycleApp>
    with WidgetsBindingObserver {
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _lastLifecycleState = state;
      if (widget.onStateChange != null) {
        widget.onStateChange!(state);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Current lifecycle state: ${_lastLifecycleState?.toString() ?? 'unknown'}',
          ),
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OTelLifecycleObserver Tests', () {
    late OTelLifecycleObserver lifecycleObserver;

    setUp(() async {
      await FlutterOTel.reset();
      await initializeFlutterOTelForTest(serviceName: 'ui-test-service');

      lifecycleObserver = OTelLifecycleObserver();
    });

    tearDown(() async {
      await FlutterOTel.reset();
    });

    testWidgets('Should create initial lifecycle state on instantiation', (
      tester,
    ) async {
      expect(
        lifecycleObserver.currentAppLifecycleState,
        equals(AppLifecycleStates.active),
      );
      expect(lifecycleObserver.currentAppLifecycleId, isNotNull);
      expect(lifecycleObserver.currentAppLifecycleStartTime, isNotNull);
    });

    testWidgets('Should update state when app lifecycle changes', (
      tester,
    ) async {
      // Save current state values
      final initialStateId = lifecycleObserver.currentAppLifecycleId;
      final initialState = lifecycleObserver.currentAppLifecycleState;

      // Mock lifecycle state change
      lifecycleObserver.didChangeAppLifecycleState(AppLifecycleState.paused);

      // Verify state has been updated
      expect(
        lifecycleObserver.currentAppLifecycleId,
        isNot(equals(initialStateId)),
      );
      expect(
        lifecycleObserver.currentAppLifecycleState,
        isNot(equals(initialState)),
      );
      expect(
        lifecycleObserver.currentAppLifecycleState?.name,
        equals(AppLifecycleState.paused.name),
      );
    });

    testWidgets('Should receive lifecycle events from Flutter binding', (
      tester,
    ) async {
      bool lifecycleCallbackTriggered = false;

      await tester.pumpWidget(
        MockLifecycleApp(
          onStateChange: (state) {
            lifecycleCallbackTriggered = true;
          },
        ),
      );

      // Trigger lifecycle event
      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(lifecycleCallbackTriggered, isTrue);
    });

    testWidgets('Should handle complete lifecycle event sequence', (
      tester,
    ) async {
      // Save current state
      // ignore: unused_local_variable
      final initialState = lifecycleObserver.currentAppLifecycleState;

      // Test sequence of lifecycle events
      final states = [
        AppLifecycleState.resumed,
        AppLifecycleState.inactive,
        AppLifecycleState.paused,
        AppLifecycleState.detached,
        AppLifecycleState.resumed,
      ];

      for (final state in states) {
        // Get current values before change
        final beforeId = lifecycleObserver.currentAppLifecycleId;

        // Trigger lifecycle change
        lifecycleObserver.didChangeAppLifecycleState(state);

        // Verify values changed
        expect(
          lifecycleObserver.currentAppLifecycleId,
          isNot(equals(beforeId)),
        );
        expect(
          lifecycleObserver.currentAppLifecycleState?.name,
          equals(state.name),
        );
      }

      // Final state should be resumed
      expect(
        lifecycleObserver.currentAppLifecycleState?.name,
        equals(AppLifecycleState.resumed.name),
      );
    });

    testWidgets('Should dispose properly', (tester) async {
      // Test the dispose method
      lifecycleObserver.dispose();
      // No explicit expectations, just verifying it doesn't throw
    });
  });
}
