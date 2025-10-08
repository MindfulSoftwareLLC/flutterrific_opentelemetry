// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'dart:async';

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart' as sdk;
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutterrific_opentelemetry/src/common/otel_lifecycle_observer.dart';
import 'package:flutterrific_opentelemetry/src/factory/otel_flutter_factory.dart';
import 'package:flutterrific_opentelemetry/src/metrics/otel_metrics_bridge.dart';
import 'package:flutterrific_opentelemetry/src/metrics/ui_meter.dart';
import 'package:flutterrific_opentelemetry/src/metrics/ui_meter_provider.dart';
import 'package:flutterrific_opentelemetry/src/nav/otel_navigator_observer.dart';
import 'package:flutterrific_opentelemetry/src/trace/interaction_tracker.dart';
import 'package:flutterrific_opentelemetry/src/trace/ui_tracer.dart';
import 'package:flutterrific_opentelemetry/src/trace/ui_tracer_provider.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:uuid/uuid.dart';

import 'metrics/metrics_service.dart';

typedef CommonAttributesFunction = Attributes Function();

/// Main entry point for Flutterrific OpenTelemetry SDK.
///
/// This class provides a simple API for adding OpenTelemetry tracing
/// to Flutter applications with minimal configuration.
///
/// FlutterOTel relies on OTel from dartastic_opentelemetry. For custom
/// OTel code such as making custom spans, tracers or spanProcessors, use
/// the [OTel] class from Dartastic.
/// can use the complete OTel SDK class from Dartastic.
class FlutterOTel {
  static const defaultServiceName = "@dart/flutterrific_opentelemetry";
  static const defaultServiceVersion = "0.1.0";
  static const dartasticEndpoint = "https://otel.dartastic.io";

  static OTelLifecycleObserver? _lifecycleObserver;

  /// Lifecycle observer for automatic app lifecycle tracing
  static OTelLifecycleObserver get lifecycleObserver {
    return _lifecycleObserver ??= OTelLifecycleObserver();
  }

  /// Interaction tracker for user interaction tracing
  static OTelInteractionTracker? _interactionTracker;

  /// Lifecycle observer for automatic app lifecycle tracing
  static OTelInteractionTracker get interactionTracker {
    return _interactionTracker ??= OTelInteractionTracker();
  }

  static final Map<String, sdk.Span> _activeSpans = <String, sdk.Span>{};

  // Defaults to the serviceName
  static String? _appName;

  /// A function to return attributes to include in all traces, called when
  /// spans are created but the UITracer.  This is a good place to include
  /// value that change over time (as opposed to resource attributes, which
  /// do not change) to correlate traces.  Consider adding values for
  /// UserSemantics userId, userRole and userSession.
  static CommonAttributesFunction? commonAttributesFunction;

  /// Created during initialize, this id is common throughout all traces until
  /// the app is closed.
  static String? appLaunchId;

  /// An id for the latest app lifecycle
  static Uint8List? currentAppLifecycleId;

  static OTelNavigatorObserver? _routeObserver;

  /// Add this to the observers in GoRouter or the NavigatorObserver in the
  /// MaterialApp if not using GoRouter
  static OTelNavigatorObserver get routeObserver {
    if (_routeObserver == null) {
      throw StateError('FlutterOTel.initialize() must be called first.');
    }
    return _routeObserver!;
  }

  /// Lifecycle observer for automatic app lifecycle tracing
  static String get appName {
    if (_appName == null) {
      throw StateError('FlutterOTel.initialize() must be called first.');
    }
    return _appName!;
  }

