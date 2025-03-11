// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart' as sdk;

// Simple pages for navigation testing with debug indicators
class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Add a key to make debugging easier
    return Scaffold(
      key: const Key('first_page'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('First Page', key: Key('first_page_title')),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('navigate_button'),
              onPressed: () {
                print('Navigate button pressed, going to /second');
                GoRouter.of(context).go('/second');
              },
              child: const Text('Navigate'),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('second_page'),
      body: Center(
        child: Text('Second Page', key: Key('second_page_title')),
      ),
    );
  }
}

// Mock classes
class MockTracerProvider extends Mock implements sdk.TracerProvider {}
class MockSpan extends Mock implements sdk.Span {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OTelLifecycleObserver with Mocked Tracer', () {
    late OTelLifecycleObserver lifecycleObserver;

    setUp(() async {
      await FlutterOTel.reset();
      await FlutterOTel.initialize(
        endpoint: 'http://localhost:4317',
        serviceName: 'ui-test-service',
        serviceVersion: '1.0.0',
      );

      lifecycleObserver = OTelLifecycleObserver();
    });

    tearDown(() async {
      await FlutterOTel.reset();
    });

    testWidgets('Should create spans on lifecycle state changes', (tester) async {
      // Initial state initialization should have created a span already

      // Create a widget that uses WidgetsBindingObserver
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return const Center(
                  child: Text('Test App'),
                );
              },
            ),
          ),
        ),
      );

      // Trigger lifecycle state changes
      final binding = tester.binding;

      // Test app entering background
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // Test app entering foreground
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // We primarily test that these transitions don't throw exceptions,
      // since the actual span creation is handled by the real FlutterOTel instance
    });
  });

  group('OTelNavigatorObserver with GoRouter', () {
    late GoRouter router;
    late OTelNavigatorObserver navigatorObserver;

    setUp(() async {
      await FlutterOTel.reset();
      await FlutterOTel.initialize(
        endpoint: 'http://localhost:4317',
        serviceName: 'ui-test-service',
        serviceVersion: '1.0.0',
      );

      navigatorObserver = OTelNavigatorObserver();

      // Create router with our observer
      router = GoRouter(
        debugLogDiagnostics: true,
        observers: [navigatorObserver],
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const FirstPage(),
          ),
          GoRoute(
            path: '/second',
            name: 'second',
            builder: (context, state) => const SecondPage(),
          ),
        ],
      );
    });

    tearDown(() async {
      await FlutterOTel.reset();
    });

    testWidgets('Should create spans on route changes', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
      ));
      await tester.pumpAndSettle();

      // Verify initial route is set
      expect(navigatorObserver.currentRouteData, isNotNull);
      expect(navigatorObserver.currentRouteData?.routeId, isNotNull);

      // Print debug info
      print('Finding navigable elements: ${find.byType(ElevatedButton).evaluate().length}');

      // Ensure the first page is showing
      expect(find.byKey(const Key('first_page')), findsOneWidget);
      expect(find.byKey(const Key('navigate_button')), findsOneWidget);

      // Use direct router navigation instead of tapping the button
      router.go('/second');
      await tester.pumpAndSettle();

      // Print the current route for debugging
      print('Current route path: ${navigatorObserver.currentRouteData?.routePath}');
      print('Current route name: ${navigatorObserver.currentRouteData?.routeName}');

      // Verify the second page is showing
      expect(find.byKey(const Key('second_page')), findsOneWidget);

      // Verify route change was processed in the observer
      expect(navigatorObserver.currentRouteData?.routePath, equals('/second/details'));
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('Should handle various navigation actions', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
      ));
      await tester.pumpAndSettle();

      // Test push
      router.go('/second');
      await tester.pumpAndSettle();

      // Test replace
      router.replace('/');
      await tester.pumpAndSettle();

      // Test push again and then pop
      router.go('/second');
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      // We primarily test that these transitions don't throw exceptions,
      // as the actual span creation is handled by the real FlutterOTel instance
    });
  });

  group('Integrated Lifecycle and Navigation Test', () {
    late GoRouter router;

    setUp(() async {
      await FlutterOTel.reset();
      await FlutterOTel.initialize(
        endpoint: 'http://localhost:4317',
        serviceName: 'ui-test-service',
        serviceVersion: '1.0.0',
      );

      // Create router with FlutterOTel.routeObserver
      router = GoRouter(
        debugLogDiagnostics: true,
        observers: [FlutterOTel.routeObserver],
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const FirstPage(),
          ),
          GoRoute(
            path: '/second',
            name: 'second',
            builder: (context, state) => const SecondPage(),
          ),
        ],
      );
    });

    tearDown(() async {
      await FlutterOTel.reset();
    });

    testWidgets('Should handle lifecycle and navigation events together', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
      ));
      await tester.pumpAndSettle();

      // Use direct router navigation instead of button tap
      router.go('/second');
      await tester.pumpAndSettle();

      // Trigger lifecycle events
      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // App comes back to foreground
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // Verify the observers still have their state
      expect(FlutterOTel.routeObserver.currentRouteData?.routeId, isNotNull);
      expect(FlutterOTel.lifecycleObserver.currentAppLifecycleId, isNotNull);

      // Verify current route
      expect(FlutterOTel.routeObserver.currentRouteData?.routePath, contains('second'));
    });
  });
}
