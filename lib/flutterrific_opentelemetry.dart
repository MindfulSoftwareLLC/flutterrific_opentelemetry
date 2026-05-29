// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

library;

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

/// Re-export key OpenTelemetry API components for convenience
export 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart'
    show
        AppInfoSemantics,
        Attributes,
        AttributesExtension,
        Baggage,
        BaggageEntry,
        BatterySemantics,
        Context,
        ContextKey,
        DeviceSemantics,
        IdGenerator,
        ErrorResource,
        ErrorSemantics,
        ExceptionResource,
        FileResource,
        LogLevel,
        Measurement,
        OTelLog,
        ObservableCallback,
        ProcessResource,
        SpanContext,
        SpanEvent,
        SpanLink,
        SpanId,
        SpanKind,
        SpanStatusCode,
        Timestamp,
        TraceId,
        TraceFlags,
        TraceState,
        Severity,
        LogRecord,
        // UI Semantics
        AppLifecycleSemantics,
        AppLifecycleStates,
        AppStartType,
        InteractionSemantics,
        InteractionType,
        NavigationSemantics,
        NetworkSemantics,
        PerformanceSemantics,
        RumSessionView;