  /// Must be called before using any other FlutterOTel or OTel methods.
  /// Sets up the global default TracerProvider and it's tracers.
  /// Adds the lifecycleObserver to observer and trace app lifecycle events.
  /// [appName] defaults to serviceName.
  /// [endpoint] is a url, defaulting to http://localhost:4317, the default port
  /// for the default gRPC protocol on a localhost.
  /// [serviceName] SHOULD uniquely identify the instrumentation scope, such as
  /// the instrumentation library (e.g. @dart/opentelemetry_api),
  /// package, module or class name.
  /// [serviceVersion] defaults to the matching OTel spec version
  /// plus a release version of this library, currently  1.11.0.0
  /// [tracerName] the name of the default tracer for the global Tracer provider
  /// it defaults to 'dartastic' but should be set to something app-specific.
  /// [tracerVersion] the version of the default tracer for the global Tracer
  /// provider.  Defaults to null.
  /// [resourceAttributes] Resource attributes added to [TracerProvider]s.
  /// Resource attributes are set once and do not change during a process.
  /// The tenant_id and the resources from [detectPlatformResources] are merged
  /// with [resourceAttributes] with [resourceAttributes] taking priority.
  /// The values must be valid Attribute types (String, bool, int, double, or
  /// List\<String>, List\<bool>, List\<int> or List\<double>).
  /// [traceAttributesFunction]
  /// [usesGoRouter] whether the instrumented app uses GoRouter,
  /// defaults to true, makes GoRouter spans faster and more reliable.
  /// [dartasticApiKey] for Dartastic.io users, the dartastic.io ApiKey
  /// [tenantId] the standard tenantId, for Dartastic.io users this must match
  /// the tenantId for the dartasticApiKey.
  /// [spanProcessor] The SpanProcessor to add to the defaultTracerProvider.
  /// If null, the following batch span processor and OTLP gRPC exporter is
  /// created and added to the default TracerProvider
  /// ```
  //       final exporter = OtlpGrpcSpanExporter(
  //         OtlpGrpcExporterConfig(
  //           endpoint: endpoint,
  //           insecure: true,
  //         ),
  //       );
  //       final spanProcessor = BatchSpanProcessor(
  //         exporter,
  //         BatchSpanProcessorConfig(
  //           maxQueueSize: 2048,
  //           scheduleDelay: Duration(seconds: 1),
  //           maxExportBatchSize: 512,
  //         ),
  //       );
  //       sdk.OTel.tracerProvider().addSpanProcessor(spanProcessor);
  /// ```
  /// [sampler] is the sampling strategy to use. Defaults to AlwaysOnSampler.
  /// [spanKind] is the default SpanKind to use. The OTel default is
  /// SpanKind.internal.  This defaults the SpanKind to SpanKind.client.
  /// Note that Dartastic OTel defaults to SpanKind.server
  /// [detectPlatformResources] whether or not to detect platform resources,
  /// Defaults to true.  If set to false, as of this release, there's no need
  /// to await this initialize call, though this may change a future release.
  ///   os.type: 'android|ios|macos|linux|windows' (from Platform.isXXX)
  ///   os.version: io.Platform.operatingSystemVersion
  ///   process.executable.name: io.Platform.executable
  ///   process.command_line: io.Platform.executableArguments.join(' ')
  ///   process.runtime.name: dart
  ///   process.runtime.version: io.Platform.version
  ///   process.num_threads: io.Platform.numberOfProcessors.toString()
  ///   host.name: io.Platform.localHostname,
  ///   host.arch: io.Platform.localHostname,
  ///   host.processors: io.Platform.numberOfProcessors,
  ///   host.os.name: io.Platform.operatingSystem,
  ///   host.locale: io.Platform.localeName,

