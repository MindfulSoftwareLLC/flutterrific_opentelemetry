# Flutterrific OpenTelemetry

An OpenTelemetry SDK for Flutter applications.

## Why OpenTelemetry?

OpenTelemetry (OTel) is the second most active Cloud Native Computing Foundation (CNCF) project, after Kubernetes. Why?
The future-proof OTel observability standard breaks proprietary locks and enables standard-based observability
interoperability.  OpenTelemetry libraries are available for dozens of languages and platforms, and now,
for Dart and Flutter.  The industry's movement from proprietary observability to the OTel standard is happening rapidly.

## Why Flutterrific OTel?

Flutterrific OTel applies the [Dartastic OpenTelemetry SDK](https://pub.dev/packages/dartastic_opentelemetry) 
to add powerful observability to Flutter apps with ease. 

## Features

- 🚀 **Simple API**: Integrate OpenTelemetry with a few lines of code. 
- 👣 **Automatic Tracing**: Navigation and app lifecycle tracing, right out of the box. Trace calls from frontend to 
backends tied together, providing problem solving superpowers.
- 📊 **Performance Tracking**: Performance metrics including web vitals and apdex scores automatically.
- 🧩 **Widget Extensions**: Easy-to-use extensions to produce metrics for widgets.
- 🐞 **Error Tracking**: Global error handler and reporting, Automatic error boundary for Widgets.
- 🪵 **Useful Flutter Logs**: See logs from your productionn apps.
- 📐 **Standards Compliant**: Complies with the [OpenTelemetry specification](https://opentelemetry.io/docs/specs/) so it's portable and future-proof.
Works with any OpenTelemetry backend. Open Source and built for pluggability and extendability.
- 🌎 **Ecosystem**:
  - [Dartastic.io](https://dartastic.io) is an OTel backend tuned for Dart and Flutter with a generous free tier,
    professional support and enterprise features.
- 💪🏻 **Powerful**:
  - Easily get traces and timings for every route. Watch how long users spend on every screen.
  - Capture any user interaction - watch clicks, swipes and taps in real time.  
  - Propagate OpenTelemetry Context across async gaps, Isolates and backend calls.
  - Pick from a rich set of Samplers including On/Off, probability and rate-limiting.
  - Automatically capture platform resources on initialization. See which devices perform best or have trouble.
- 🧷 **Typesafe Semantics**: Ensure you're speaking the right language with a massive set of enums matching
  the evolving [OpenTelemetry Semantics Conventions](https://opentelemetry.io/docs/specs/semconv/).  Avoid naming bugs inside loose strings.
- 📊 **Excellent Performance**: Uses gRCP by default for efficient throughput. The performance test suite proves it
  meets benchmarks for speed with low overhead.
- 🐞 **Well Tested**: Good test coverage. Used in production apps at very large enterprises.
- 📃 **Quality Documentation**: If it's not clearly documented, it's a bug. Extensive examples and best practices are
  provided. [Wonderous Dartastic](https://pub.dev/packages/wonderous_dartastic) demonstrates the Wonderous App instrumented with OpenTelemetry.

Flutterrific is built upon the [dartastic_opentelemetry](https://pub.dev/packages/dartastic_opentelemetry), the Dart SDK for OpenTelemetry.

Do you need an OpenTelemetry backend?
[Dartastic.io](https://dartastic.io) offers an observability backend with a generous free tier based on
the OTel standard with professional support and enterprise features.  Get useful stacktraces from production apps.

Dartastic and Flutterrific are brought to you by Michael Bushe and [Mindful Software](https://mindfulsoftware.com).

## Getting Started

### 1. Add dependency

```yaml
dependencies:
  flutterrific_opentelemetry: ^1.0.0
```

### 2. Initialize OpenTelemetry in your app

The simplest robust setup that catches errors and auto-traces the app lifecycle and navigation is as follows.  
See "Correlating Auto-Tracing" below for a more robust version.  Also see [Wonderous Dartastic](https://pub.dev/packages/wonderous_dartastic) for a 
complete example.

```dart
import 'package:flutter/material.dart';
import 'package:flutterrific_opentelemetry/flutterrific_otel.dart';

void main() {
  // Catch errors from the Flutter framework.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterOTel.reportError('FlutterError.onError', details.exception, details.stack);
    // Optionally, you can also print the error to the console:
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  // Catch asynchronous errors.
  runZonedGuarded(() {
    FlutterOTel.initialize(
      serviceName: 'my-wonderful-app',
      serviceVersion: '2.0',
      //configures the default trace, consider making other tracers for isolates, etc.
      tracerName: 'ui',
      //OTel standard tenant_id, required for Dartastic.io
      tenantId: 'valued-customer-id',
      //required for the Dartastic.io backend
      dartasticAPIKey: '123456',
      resourceAttributes: {
        // Always consult the OTel Semantic Conventions to find an existing
        // convention name for an attribute.  Semantics are evolving.
        // https://opentelemetry.io/docs/specs/semconv/
        //--dart-define environment=dev
        //See https://opentelemetry.io/docs/specs/semconv/resource/deployment-environment/
        '${DeploymentNames.deploymentEnvironmentName}': String.fromEnvironment('environment'),
        //--dart-define pod-name=powerful-dart-pod
        //See https://opentelemetry.io/docs/specs/semconv/resource/#kubernetes
        '${DeploymentNames.k8sPodName}': String.fromEnvironment('pod-name'),
      }
    );
    runApp(MyApp());
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('$error');
      debugPrintStack(stackTrace: stack, label: 'Flutter app runZoneGuarded');
    }
    FlutterOTel.reportError('Error caught in run', error, stack,
            attributes: {
              'error.source': 'zone_error',
              'error.type': error.runtimeType.toString(),
    });
  });
}

/// When using GoRouter, wrap your _handleRedirect with an OTelGoRouterRedirect
final appRouter = GoRouter(
redirect:  OTelGoRouterRedirect(_handleRedirect).callRedirect,
  routes: [/* routes */]
);
```

That's it! Your app now automatically traces:
- Route transitions
- App lifecycle events (foreground/background)
- App startup performance

## How Auto-Tracing Works

### Auto-Tracing Basics

The root of OpenTelemetry is the `Trace` that holds a tree of `Span`s. A `trace` has a `traceId` this is shared amongst 
all `Span`s in the `Trace`.  Each `Span` has its own `spanId` and a `parentSpanId`.  The first span in a trace is the 
root `Span` and has no `parentSpan` (its parentSpanId is null). All other `Span`s have the `parentSpanId`s of their 
parents, forming a tree of Spans.  

All autotracing occurs in the global default `TracerProvider` and it's default tracer, retrieved from 
`FlutterOTel.tracer`.

### Auto-Traces are Brief

Traces in OTel are not intended to be long-lasting. An anti-pattern is a session trace that lasts for hours or even
weeks and has many child spans. Another is a page span that has child spans for subroutes. The problem with such 
patterns is that spans must `end` and have their parents `end` to get properly ingested by backend observability tools.
Large, multi-hour traces with dozens (or hundreds) of child spans also become unwieldy in APM tools.

Client developers have concerns that server developers don't have worry about - a mobile app can be closed without 
warning with a flick or suspended into the background for week and come back. This is particularly concerning at the 
most important moments.  The user is most likely going to close the app when the app is slow to load, has errors or 
when the user is choosing not to click "Subscribe".  To deal with these pesky users, top-level spans should be created 
frequently and ended immediately.  Keep these issues in mind if you manually manage your own spans.

FlutterOTel starts and ends short-lived spans quickly and `forceFlush()`s the spans to the backend so traces are not
lost when the user closes the app.  This avoids dealing with the cross-platform app lifecycle vagaries.

Instead of long-lasting parent-child relationships, spans are correlated by common attributes, like the traceId, the
deviceId or the userId.

### Correlating Auto-Tracing 

When the app is launched and `FlutterOTel.initialize()` is called, an `app_launch_id` uuid (v4) is created. The 
`app_launch_id` is sent with all spans created with default `UITracer` as an Attribute equal to 
`AppLifecycleSemantics.appLaunchId.key`  to allow tools to correlate all auto-traces from the app's launch until the 
app is closed.  To correlate traces created manually, include 
`{AppLifecycleSemantics.appLaunchId.key : FlutterOTel.appLaunchId}` in span attributes.

To correlate traces for a device across launches, it is recommended to use `device_info_plus` to pass Resource 
Attributes to `FlutterOTel.initialize()`.  To correlate across versions, use `package_info_plus`.  In order to maximize
compatibility, `flutterrific_otel` does not ship with these dependencies.

To correlate across user attributes, use the `commonAttributesFunction` which will be executed to include attributes
on each span.  Unlike Resource attributes, common attribute values change over the course of a launch, for example,
when a user logs in.  Remember that OTel does not allow null Attribute values.

This example is from the `wondrous_otel` example:
```
  ///Flutterrific OTel initialization
  final deviceInfoPlugin = DeviceInfoPlugin();
  final deviceInfo = await deviceInfoPlugin.iosInfo;
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  
  await FlutterOTel.initialize(
      resourceAttributes: <String, Object>{
        '${EnvironmentResource.deploymentEnvironment}': 'dev',
        DeviceSemantics.deviceId.key : deviceInfo.identifierForVendor ?? 'no_id',
        DeviceSemantics.deviceModel.key : deviceInfo.model,
        DeviceSemantics.devicePlatform.key : deviceInfo.systemName,
        DeviceSemantics.deviceOsVersion.key : deviceInfo.systemVersion,
        DeviceSemantics.deviceModel.key : deviceInfo.isiOSAppOnMac,
        DeviceSemantics.isPhysicalDevice.key : deviceInfo.isPhysicalDevice,
        AppInfoSemantics.appName.key: packageInfo.appName,
        AppInfoSemantics.appPackageName.key: packageInfo.packageName,
        AppInfoSemantics.appVersion.key: packageInfo.version,
        AppInfoSemantics.appBuildNumber.key: packageInfo.buildNumber,
       }.toAttributes(), 
       commonAttributesFunction: () {
            final Map<String, Object> commonAttrs = {};
            if (auth.id != null) {
                commonAttrs[UserSemantics.userId.key] = auth.id;
            }
            if (auth.userRole != null) {
                commonAttrs[UserSemantics.userRole.key] = auth.userRole;
            }
            if (sessionManager.sessionId != null) {
                commonAttrs[UserSemantics.userSession.key] = sessionManager.sessionId;
            }
       }.toAttributes());
```

### Auto-generated Traces

#### Auto tracing errors

```
  // Catch errors from the Flutter framework.
  FlutterError.onError = (FlutterErrorDetails details) {
    // Report the error via your agent.
    FlutterOTel.reportError(details.exception, details.stack);
    // Optionally, you can also print the error to the console:
    // FlutterError.dumpErrorToConsole(details);
  };

  // Catch asynchronous errors.
  runZonedGuarded(() {
    runApp(MyApp());
  }, (error, stack) {
    FlutterOTel.reportError(error, stack);
  });
```

#### Auto tracing the app lifecycle

`FlutterOTel.initialize()` creates an `AppLifecycleObserver` that is added to 
`WidgetsBindingObserver.didChangeAppLifecycleState` to respond to app lifecycle events. 
It sets `FlutterOTel.currentAppLifecycleId` to a new id which is included as `app_lifecycle.id`
(`AppLifecycleSemantics.appLifecycleId`) in all auto-generated spans.

For each change in the app's lifecycle, a span is created and ended that has the current lifecycle state and start time, 
the previous app lifecycle state and duration. The first state is 'active' (not an actual Flutter AppLifecycleState).

For the App lifecycle states detached, inactive, hidden, paused (all except resume), navigation spans are also ended.
(see the next section for navigation spans).

All spans are then flushed to ensure, as best as possible, that all telemetry is sent to the server.

#### Auto tracing navigation

Similar to app lifecycle, Flutterific OTel's NavigatorObserver creates short-lived`Span`s as the user navigates the app. 
For each callback in NavigatorObserver a new navigation span is created for the change. Each spans has information for
the new and previous routes.  The exact semantics are defined in the API's NavigationSemantics.
- NavigationAction routeChangeType (push, pop...)
- New route
  - routeId - similar to a spanId, generated for the new route during the  change
  - name
  - path
  - key
  - arguments
  - startTime
- Previous route 
  - The same information as above, gathered when it was the new route. 
  - routeDuration

#### Auto tracing user interactions


### 3. Add custom tracing

Within these automatic Traces and Spans you can use the
FlutterOTel's [UITracer]'s [startSpan] to start child or
root spans - the tracer will figure out which by assigning a parent
span if it exist or created a new span if there is no root span.  
For more advanced maneuver's you can manually [UITracer]'s [createSpan]  
to create a new span but you  must manage parent and child relationships
manually, and end previous Spans, if appropriate.

For more detailed tracing, you can access the tracer directly:

```dart
import 'package:flutterrific_opentelemetry/flutterrific_otel.dart';

void fetchData() async {
  final tracer = FlutterrificOTel().tracer;
  
  // Start a span
  final span = tracer.startSpan(
    'fetch_user_data',
    attributes: {
      'source': 'api',
      'user_id': '123',
    },
  );
  
  try {
    // Your code here
    await api.fetchUserData();
    span.end(); // End span successfully
  } catch (e, stackTrace) {
    // Record error in span
    span.recordException(e, stackTrace: stackTrace);
    span.setStatus(SpanStatusCode.Error, e.toString());
    span.end(); // End span with error status
    rethrow;
  }
}
```

## Advanced Features

### Track User Interactions

```dart
// For individual widgets
ElevatedButton(
  onPressed: () {
    // The interaction will be tracked automatically
  },
  child: Text('Submit'),
).withOTelButtonTracking('submit_button');

// For form fields
TextField(
  decoration: InputDecoration(labelText: 'Email'),
).withOTelTextFieldTracking('email_field');

// Or manually track interactions
void onTap() {
  FlutterrificOTel().interactionTracker.trackButtonClick(
    context, 
    'custom_button',
  );
}
```

### Error Boundary

Wrap widgets with error boundary to automatically capture render errors:

```dart
MyComplexWidget().withOTelErrorBoundary('profile_screen');
```

## Semantic Conventions

The SDK follows OpenTelemetry semantic conventions for RUM (Real User Monitoring) with attributes like:

- `ui.screen.name` - The name of the current screen/route
- `ui.interaction.type` - The type of interaction (click, scroll, etc.)
- `app.lifecycle.timestamp` - Timestamp for lifecycle events
- `navigation.type` - Type of navigation (push, pop, replace)

## Advanced Configuration

For advanced configuration, you can provide a custom tracer provider:

```dart
import 'package:opentelemetry_api/opentelemetry_api.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

void main() {
  // Configure exporter
  final otlpExporter = OtlpHttpExporter(
    endpoint: 'https://your-collector-endpoint:4318/v1/traces',
  );
  
  // Create SDK with configured exporter
  final sdk = OpenTelemetrySdk(
    tracerProvider: TracerProviderBuilder()
        .addSpanProcessor(BatchSpanProcessor(otlpExporter))
        .build(),
  );
  
  // Initialize Flutterrific with custom tracer provider
  FlutterrificOTel().initialize(
    appName: 'my_app',
    tracerProvider: sdk.tracerProvider,
  );
  
  runApp(MyApp());
}
```

## Examples

Check out the Wonderous OpenTelemetry example app for a complete implementation:
- [wonderous-dartastic](/Users/mbushe/dev/mf/otel/dartastic/wonderous-dartastic)

## Flutterific OTel Features
Flutterrific is very easy and very powerful.  

Flutterific OTel seamlessly integrates observability into Flutter apps:
- Instruments the router to track where your users go.
- Reports web vitals APDEX metrics so you can understand how startup and page performance is effecting user experience.
- Sends standard trace information with calls to your server for a unified client-through-servers view of every network
  operation.  Quickly prove to the team that Flutter is fast and the server team needs to work on that
  performance issue. 😎
- Capture metric for any Widgets, even with animations, to see how they perform in the field on real devices.
- Catches errors globally and connect them to the user's UI path.
- Golden signals for Software Reliability Engineering.

flutterific_opentelemetry is based on dartastic_opentelemetry and offers all the features of Dartastic, including
- Context propagation across Dart Zones and Isolates
- gRPC for fast and efficient data transfer, the OTel default
- Samplers, including rate-limiting samplers, to tune your o11y for cost and effectiveness.
- An OTel API and SDK that is fully compliant with the specification.
- Great DevEx with a discoverable, easy-to-user Dart-like API.
- An extensible and pluggable library.  Roll your own implementation or even small improvements.
- Very good documentation with samples and good OTel practices.
- An extensive automated test suite
- A performance test suite for proven reliable speed with low overhead.

## FAQ

1. Why can't I use the toAttributes extension on a Map?
This doesn't work because {} the map is not keyed by Strings and allows null (is dynamic):
```
attributes: {
        AppInfoSemantic.appName.key: 'my-cool-app',
      } // .toAttributes() isn't possible
```

Since Attributes cannot have null values per the OTel specification and since the Map is keyed
by String, add types to the Map:
```
attributes: <String, Object>{ //properly typed, no nulls allowed, per spec
        AppInfoSemantic.appName.key: 'my-cool-app',
      }.toAttributes()
```

## Additional information

- Flutter developers should use the [Flutterrific OTel SDK](https://pub.dev/packages/flutterrific_opentelemetry).
- Dart backend developers should use the [Dartastic OTel SDK](https://pub.dev/packages/dartastic_opentelemetry).
- Also see:
    - [The OpenTelemetry Specification](https://opentelemetry.io/docs/specs/otel/)
    - [Dartastic.io](https://dartastic.io/) the Flutter OTel backend
    - The [Wonderous OTel App](https://pub.dev/packages/wonderous_opentelemetry) is the example app for Flutterific.
      It's a fork of the Wonderous App, enhanced with Flutterrific OpenTelemetry.
