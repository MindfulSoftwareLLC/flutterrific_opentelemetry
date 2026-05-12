// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

library;

export 'src/util/otel_config.dart';
export 'src/util/platform_detection.dart';

export 'src/flutterrific_otel.dart';
export 'src/flutterrific_otel_metrics.dart';
export 'src/metrics/flutter_metric_reporter.dart';
export 'src/metrics/metric_collector.dart';
export 'src/metrics/ui_meter.dart';
export 'src/metrics/ui_meter_provider.dart';
export 'src/metrics/otel_metrics_bridge.dart';
export 'src/metrics/metrics_service.dart';
export 'src/nav/otel_navigator_observer.dart';
export 'src/nav/otel_go_router_redirect.dart';
export 'src/common/otel_lifecycle_observer.dart';
export 'src/trace/interaction_tracker.dart';
export 'src/trace/ui_tracer.dart';
export 'src/trace/ui_tracer_provider.dart';
export 'src/logs/ui_logger.dart';
export 'src/logs/ui_logger_provider.dart';
export 'src/semantics/flutter_semantics.dart';

/// Re-export key Dartastic OpenTelemetry SDK components for convenience
export 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart'
    show
        AttributeSamplingCondition,
        AlwaysOffSampler,
        AlwaysOnSampler,
        BatchSpanProcessor,
        CompositeSampler,
        CompositeResourceDetector,
        ConsoleExporter,
        CountingSampler,
        EnvVarResourceDetector,
        ErrorSamplingCondition,
        HostResourceDetector,
        MetricExporter,
        MetricReader,
        NamePatternSamplingCondition,
        OTel,
        OTelLog,
        OtlpGrpcMetricExporter,
        OtlpGrpcMetricExporterConfig,
        OtlpGrpcExporterConfig,
        OtlpGrpcSpanExporter,
        OtlpHttpMetricExporter,
        OtlpHttpMetricExporterConfig,
        OtlpHttpSpanExporter,
        OtlpHttpExporterConfig,
        ParentBasedSampler,
        PeriodicExportingMetricReader,
        PlatformResourceDetector,
        ProbabilitySampler,
        ProcessResourceDetector,
        RateLimitingSampler,
        Resource,
        ResourceDetector,
        Sampler,
        SamplingDecision,
        SamplingDecisionSource,
        SamplingResult,
        SpanExporter,
        SpanProcessor,
        SamplingCondition,
        SimpleSpanProcessor,
        Span,
        TracerProvider,
        Tracer,
        TraceIdRatioSampler,
        // Logs
        OTelLogger,
        LoggerProvider,
        LogRecordProcessor,
        LogRecordExporter,
        BatchLogRecordProcessor,
        SimpleLogRecordProcessor,
        ConsoleLogRecordExporter,
        OtlpGrpcLogRecordExporter,
        OtlpGrpcLogRecordExporterConfig,
        OtlpHttpLogRecordExporter,
        OtlpHttpLogRecordExporterConfig,
        SDKLogRecord,
        ReadableLogRecord,
        ReadWriteLogRecord,
        DartLogBridge,
        LogsConfiguration,
        NavigationAction;

/// Re-export key OpenTelemetry API components for convenience.
///
/// As of `dartastic_opentelemetry_api` 1.0.0-beta.6, ~60 attribute-key
/// enums dropped the `Resource` suffix to match the OTel semconv
/// registry names (e.g. `HttpResource` → `Http`, `UrlResource` →
/// `Url`). Six enums kept the suffix to avoid conflicts with common
/// Dart / Flutter / library types: `ErrorResource`, `ExceptionResource`,
/// `FileResource`, `ProcessResource`, `ServerResource`, `EventResource`.
/// `UserSemantics` was renamed to `User`; `SessionViewSemantics` was
/// split into `Session` (OTel-spec keys: `session.id`,
/// `session.previous_id`) and `RumSessionView` (Datadog/Dynatrace-style
/// `view.*` and underscore-variant keys). See the API beta.6 CHANGELOG
/// for the full migration table.
export 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart'
    show
        AppInfoSemantics,
        Attributes,
        AttributesExtension,
        Baggage,
        BaggageEntry,
        BatterySemantics,
        Client,
        Cloud,
        ComputeUnit,
        ComputeInstance,
        Context,
        ContextKey,
        Database,
        Deployment,
        Device,
        DeviceSemantics,
        IdGenerator,
        Environment,
        ErrorResource,
        ErrorSemantics,
        ExceptionResource,
        FeatureFlag,
        FileResource,
        GenAI,
        General,
        GraphQL,
        Host,
        Http,
        Kubernetes,
        Measurement,
        Messaging,
        Network,
        OTelLog,
        ObservableCallback,
        OperatingSystem,
        ProcessResource,
        RPC,
        Service,
        SourceCode,
        SpanContext,
        SpanEvent,
        SpanLink,
        SpanId,
        SpanKind,
        SpanStatusCode,
        TelemetryDistro,
        TelemetrySDK,
        Timestamp,
        TraceId,
        TraceFlags,
        TraceState,
        Severity,
        LogRecord,
        Url,
        // `User` replaces `UserSemantics` (beta.6 rename).
        User,
        Version,
        // UI Semantics
        AppLifecycleSemantics,
        AppLifecycleStates,
        AppStartType,
        InteractionSemantics,
        InteractionType,
        NavigationSemantics,
        NetworkSemantics,
        PerformanceSemantics,
        // `SessionViewSemantics` split: OTel-spec keys live on
        // `Session`; the Datadog/Dynatrace-style RUM keys
        // (`view.name`, `view.start`, etc.) live on `RumSessionView`.
        Session,
        RumSessionView;