  /// Under the hood this sets a variety of intelligent defaults:
  // Points to the OTel spec's default gRPC endpoint on the localhost: https://localhost:4317, which isn't
  // very useful for mobile, except for development with localhost redirected.
  // TODO - doc using the collector locally for dev with simulator/emulator.
  // Providing a value for `dartasticApiKey` will point the endpoint to: https://otel.dartastic.io:4317
  // - It gets computes an OTel [Resource](https://opentelemetry.io/docs/specs/otel/resource/sdk/) for the device
  //   so all traces can be tied back to the device.
  //   The Resource includes:
  //   For all platforms :
  //   os.type: 'android|ios|macos|linux|windows' (from Platform.isXXX)
  //   os.version: io.Platform.operatingSystemVersion
  //   process.executable.name: io.Platform.executable
  //   process.command_line: io.Platform.executableArguments.join(' ')
  //   process.runtime.name: dart
  //   process.runtime.version: io.Platform.version
  //   process.num_threads: io.Platform.numberOfProcessors.toString()
  //   host.name: io.Platform.localHostname,
  //   host.arch: io.Platform.localHostname,
  //   host.processors: io.Platform.numberOfProcessors,
  //   host.os.name: io.Platform.operatingSystem,
  //   host.locale: io.Platform.localeName,
  //
  //   For Flutter web:
  //   browser.language: html.window.navigator.language
  //   browser.platform: html.window.navigator.platform
  //   browser.user_agent: html.window.navigator.userAgent
  //   browser.mobile: html.window.navigator.userAgent.contains('Mobile').toString()
  //   browser.languages: html.window.navigator.languages?.join(',')
  //   browser.vendor: html.window.navigator.vendor,
  //   Environmental variables and `--dart-define`'s (TODO - doc)
  // TODO - function to get the app session key
  // TODO - function to get device id
  // TODO - function to use for devs including device_info_plus to call it
  // and return attributes
  static Future<void> initialize({
    String? appName,
    String? endpoint,
    bool secure = true,
    String serviceName = defaultServiceName,
    String? serviceVersion = defaultServiceVersion,
    String? tracerName,
    String? tracerVersion,
    Attributes? resourceAttributes,
    CommonAttributesFunction? commonAttributesFunction,
    sdk.SpanProcessor? spanProcessor,
    sdk.Sampler? sampler,
    SpanKind spanKind = SpanKind.client,
    String? dartasticApiKey,
    String? tenantId,
    Duration? flushTracesInterval = const Duration(seconds: 30),
    bool detectPlatformResources = true,
    // Metrics configuration
    MetricExporter? metricExporter,
    MetricReader? metricReader,
    bool enableMetrics = true,
  }) async {
    _appName = appName ?? serviceName;
    FlutterOTel.commonAttributesFunction = commonAttributesFunction;
    if (endpoint == null) {
      // OTel environment variables come first
      final envEndpoint = const String.fromEnvironment(
        'OTEL_EXPORTER_OTLP_ENDPOINT',
      );
      if (envEndpoint.isNotEmpty) {
        endpoint = envEndpoint;
        if (OTelLog.isDebug()) {
          OTelLog.debug(
            'Using endpoint from OTEL_EXPORTER_OTLP_ENDPOINT: $endpoint',
          );
        }
      } else if (dartasticApiKey != null && dartasticApiKey.isNotEmpty) {
        // dartastic key uses the dartastic endpoint
        endpoint = dartasticEndpoint;
        if (OTelLog.isDebug()) {
          OTelLog.debug('Using default Dartastic endpoint : $endpoint');
        }
      } else {
        endpoint = OTelFactory.defaultEndpoint;
        if (OTelLog.isDebug()) {
          OTelLog.debug(
            'Using endpoint from OTelFactory.defaultEndpoint: $endpoint',
          );
        }
      }
    }

    if (OTelLog.isDebug()) OTelLog.debug('Using endpoint: $endpoint');

    resourceAttributes ??= sdk.OTel.attributes();
    appLaunchId = Uuid().v4();
    resourceAttributes = resourceAttributes.copyWithAttributes(
      <String, Object>{
        AppLifecycleSemantics.appLaunchId.key: appLaunchId!,
      }.toAttributes(),
    );

    // Create platform-specific exporters if not provided
    if (spanProcessor == null) {
      sdk.SpanExporter exporter;
      if (kIsWeb) {
        // Web platform must use HTTP
        if (OTelLog.isDebug()) {
          OTelLog.debug('Creating HTTP span exporter for web platform');
        }
        exporter = OtlpHttpSpanExporter(
          OtlpHttpExporterConfig(
            endpoint: endpoint,
            compression: false, // Web doesn't handle compression well
          ),
        );
      } else {
        // Native platforms use gRPC
        if (OTelLog.isDebug()) {
          OTelLog.debug('Creating gRPC span exporter for native platform');
        }
        exporter = OtlpGrpcSpanExporter(
          OtlpGrpcExporterConfig(endpoint: endpoint, insecure: !secure),
        );
      }
      spanProcessor = sdk.BatchSpanProcessor(
        exporter,
        const BatchSpanProcessorConfig(
          maxQueueSize: 2048,
          scheduleDelay: Duration(seconds: 1),
          maxExportBatchSize: 512,
        ),
      );
      if (OTelLog.isDebug()) {
        OTelLog.debug('Created ${kIsWeb ? "HTTP" : "gRPC"} span processor');
      }
    }

    // Create platform-specific metric exporters if not provided
    if (metricExporter == null) {
      if (kIsWeb) {
        // Web platform must use HTTP
        if (OTelLog.isDebug()) {
          OTelLog.debug('Creating HTTP metric exporter for web platform');
        }
        metricExporter = OtlpHttpMetricExporter(
          OtlpHttpMetricExporterConfig(
            endpoint: endpoint,
            compression: false, // Web doesn't handle compression well
          ),
        );
      } else {
        // Native platforms use gRPC
        if (OTelLog.isDebug()) {
          OTelLog.debug('Creating gRPC metric exporter for native platform');
        }
        metricExporter = OtlpGrpcMetricExporter(
          OtlpGrpcMetricExporterConfig(endpoint: endpoint, insecure: !secure),
        );
      }
    }

    metricReader ??= PeriodicExportingMetricReader(
      metricExporter,
      interval: Duration(seconds: 1), // Export every second
    );

    await sdk.OTel.initialize(
      endpoint: endpoint,
      secure: secure,
      serviceName: serviceName,
      serviceVersion: serviceVersion,
      tracerName: tracerName,
      tracerVersion: tracerVersion,
      resourceAttributes: resourceAttributes,
      spanProcessor: spanProcessor,
      sampler: sampler ?? AlwaysOnSampler(),
      spanKind: spanKind,
      metricExporter: metricExporter,
      metricReader: metricReader,
      enableMetrics: enableMetrics,
      dartasticApiKey: dartasticApiKey,
      tenantId: tenantId,
      detectPlatformResources: detectPlatformResources,
      oTelFactoryCreationFunction: otelFlutterFactoryFactoryFunction,
    );
    //TODO - merge mobile/Flutter specific resources
    //sdk.OTel.defaultResource = sdk.OTel.defaultResourcemerge(flutterResources);
    //Create observers
    _lifecycleObserver = OTelLifecycleObserver();
    _routeObserver = OTelNavigatorObserver();
    _interactionTracker = OTelInteractionTracker();

    WidgetsBinding.instance.addObserver(_lifecycleObserver!);

    // Initialize OTel metrics bridge
    // This connects Flutter metrics to OpenTelemetry
    OTelMetricsBridge.instance.initialize();

    if (kDebugMode) {
      MetricsService.debugPrintMetricsStatus();
    }

    //TODO - move down to Dartastic but make Dartastic default to null
    if (flushTracesInterval != null) {
      Timer.periodic(flushTracesInterval, (_) {
        sdk.OTel.tracerProvider().forceFlush();
      });
    }
  }

