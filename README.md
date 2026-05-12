# Flutterrific OpenTelemetry SDK for Flutter

[![pub.dev](https://img.shields.io/pub/v/flutterrific_opentelemetry.svg)](https://pub.dev/packages/flutterrific_opentelemetry)
[![Coverage](https://img.shields.io/badge/coverage-19%25-red.svg)](https://mindfulsoftwarellc.github.io/flutterrific_opentelemetry/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

> **Coverage candor:** the badge above is the real line-coverage number, not a vanity placeholder. Flutterrific's auto-instrumentation (lifecycle observers, paint/shift trackers, gesture observers) needs an actual Flutter binding running to exercise, which makes traditional unit tests structurally hard. The roadmap to `>=85%` for the stable cut lives in [ROADMAP.md](ROADMAP.md). Run `tool/coverage.sh` locally and `tool/update_coverage_badge.sh` to refresh.

Flutterrific OTel is an OpenTelemetry SDK for Flutter applications built on the [Dartastic OpenTelemetry SDK](https://pub.dev/packages/dartastic_opentelemetry), providing comprehensive observability for Flutter applications across all platforms.

## Demo

The [Wondrous OpenTelemetry](https://github.com/MindfulSoftwareLLC/flutter-wonderous-app-opentelemetry) project instruments the Wondrous App for observability with Flutterrific OTel.
The `main.dart` and `router.dart` show how to set up your app with Flutterrific OpenTelemetry.

## Overview

Flutterrific OpenTelemetry implements the [OpenTelemetry](https://opentelemetry.io/) specification for Flutter, enabling developers to collect **traces**, **metrics**, and **logs** from Flutter applications. OpenTelemetry is a vendor-neutral standard for observability and is the second most active [Cloud Native Computing Foundation (CNCF)](https://www.cncf.io/) project, after Kubernetes.

The CNCF OpenTelemetry Client Group is currently working on the specification for how OTel works on client apps. Flutterrific follows the client spec as it matures and proposes Flutter-specific semantic conventions for areas not yet covered.

## Why OpenTelemetry for Flutter?

- **Report Errors**: Get notified of errors in real time with structured context
- **App Lifecycle**: Track when users launch, pause, resume, and quit
- **Watch Your Users**: Understand navigation flows and improve conversion rates
- **Get Metrics**: Measure route load times, frame rates, and APDEX scores in production
- **Structured Logs**: Emit OTel Events for lifecycle, navigation, errors, and custom telemetry
- **Future-Proof**: OpenTelemetry is an industry standard with broad ecosystem support
- **Vendor Neutral**: Works with any OpenTelemetry-compatible backend (Grafana, Elastic, Datadog, etc.)
- **Cross-Platform**: Supports all Flutter platforms (Android, iOS, Web, Desktop)
- **Performance**: Designed for minimal overhead in production applications

## Features

### Three OTel Signals

Flutterrific supports all three OpenTelemetry signals:

| Signal  | Description | Auto-Instrumented |
|---------|-------------|-------------------|
| **Traces** | Distributed traces with spans for navigation, lifecycle, interactions, errors, and performance | Yes |
| **Metrics** | Counters, histograms, and gauges for frame times, navigation durations, APDEX, errors | Yes |
| **Logs** | Structured OTel Events for lifecycle changes, navigation, errors, and custom events | Yes |

### Auto-Instrumentation

On `FlutterOTel.initialize()`, the SDK automatically instruments:

- **App Lifecycle** — Traces and log events for `resumed`, `paused`, `inactive`, `hidden`, `detached` transitions
- **Navigation** — Traces and log events for route pushes, pops, replaces, and removes (GoRouter and Navigator)
- **Errors** — Traces, metrics, and log events for Flutter errors reported via `FlutterOTel.reportError()`
- **Performance Metrics** — Frame times, page load times, navigation durations, APDEX scores
- **User Interactions** — Taps, scrolls, drags, long presses, form submissions, menu selections

Each auto-instrumented event produces an **independent, short-lived trace** (not chained into a single long trace), a **metric data point**, and (when enabled) a **structured OTel log event**.

### Architecture

Flutterrific follows a wrapper/decorator pattern at each layer:

```
FlutterOTel (static entry point)
  ├── UITracerProvider → wraps SDK TracerProvider
  │     └── UITracer → wraps SDK Tracer, adds Flutter-specific span methods
  ├── UIMeterProvider → wraps SDK MeterProvider
  │     └── UIMeter → wraps SDK Meter
  ├── UILoggerProvider → wraps SDK LoggerProvider
  │     └── UILogger → wraps SDK Logger, adds Flutter-specific log methods
  ├── OTelLifecycleObserver → WidgetsBindingObserver for lifecycle
  ├── OTelNavigatorObserver → NavigatorObserver for routing
  └── OTelInteractionTracker → User interaction tracking
```

All constructors are hidden. You create objects through static methods on `FlutterOTel` (or `OTel` from Dartastic for lower-level SDK access).

## Quick Start

### 1. Add Dependency

```yaml
dependencies:
  flutterrific_opentelemetry: ^0.5.0
```

### 2. Initialize

```dart
import 'package:flutter/material.dart';
import 'package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterOTel.reportError(
      'FlutterError.onError', details.exception, details.stack);
  };

  // Initialize OpenTelemetry — all three signals enabled by default
  await FlutterOTel.initialize(
    serviceName: 'my-flutter-app',
    serviceVersion: '1.0.0',
    // endpoint defaults to localhost:4317 (gRPC) or 4318 (HTTP on web)
  );

  runApp(MyApp());
}
```

### 3. Add the Route Observer

For GoRouter:

```dart
final router = GoRouter(
  observers: [FlutterOTel.routeObserver],
  routes: [ /* ... */ ],
);
```

For standard Navigator:

```dart
MaterialApp(
  navigatorObservers: [FlutterOTel.routeObserver],
  // ...
);
```

That's it. With these three steps, your app automatically emits traces, metrics, and log events for all lifecycle changes, navigation, and errors.

## Signals In Depth

### Traces

Every auto-instrumented event creates a **short, independent span** with its own trace ID. This avoids the problem of a single long-running trace spanning the entire app session.

```dart
// Access the tracer for custom spans.
final tracer = FlutterOTel.tracer;

// Build attributes via `OTel.attributesFromSemanticMap` — the typed-enum
// shorthand that drops the `.key` suffix on every entry. Mix
// namespaces freely; everything implements `OTelSemantic`.
final span = tracer.startSpan(
  'fetch_user_data',
  kind: SpanKind.client,
  attributes: OTel.attributesFromSemanticMap({
    User.id: userId,
    Http.requestMethod: 'GET',
    Url.urlPath: '/users/$userId',
  }),
);

// `withSpanAsync` activates `span` for the duration of the closure
// using Zone-based context propagation — any nested instrumentation
// inside `apiClient.getUser(...)` that reads `Context.current.span`
// will see this span as its parent, including across `await`.
try {
  final result = await tracer.withSpanAsync(span, () async {
    final r = await apiClient.getUser(userId);
    span
      ..setIntAttribute(Http.responseStatusCode.key, 200)
      ..setStatus(SpanStatusCode.Ok);
    return r;
  });
  return result;
} catch (e, stackTrace) {
  span
    ..recordException(e, stackTrace: stackTrace)
    ..setStatus(SpanStatusCode.Error, e.toString());
  rethrow;
} finally {
  span.end();
}
```

For purely synchronous spans, use `tracer.withSpan(span, () { ... })` — same activation semantics without the `async`.

The UITracer provides convenience methods:

| Method | Description |
|--------|-------------|
| `startSpan(name, context: ..., kind: ..., attributes: ...)` | Start a span (caller is responsible for ending it; pass an explicit `Context` if you need to anchor the span to a specific parent) |
| `withSpan` / `withSpanAsync` | Activate a started span across a closure so nested code sees it as `Context.current.span` |
| `startActiveSpan` / `startActiveSpanAsync` | Convenience — starts + activates + ends the span around a closure (the `fn` receives the span as its argument) |
| `recordNavChange()` | Record a navigation change (starts and ends span) |
| `recordUserInteraction()` | Record a user interaction (starts and ends span) |
| `recordError()` | Record an error with stack trace |
| `recordPerformanceMetric()` | Record a performance measurement |
| `startNavigationChangeSpan()` | Start a navigation span (caller ends it) |
| `startAppLifecycleSpan()` | Start a lifecycle span (caller ends it) |

### Metrics

Metrics are automatically collected via `OTelMetricsBridge`:

| Metric | Type | Description |
|--------|------|-------------|
| `flutter.frame.duration` | Histogram | Frame rendering times (ms) |
| `flutter.page.load_time` | Histogram | Page load times (ms) |
| `flutter.navigation.duration` | Histogram | Navigation transition times (ms) |
| `flutter.errors.count` | Counter | Error count |
| `flutter.interaction.response_time` | Histogram | User interaction response times (ms) |
| `flutter.paint.duration` | Histogram | Paint operation durations (ms) |
| `flutter.layout.shift_score` | Histogram | Layout shift scores |
| `flutter.apdex.score` | Gauge | APDEX performance index |

You can also record custom metrics:

```dart
// Using FlutterOTelMetrics
FlutterOTelMetrics.recordMetric(
  name: 'my_custom_metric',
  value: 42,
  unit: 'ms',
  metricType: 'histogram',
);

// Or directly with a Meter
final meter = FlutterOTel.meter(name: 'my-feature');
meter.createCounter(name: 'feature.usage', unit: '{count}')
  .addWithMap(1, {'feature.name': 'dark_mode'});
```

### Logs (OTel Events)

The Log Signal emits structured OTel Events — log records with an `EventName` field that identifies the event type. This follows the emerging OTel client instrumentation standard.

#### UILogger

`UILogger` wraps the SDK `Logger` with Flutter-specific convenience methods:

```dart
final logger = FlutterOTel.logger('my-feature');

// Standard log levels
logger.info('Feature loaded');
logger.warn('Cache miss');
logger.error('Failed to fetch data');

// Structured OTel Events. Use the in-development OTel client event
// names (`app.screen.click`, `app.widget.click`, `device.app.lifecycle`)
// for keys that have one; fall back to your own namespace for events
// the spec hasn't covered yet. See the "Client OpenTelemetry" section
// below for the comparison table.
logger.emitEvent(
  'app.widget.click',
  body: 'Button tapped',
  attributes: {'app.widget.id': 'submit'}.toAttributes(),
);

// Flutter error logging
FlutterError.onError = (details) {
  logger.emitFlutterError(details);
};

// Lifecycle events (auto-emitted when enableAutoLogEvents is true)
logger.emitLifecycleEvent('resumed', previousState: 'paused');

// Navigation events (auto-emitted when enableAutoLogEvents is true)
logger.emitNavigationEvent('/details', fromRoute: '/home', action: 'push');
```

#### Auto Log Events

When `enableAutoLogEvents` is `true` (the default), Flutterrific automatically emits structured log events for:

| Event Name | Trigger | Key Attributes | Spec Status |
|------------|---------|----------------|-------------|
| `device.app.lifecycle` | App lifecycle state change | `app_lifecycle.state`, `app_lifecycle.previous_state`, `app_lifecycle.duration` | Event name spec'd ([mobile-events](https://opentelemetry.io/docs/specs/semconv/mobile/mobile-events/)); attribute keys are Flutterrific extensions until OTel stabilizes them |
| `browser.navigation` | Route change | `navigation.route.name`, `navigation.previous_route_name`, `navigation.action` | Flutterrific-specific — not yet covered by OTel client semconv |
| `device.app.error` | `FlutterOTel.reportError()` | `error.type`, `error.message`, `exception.stacktrace` | `error.*` and `exception.stacktrace` are spec'd; the event name itself is a Flutterrific extension |

Set `enableAutoLogEvents: false` in `initialize()` to disable automatic log events while keeping manual logger access. See the **[Client OpenTelemetry](#client-opentelemetry)** section below for the full spec-comparison and migration outlook as the OTel client semantic conventions stabilize.

## Semantic Conventions

Flutterrific uses strongly-typed semantic enums for all attribute keys, following OTel conventions.

### From the OTel Spec (via Dartastic API)

These enums come from the standard OTel semantic conventions. As of `dartastic_opentelemetry_api` 1.0.0-beta.6, ~60 attribute-key enums dropped the `Resource` suffix to match the spec's registry names (so `HttpResource` → `Http`, `UrlResource` → `Url`, etc.). Six kept the suffix to avoid Dart/Flutter/library type collisions: `ErrorResource`, `ExceptionResource`, `FileResource`, `ProcessResource`, `ServerResource`, `EventResource`.

- `Http`, `Url`, `Network`, `Server`*Resource*, `Client` — for outbound HTTP requests instrumented in your app.
- `Session` — `session.id`, `session.previous_id` (OTel-spec session keys).
- `User` — `user.id`, `user.email`, `user.full_name`, `user.name`, `user.roles`, `user.session`.
- `AppLifecycleSemantics` — `app_lifecycle.state`, `app_lifecycle.duration`, `app.launch.id`, etc. (Flutterrific-specific naming; see Client OpenTelemetry section).
- `NavigationSemantics` — `navigation.route.name`, `navigation.action`, etc. (Flutterrific-specific.)
- `ErrorSemantics` — `error.type`, `error.message` (some keys spec'd, some Flutterrific extensions).
- `InteractionSemantics` — `interaction.type`, `interaction.target`, etc. (Flutterrific-specific RUM-style; spec equivalents are `app.screen.click` / `app.widget.click` events).
- `PerformanceSemantics` — `render.duration`, `frame.rate`, `first.paint`, etc. (Flutterrific-specific; spec direction is `browser.web_vital` event for web targets).
- `RumSessionView` — `view.name`, `view.start`, `view.duration`, `session_id`, etc. The Datadog/Dynatrace-style RUM keys, deliberately separate from `Session` so spec-aligned and RUM-style data stay cleanly distinguished.

### Flutter-Specific Proposals

These enums live in `FlutterSemantics` and cover areas the OTel client conventions don't yet describe. We track upstream stabilization in the **Client OpenTelemetry** section below and migrate as keys become spec'd.

- `FlutterErrorSemantics` — `error.context`, `error.widget`, `error.widget_context`, `error.location`
- `FlutterPerformanceSemantics` — `perf.metric.name`, `perf.duration_ms`
- `FlutterUISemantics` — `ui.type`
- `FlutterScrollSemantics` — `scroll.position`
- `FlutterRedirectSemantics` — `redirect.to`
- `FlutterLifecycleMetricSemantics` — `lifecycle.state` (metric context)
- `FlutterRouteMetricSemantics` — `route.name`, `route.action`, `navigation.from_route`, `navigation.to_route`
- `FlutterEventNames` — `device.app.lifecycle`, `device.app.error`, `browser.navigation`

## Client OpenTelemetry

### Spec status, as of the cut date of this release

Client-side OpenTelemetry — the slice of the spec covering browser /
mobile / desktop client apps — is still under active development.
Every relevant doc in the
[OTel semantic-conventions repo](https://github.com/open-telemetry/semantic-conventions)
is marked `Status: Development` and the keys can still change. The big
moving pieces:

1. **Events API as the foundation for client telemetry.**
   [OTEP 0265 (Event Vision)](https://github.com/open-telemetry/opentelemetry-specification/blob/main/oteps/0265-event-vision.md)
   and the follow-up
   [OTEP 4430 (Span Event API deprecation)](https://github.com/open-telemetry/opentelemetry-specification/blob/main/oteps/4430-span-event-api-deprecation-plan.md)
   establish that **structured events live on the Logs API**, not as
   Span Events. A client event is a `LogRecord` with a non-empty
   `eventName`, structured attributes describing the event, and an
   optional body (string-only, for display). Span `AddEvent` and
   `RecordException` are being deprecated in favor of the Logs API.

   **What Flutterrific does today:** auto-instrumentation emits log
   events via `UILogger.emit(..., eventName: ...)` for lifecycle,
   navigation, and errors. ✓ Already spec-aligned.

2. **Mobile lifecycle event — `device.app.lifecycle`.**
   [`mobile-events`](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/mobile/mobile-events.md)
   specifies one event today with Android (`android.app.state`) /
   iOS (`ios.app.state`) state values. Flutter's `AppLifecycleState`
   doesn't map cleanly to either platform's terminology — Flutter has
   `resumed` / `inactive` / `hidden` / `paused` / `detached`, which
   straddles iOS and Android conventions.

   **What Flutterrific does today:** emits a `device.app.lifecycle`
   event with Flutter-native state values (`app_lifecycle.state`
   carries `resumed` / `paused` / etc., not `android.app.state` /
   `ios.app.state`). Pragmatic compromise — the event name matches
   the spec, the attribute schema doesn't yet because there isn't a
   Flutter-shaped spec convention. Will migrate once OTel adopts a
   cross-platform state vocabulary (tracked in semconv issue
   [#1654](https://github.com/open-telemetry/semantic-conventions/issues/1654)
   if you want to follow along).

3. **App events — `app.screen.click`, `app.widget.click`, `app.jank`.**
   [`docs/app/app-events.md`](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/app/app-events.md)
   covers click events with `app.screen.coordinate.x/y`,
   `app.screen.id`, `app.screen.name`, `app.widget.id`,
   `app.widget.name` attributes, and a `app.jank` event for frame
   drops.

   **What Flutterrific does today:** the `InteractionSemantics` enum
   carries RUM-style keys (`interaction.type`, `interaction.target`,
   `interaction.result`, `input.delay`) — predates the OTel spec by
   ~18 months. Migrating individual click/tap/long-press paths to
   `app.widget.click` / `app.screen.click` (with the spec's
   coordinate / id / name attributes) is on the 0.6 roadmap.
   `app.jank` aligns with what `flutter_metric_reporter`'s shift /
   paint trackers measure today — same migration window.

4. **Browser events — `browser.web_vital`.**
   [`browser-events`](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/browser/browser-events.md)
   spec'd the four core Google Web Vitals (CLS / FID / INP / LCP) as
   a single event with `name` / `value` / `delta` / `id` body fields.

   **What Flutterrific does today:** the `PerformanceSemantics` enum
   has `firstPaint`, `firstContentfulPaint`, `timeToInteractive`,
   `frameTime`, `jankCount`, `rumFirstInputDelay`, etc. — covers
   what's measurable on Flutter web, but with RUM-style flat keys
   rather than spec'd event bodies. Migration depends on the web
   target stabilizing in Flutter (Wasm and CanvasKit have different
   instrumentation surfaces).

5. **Browser / user-agent attributes.**
   `user_agent.original` (top-level OTel attribute registry) replaced
   the deprecated `browser.user_agent`. Dartastic's
   `WebResourceDetector` already emits the new key as of
   `dartastic_opentelemetry_api` 1.0.0-beta.6.

### Recommended pattern for your app

For each kind of client signal, pick the spec-aligned approach where
one exists, and use Flutterrific's RUM-style enums otherwise:

| Signal | Spec direction | Use today |
|--------|----------------|-----------|
| App lifecycle | `device.app.lifecycle` event via Logs API | `FlutterOTel.logger().emitLifecycleEvent(...)` — Flutterrific does this automatically when `enableAutoLogEvents: true`. |
| Errors / exceptions | `LogRecord` with `exception.*` attributes via Logs API; `Span.recordException` deprecated in favor of this | `FlutterOTel.reportError(...)` (auto-routes to both span event and log) or `logger.emitFlutterError(details)` |
| Navigation | No OTel client spec yet | `FlutterOTel.routeObserver` + Flutterrific's `NavigationSemantics`. Migrate when spec lands. |
| Clicks / taps | `app.widget.click` / `app.screen.click` events (spec, `Development`) | `withOTelButtonTracking('button_id')` extension. Migrate to spec event names in 0.6. |
| Frame jank | `app.jank` event (spec, `Development`) | `flutter_metric_reporter`'s shift / paint trackers. |
| Web vitals | `browser.web_vital` event (spec, `Development`) | `PerformanceSemantics` keys. |
| User identity | `User.id` / `User.roles` / `User.session` (stable in OTel registry) | ✓ Use directly. See "Common Attributes". |
| Session | `Session.id` / `Session.previous_id` (stable in OTel registry); `RumSessionView.*` for view-level metrics not in spec | ✓ Use both as needed. |

We track every spec-comparison decision in [ROADMAP.md](ROADMAP.md);
file an issue if a key matters for your backend and we haven't moved
on it.

## Configuration

### Initialize Options

```dart
await FlutterOTel.initialize(
  // Required
  serviceName: 'my-app',

  // Optional — all have sensible defaults
  appName: 'My App',                    // defaults to serviceName
  serviceVersion: '1.0.0',
  endpoint: 'https://collector:4317',   // defaults to localhost:4317

  // Traces
  spanProcessor: null,                  // auto-creates BatchSpanProcessor
  sampler: AlwaysOnSampler(),
  flushTracesInterval: Duration(seconds: 30),

  // Metrics
  enableMetrics: true,
  metricExporter: null,                 // auto-creates platform-specific exporter
  metricReader: null,                   // auto-creates PeriodicExportingMetricReader

  // Logs
  enableLogs: true,
  logRecordExporter: null,              // auto-creates platform-specific exporter
  logRecordProcessor: null,
  logPrint: false,                      // bridge Dart print() to OTel logs
  enableAutoLogEvents: true,            // auto-emit lifecycle/nav/error events

  // Resources
  resourceAttributes: null,
  detectPlatformResources: true,
  commonAttributesFunction: null,       // called on every span creation

  // Security
  secure: true,
  dartasticApiKey: null,
  tenantId: null,
);
```

### Platform-Specific Exporters

Flutterrific automatically selects the right protocol:

| Platform | Traces | Metrics | Logs |
|----------|--------|---------|------|
| Android, iOS, Desktop | OTLP/gRPC | OTLP/gRPC | OTLP/gRPC |
| Web | OTLP/HTTP | OTLP/HTTP | OTLP/HTTP |

Web browsers cannot use gRPC due to browser limitations, so Flutterrific automatically switches to HTTP for web builds.

### Common Attributes

Use `commonAttributesFunction` to add attributes to every span (e.g., user ID, session info):

```dart
await FlutterOTel.initialize(
  serviceName: 'my-app',
  commonAttributesFunction: () => OTel.attributesFromSemanticMap({
    User.id: currentUser.id,
    User.roles: currentUser.roles,         // list-of-string per spec
    Session.id: sessionManager.currentSessionId,
  }),
);
```

### Environment Variables

Standard OpenTelemetry environment variables are supported via `--dart-define`:

```bash
flutter run \
  --dart-define=OTEL_SERVICE_NAME=my-flutter-app \
  --dart-define=OTEL_SERVICE_VERSION=1.0.0 \
  --dart-define=OTEL_EXPORTER_OTLP_ENDPOINT=https://collector:4317 \
  --dart-define=OTEL_EXPORTER_OTLP_PROTOCOL=grpc \
  --dart-define=OTEL_EXPORTER_OTLP_HEADERS=api-key=your-api-key
```

| Variable | Description | Default |
|----------|-------------|---------|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Collector endpoint | `http://localhost:4317` |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | Protocol (`grpc` or `http/protobuf`) | `grpc` |
| `OTEL_EXPORTER_OTLP_HEADERS` | Additional headers | None |
| `OTEL_SERVICE_NAME` | Service name | None |
| `OTEL_SERVICE_VERSION` | Service version | None |
| `OTEL_LOG_LEVEL` | SDK internal log level | `INFO` |
| `OTEL_CONSOLE_EXPORTER` | Add console exporter for debugging | `false` |

Signal-specific variables (`OTEL_EXPORTER_OTLP_TRACES_*`, `OTEL_EXPORTER_OTLP_METRICS_*`) are also supported and take precedence.

## Developer's Guide

### Widget-Level Tracking

```dart
// Track button interactions
ElevatedButton(
  onPressed: handleSubmit,
  child: Text('Submit'),
).withOTelButtonTracking('submit_form');

// Error boundaries
RiskyWidget().withOTelErrorBoundary('risky_operation');

// Track interactions via the interaction tracker
FlutterOTel.interactionTracker.trackButtonClick(context, 'submit_btn');
FlutterOTel.interactionTracker.trackScroll(context, 'feed_list', scrollPosition);
FlutterOTel.interactionTracker.trackSwipeGesture(context, 'card', 'left');
```

### Manual Screen Spans

```dart
// Start a screen span (creates a new trace)
final span = FlutterOTel().startScreenSpan('checkout');

// ... user interacts with screen ...

// End when leaving
FlutterOTel().endScreenSpan('checkout');
```

### Error Reporting

```dart
// Report errors from any zone
FlutterOTel.reportError('network_error', error, stackTrace,
  attributes: {'endpoint': '/api/users'},
);

// In Flutter error handler
FlutterError.onError = (details) {
  FlutterOTel.reportError(
    'FlutterError', details.exception, details.stack);
};

// For async errors
PlatformDispatcher.instance.onError = (error, stack) {
  FlutterOTel.reportError('PlatformError', error, stack);
  return true;
};
```

### Custom OTel Events

```dart
final logger = FlutterOTel.logger('checkout');

// Emit a structured event. Event names in your own namespace are fine
// when the OTel client semconv doesn't already specify one.
logger.emitEvent('checkout.completed',
  body: 'Order placed successfully',
  attributes: {
    'order.id': orderId,
    'order.total': total,
    'payment.method': 'credit_card',
  }.toAttributes(),
);
```

### Testing

For widget tests, use `SimpleSpanProcessor` with `ConsoleExporter` to avoid gRPC timer conflicts with `FakeAsync`:

```dart
import 'package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart';

Future<void> initializeForTest() async {
  await FlutterOTel.initialize(
    endpoint: 'http://localhost:4317',
    serviceName: 'test-service',
    spanProcessor: SimpleSpanProcessor(ConsoleExporter()),
    enableMetrics: false,
    enableLogs: false,
    flushTracesInterval: null,   // No periodic timer in tests
    detectPlatformResources: false,
  );
}

// In tests:
setUp(() async {
  await FlutterOTel.reset();
  await initializeForTest();
});

tearDown(() async {
  await FlutterOTel.reset();
});
```

### Local Development

Run an OpenTelemetry collector locally:

```bash
# Grafana LGTM stack (Loki, Grafana, Tempo, Mimir) — all-in-one
docker run -p 3000:3000 -p 4317:4317 -p 4318:4318 --rm -ti grafana/otel-lgtm
```

Then open Grafana at `http://localhost:3000` to see traces, metrics, and logs.

### Flushing Data

```dart
// Force flush all pending data (traces, metrics, logs)
FlutterOTel.forceFlush();
```

By default, traces are flushed every 30 seconds. Set `flushTracesInterval` to change this, or `null` to disable periodic flushing.

### Cleanup

```dart
// Clean up on app shutdown
FlutterOTel().dispose();
```

## Platform Support

| Platform | Support Level | Protocol  | Notes                                    |
|----------|---------------|-----------|------------------------------------------|
| Android  | Full          | OTLP/gRPC | Complete feature support                 |
| iOS      | Full          | OTLP/gRPC | Complete feature support                 |
| Web      | Full          | OTLP/HTTP | Auto-switches due to browser limitations |
| Windows  | Beta          | OTLP/gRPC | Desktop support                          |
| macOS    | Beta          | OTLP/gRPC | Desktop support                          |
| Linux    | Beta          | OTLP/gRPC | Desktop support                          |

## Examples

- [Basic Integration Example](example/)
- [Wonderous OpenTelemetry](https://github.com/MindfulSoftwareLLC/flutter-wonderous-app-opentelemetry) - Complete app example based on Wonderous

## Compatibility

- **Flutter**: 3.7.0+
- **Dart**: 3.7.0+
- **OpenTelemetry Specification**: 1.56+ (the version `dartastic_opentelemetry` 1.1.0-beta.4 targets)
- **OpenTelemetry Semantic Conventions**: 1.41+ (typed enums regenerated against the beta.6 API)
- **Client OpenTelemetry**: tracks the in-development client semconv — see the [Client OpenTelemetry](#client-opentelemetry) section for the per-signal alignment status.
- **Platforms**: Android, iOS, Web, Windows, macOS, Linux

## Contributing

We are looking for contributors and maintainers! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
git clone https://github.com/MindfulSoftwareLLC/flutterrific_opentelemetry.git
cd flutterrific_opentelemetry
flutter pub get
flutter analyze
flutter test
```

### Coverage

```bash
tool/coverage.sh             # writes coverage/lcov.info + coverage/html
tool/update_coverage_badge.sh  # rewrites the README badge in place
```

### Releasing

This repo follows the Flutter / Dart team's `-wip` convention. See [PUBLICATION_CHECKLIST.md](PUBLICATION_CHECKLIST.md). The short version:

```bash
dart run tool/release.dart
```

The script strips `-wip` from `pubspec.yaml`, dates the CHANGELOG section, runs `flutter analyze` + `flutter test`, tags `vX.Y.Z`, bumps to the next `-wip`, then `dart pub publish`es from the tagged tree.

## Governance

This project follows the [CNCF Code of Conduct](https://github.com/cncf/foundation/blob/main/code-of-conduct.md) and maintains [open governance](GOVERNANCE.md). We welcome community participation and contributions.

## Security

Security vulnerabilities should be reported privately to the maintainers. See our [Security Policy](SECURITY.md) for details.

## Roadmap

See our [Roadmap](ROADMAP.md) for planned features and improvements.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Community

- [GitHub Issues](https://github.com/MindfulSoftwareLLC/flutterrific_opentelemetry/issues) - Bug reports and feature requests
- [OpenTelemetry Community](https://opentelemetry.io/community/) - Broader OpenTelemetry community

## Acknowledgments

Built on the foundation of:
- [Dartastic OpenTelemetry SDK](https://pub.dev/packages/dartastic_opentelemetry)
- [Dartastic OpenTelemetry API](https://pub.dev/packages/dartastic_opentelemetry_api)
- [OpenTelemetry Specification](https://opentelemetry.io/docs/specs/otel/)
- [Flutter Framework](https://flutter.dev/)

Maintained by [Michael Bushe](https://github.com/michaelbushe) and [Mindful Software LLC](https://mindfulsoftware.com).

---

*This project aims to be contributed to the [OpenTelemetry](https://opentelemetry.io/) organization under the [Cloud Native Computing Foundation](https://www.cncf.io/).*
