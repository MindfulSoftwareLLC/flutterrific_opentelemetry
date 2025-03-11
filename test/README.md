# Flutterrific OpenTelemetry Tests

This directory contains tests for the Flutterrific OpenTelemetry Flutter library, with a special focus on the app lifecycle and navigation observers.

## Tests Structure

The tests are organized into the following files:

### 1. `lifecycle_observer_test.dart`

Tests for the `OTelLifecycleObserver` which tracks app lifecycle events:
- Tests initialization behavior
- Tests state changes from Flutter's AppLifecycleState events
- Verifies observer correctly registers with WidgetsBinding
- Tests full sequence of lifecycle events

### 2. `navigation_observer_test.dart`

Tests for the `OTelNavigatorObserver` which tracks navigation events:
- Tests with GoRouter integration
- Tests with standard Navigator integration
- Verifies route transitions (push, pop, replace)
- Tests route parameters and path tracking

### 3. `otel_integration_test.dart`

Integration tests for the overall FlutterOTel system:
- Tests both lifecycle and navigation observers working together
- Tests custom span creation
- Tests background/foreground transitions
- Verifies app initialization and routing

### 4. `mock_tracer_test.dart`

Tests using mocked tracers/spans to verify correct behavior:
- Tests span creation on lifecycle changes
- Tests span creation on navigation events
- Tests integration of both observers

### 5. `mocks/mock_tracer.dart`

Contains mock implementations for testing:
- Mock UITracer implementation
- Mock span implementation
- Helps verify correct behavior without needing real OTel exporting

## Running the Tests

To run the tests:

```bash
flutter test
```

To run a specific test file:

```bash
flutter test test/lifecycle_observer_test.dart
```

## Test Dependencies

The tests use the following dependencies:
- flutter_test: For widget testing
- go_router: For testing route observation
- mockito: For creating test mocks

You'll need to run `flutter pub get` before running the tests to ensure all dependencies are available.

## Test Coverage

These tests focus on the following key areas:
1. Verifying that app lifecycle events are correctly observed and tracked
2. Verifying that navigation events are correctly observed and tracked
3. Ensuring the two systems work well together
4. Testing the behavior of the API in realistic Flutter applications

The tests don't verify the content of spans or the export functionality, as those are more appropriately tested in the underlying Dartastic OpenTelemetry implementation.