  /// Get the Tracer instance
  static UITracer get tracer => sdk.OTel.tracer() as UITracer;

  static UITracerProvider get tracerProvider =>
      sdk.OTel.tracerProvider() as UITracerProvider;

  /// Get the MeterProvider instance
  static UIMeterProvider get meterProvider {
    return sdk.OTel.meterProvider() as UIMeterProvider;
  }

  /// Get a Meter with the given name and version
  static UIMeter meter({
    String name = 'flutter.default',
    String? version,
    String? schemaUrl,
  }) {
    return meterProvider.getMeter(
          name: name,
          version: version,
          schemaUrl: schemaUrl,
        )
        as UIMeter;
  }

  /// Starts a span for a screen/route
  /// Normally this will be handled automatically by the NavigatorObserver
  /// This is useful for manual spans like a subscription popup.
  /// [root] if (route is true, this starts a new trace)
  /// [childRoute] If not a child, this ends an existing screen span.
  /// [spanLinks]
  sdk.Span startScreenSpan(
    String screenName, {
    bool root = false,
    bool childRoute = false,
    Attributes? attributes,
    List<SpanLink>? spanLinks,
  }) {
    // TODO
    // if (!tracer.enabled) {
    //   return tracer.emptySpan();
    // }
    if (root && childRoute) {
      throw ArgumentError('root cannot be a child route');
    }
    if (!childRoute) {
      // End any existing spans
      endScreenSpan(screenName);
    }
    if (root) {
      //TODO - end all the spans in the path
    }
    final span = tracer.startSpan(
      'screen.$screenName',
      kind: SpanKind.client,
      attributes:
          {'ui.screen.name': screenName, 'ui.type': 'screen'}.toAttributes(),
    );

    _activeSpans[screenName] = span;
    return span;
  }

  /// Ends the span for a screen/route
  void endScreenSpan(String screenName) {
    if (!tracer.enabled) return;

    final span = _activeSpans[screenName];
    if (span != null) {
      span.end();
      _activeSpans.remove(screenName);
    }
  }

  /// Creates and immediately ends a span for a user interaction
  void recordUserInteraction(
    String screenName,
    String interactionType, {
    String? targetName,
    Duration? responseTime,
    Map<String, dynamic>? attributes,
  }) {
    if (!tracer.enabled) return;

    // Create interaction attributes
    final interactionAttributes = <String, Object>{
      'ui.screen.name': screenName,
      'ui.interaction.type': interactionType,
      if (targetName != null) 'ui.interaction.target': targetName,
      if (responseTime != null)
        'ui.interaction.response_time_ms': responseTime.inMilliseconds,
      ...?attributes,
    };

    // Record as span
    final spanName = 'interaction.$screenName.$interactionType';
    final span = tracer.startSpan(
      spanName,
      kind: SpanKind.client,
      attributes: interactionAttributes.toAttributes(),
    );

    if (responseTime != null) {
      // Set the end time based on the response time
      span.end(endTime: span.startTime.add(responseTime));

      // Also record as a metrics histogram
      meter(name: 'flutter.interaction')
          .createHistogram(
            name: 'interaction.response_time',
            description: 'User interaction response time',
            unit: 'ms',
          )
          .record(
            responseTime.inMilliseconds,
            interactionAttributes.toAttributes(),
          );
    } else {
      span.end();

      // Record as a simple counter
      meter(name: 'flutter.interaction')
          .createCounter(
            name: 'interaction.count',
            description: 'User interaction count',
            unit: '{interactions}',
          )
          .add(1, interactionAttributes.toAttributes());
    }
  }

  /// Records a navigation event between routes
  void recordNavigation(
    String fromRoute,
    String toRoute,
    String navigationType,
    Duration duration,
  ) {
    if (!tracer.enabled) return;

    // Create navigation attributes
    final navAttributes = {
      'ui.navigation.from': fromRoute,
      'ui.navigation.to': toRoute,
      'ui.navigation.type': navigationType,
    };

    // Record as span
    final spanName = 'navigation.$navigationType';
    final span = tracer.startSpan(
      spanName,
      kind: SpanKind.client,
      attributes: navAttributes.toAttributes(),
    );

    span.end(endTime: span.startTime.add(duration));

    // Also record as metric
    meter(name: 'flutter.navigation')
        .createHistogram(
          name: 'navigation.duration',
          description: 'Navigation transition time',
          unit: 'ms',
        )
        .record(duration.inMilliseconds, navAttributes.toAttributes());
  }

  /// Records an error within the current context
  static void reportError(
    String message,
    dynamic error,
    StackTrace? stackTrace, {
    Map<String, dynamic>? attributes,
  }) {
    try {
      OTelLog.error('Flutter error reported: $message \nStack: $stackTrace');
      if (OTelFactory.otelFactory == null) {
        debugPrint('Error before OTel initialization: $message, $error');
        debugPrintStack(stackTrace: stackTrace);
        return; //cannot, too early
      }
      if (!tracer.enabled) return;

      // Create attribute map
      final errorAttributes = <String, Object>{
        'error.context': message,
        'error.type': error.runtimeType.toString(),
        'error.message': error.toString(),
        ...?attributes,
      };

      // Record as span
      final span = tracer.startSpan(
        'error.$message',
        kind: SpanKind.client,
        attributes: errorAttributes.toAttributes(),
      );

      span.recordException(error, stackTrace: stackTrace, escaped: true);
      span.setStatus(SpanStatusCode.Error, error.toString());
      span.end();

      // Also record as a metric counter
      meter(name: 'flutter.errors')
          .createCounter(
            name: 'error.count',
            description: 'Error counter',
            unit: '{errors}',
          )
          .add(1, errorAttributes.toAttributes());
    } catch (e, s) {
      // TODO - best alternative?
      OTelLog.error('Error when reporting the Flutter error: $e \n$s');
    }
  }

  /// Records a performance metric
  void recordPerformanceMetric(
    String name,
    Duration duration, {
    Map<String, dynamic>? attributes,
  }) {
    if (!tracer.enabled) return;

    // Record in both spans and metrics
    final span = tracer.startSpan(
      'perf.$name',
      kind: SpanKind.client,
      attributes:
          <String, Object>{
            'perf.metric.name': name,
            'perf.duration_ms': duration.inMilliseconds,
            ...?attributes,
          }.toAttributes(),
    );

    span.end(endTime: span.startTime.add(duration));

    // Also record as a metric for proper aggregation
    meter(name: 'flutter.performance')
        .createHistogram(
          name: 'perf.$name',
          description: 'Performance measurement for $name',
          unit: 'ms',
        )
        .record(
          duration.inMilliseconds,
          <String, Object>{
            'perf.metric.name': name,
            ...?attributes,
          }.toAttributes(),
        );
  }

  /// Clean up resources
  void dispose() {
    if (_lifecycleObserver != null) {
      _lifecycleObserver!.dispose();
    }
    forceFlush();
  }

  /// Sends all pending OTel data
  static forceFlush() {
    tracerProvider.forceFlush(); //TODO - await
  }

  @visibleForTesting
  static reset() {
    // ignore: invalid_use_of_visible_for_testing_member
    sdk.OTel.reset();
    try {
      WidgetsBinding.instance.removeObserver(FlutterOTel.lifecycleObserver);
    } catch (e) {
      // Ignore errors when observer isn't registered
    }
  }
}

/// Extension methods for Flutter widgets to simplify OpenTelemetry integration
// TODO doc usage
extension OTelWidgetExtension on Widget {
  /// Wraps a widget with OpenTelemetry error boundary
  Widget withOTelErrorBoundary(String context) {
    return Builder(
      builder: (buildContext) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          // Record error in OpenTelemetry
          final tracer = FlutterOTel.tracer;
          var errorWidget = errorDetails.context;
          String widgetName =
              errorWidget == null
                  ? errorWidget.runtimeType.toString()
                  : 'Unknown';
          tracer.recordError(
            context,
            errorDetails.exception,
            errorDetails.stack,
            attributes: {
              'error.context': 'widget_build',
              'error.widget': widgetName,
            },
          );

          // Return original error widget
          return ErrorWidget(errorDetails.exception);
        };

        return this;
      },
    );
  }
}
