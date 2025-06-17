// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/foundation.dart';

import 'otel_config.dart';

/// Helper class to detect platform-specific capabilities and configurations
class PlatformDetection {
  /// Returns true if the current platform is Flutter Web
  static bool get isWeb => kIsWeb;

  /// Creates the appropriate span exporter based on the current platform and configuration
  ///
  /// For Flutter Web, this will create an HTTP exporter.
  /// For other platforms, this will create a gRPC exporter.
  ///
  /// The method respects these environment variables:
  /// - OTEL_EXPORTER_OTLP_ENDPOINT: The endpoint URL
  /// - OTEL_EXPORTER_OTLP_PROTOCOL: The protocol to use (grpc, http/protobuf)
  ///
  /// Returns an OtlpGrpcSpanExporter by default or an OtlpHttpSpanExporter for web or
  /// when explicitly configured through environment variables.
  static SpanExporter createSpanExporter({
    String? endpoint,
    bool insecure = false,
  }) {
    // Get endpoint from environment variable if not provided
    final resolvedEndpoint = OTelConfig.endpointEnv;

    // Get protocol from environment variable
    final envProtocol = OTelConfig.protocolEnv;

    // Determine if we should use HTTP/protobuf
    bool useHttp = isWeb; // Always use HTTP for web

    // If explicitly configured, use that instead
    if (envProtocol.isNotEmpty) {
      if (envProtocol.toLowerCase() == 'http/protobuf') {
        useHttp = true;
        if (OTelLog.isDebug()) OTelLog.debug('Using HTTP/protobuf protocol as configured');
      } else if (envProtocol.toLowerCase() == 'grpc') {
        useHttp = false;
        if (OTelLog.isDebug()) OTelLog.debug('Using gRPC protocol as configured');
      } else {
        if (OTelLog.isWarn()) OTelLog.warn('Unknown OTEL_EXPORTER_OTLP_PROTOCOL: $envProtocol, defaulting to ${useHttp ? "HTTP/protobuf" : "gRPC"}');
      }
    }

    // Create the appropriate exporter
    if (useHttp) {
      // Ensure endpoint is HTTP URLs for HTTP/protobuf
      String httpEndpoint = resolvedEndpoint;
      if (!httpEndpoint.toLowerCase().startsWith('http://') && !httpEndpoint.toLowerCase().startsWith('https://')) {
        httpEndpoint = insecure ? 'http://$httpEndpoint' : 'https://$httpEndpoint';
      }

      // For HTTP, we need to ensure the port is 4318 if not specified
      if (!httpEndpoint.contains(':')) {
        httpEndpoint = '$httpEndpoint:4318';
      } else if (httpEndpoint.contains(':4317')) {
        // If using the gRPC port, change to HTTP port
        httpEndpoint = httpEndpoint.replaceAll(':4317', ':4318');
      }

      if (OTelLog.isDebug()) OTelLog.debug('Creating OtlpHttpSpanExporter with endpoint: $httpEndpoint');
      return OtlpHttpSpanExporter(
        OtlpHttpExporterConfig(
          endpoint: httpEndpoint,
          compression: false, // Web doesn't handle compression well
        ),
      );
    } else {
      // For gRPC, ensure we have the right format
      String grpcEndpoint = resolvedEndpoint;

      // Remove http/https from the endpoint for gRPC
      if (grpcEndpoint.toLowerCase().startsWith('http://') || grpcEndpoint.toLowerCase().startsWith('https://')) {
        bool isSecure = grpcEndpoint.toLowerCase().startsWith('https://');
        grpcEndpoint = grpcEndpoint.replaceAll(RegExp(r'^(http|https)://'), '');
        // If insecure wasn't explicitly set, use the protocol from the URL
        insecure = insecure || !isSecure;
      }

      if (OTelLog.isDebug()) OTelLog.debug('Creating OtlpGrpcSpanExporter with endpoint: $grpcEndpoint, insecure: $insecure');
      return OtlpGrpcSpanExporter(
        OtlpGrpcExporterConfig(
          endpoint: grpcEndpoint,
          insecure: insecure,
        ),
      );
    }
  }

  /// Creates the appropriate metric exporter based on the current platform and configuration
  ///
  /// For Flutter Web, this will create an HTTP exporter.
  /// For other platforms, this will create a gRPC exporter.
  ///
  /// The method respects these environment variables:
  /// - OTEL_EXPORTER_OTLP_ENDPOINT: The endpoint URL
  /// - OTEL_EXPORTER_OTLP_PROTOCOL: The protocol to use (grpc, http/protobuf)
  ///
  /// Returns an OtlpGrpcMetricExporter by default or an OtlpHttpMetricExporter for web or
  /// when explicitly configured through environment variables.
  static MetricExporter createMetricExporter({
    String? endpoint,
    bool insecure = false,
  }) {
    // Get endpoint from environment variable if not provided
    final envEndpoint = const String.fromEnvironment('OTEL_EXPORTER_OTLP_ENDPOINT');
    final resolvedEndpoint = endpoint ?? (envEndpoint.isNotEmpty ? envEndpoint : 'http://localhost:4317');

    // Get protocol from environment variable
    final envProtocol = const String.fromEnvironment('OTEL_EXPORTER_OTLP_PROTOCOL');

    // Determine if we should use HTTP/protobuf
    bool useHttp = isWeb; // Always use HTTP for web

    // If explicitly configured, use that instead
    if (envProtocol.isNotEmpty) {
      if (envProtocol.toLowerCase() == 'http/protobuf') {
        useHttp = true;
        if (OTelLog.isDebug()) OTelLog.debug('Using HTTP/protobuf protocol for metrics as configured');
      } else if (envProtocol.toLowerCase() == 'grpc') {
        useHttp = false;
        if (OTelLog.isDebug()) OTelLog.debug('Using gRPC protocol for metrics as configured');
      } else {
        if (OTelLog.isWarn()) OTelLog.warn('Unknown OTEL_EXPORTER_OTLP_PROTOCOL: $envProtocol, defaulting to ${useHttp ? "HTTP/protobuf" : "gRPC"} for metrics');
      }
    }

    // Create the appropriate exporter
    if (useHttp) {
      // Ensure endpoint is HTTP URLs for HTTP/protobuf
      String httpEndpoint = resolvedEndpoint;
      if (!httpEndpoint.toLowerCase().startsWith('http://') && !httpEndpoint.toLowerCase().startsWith('https://')) {
        httpEndpoint = insecure ? 'http://$httpEndpoint' : 'https://$httpEndpoint';
      }

      // For HTTP, we need to ensure the port is 4318 if not specified
      if (!httpEndpoint.contains(':')) {
        httpEndpoint = '$httpEndpoint:4318';
      } else if (httpEndpoint.contains(':4317')) {
        // If using the gRPC port, change to HTTP port
        httpEndpoint = httpEndpoint.replaceAll(':4317', ':4318');
      }

      if (OTelLog.isDebug()) OTelLog.debug('Creating OtlpHttpMetricExporter with endpoint: $httpEndpoint');
      return OtlpHttpMetricExporter(
        OtlpHttpMetricExporterConfig(
          endpoint: httpEndpoint,
          compression: false, // Web doesn't handle compression well
        ),
      );
    } else {
      // For gRPC, ensure we have the right format
      String grpcEndpoint = resolvedEndpoint;

      // Remove http/https from the endpoint for gRPC
      if (grpcEndpoint.toLowerCase().startsWith('http://') || grpcEndpoint.toLowerCase().startsWith('https://')) {
        bool isSecure = grpcEndpoint.toLowerCase().startsWith('https://');
        grpcEndpoint = grpcEndpoint.replaceAll(RegExp(r'^(http|https)://'), '');
        // If insecure wasn't explicitly set, use the protocol from the URL
        insecure = insecure || !isSecure;
      }

      if (OTelLog.isDebug()) OTelLog.debug('Creating OtlpGrpcMetricExporter with endpoint: $grpcEndpoint, insecure: $insecure');
      return OtlpGrpcMetricExporter(
        OtlpGrpcMetricExporterConfig(
          endpoint: grpcEndpoint,
          insecure: insecure,
        ),
      );
    }
  }

  /// Adjusts an endpoint URL based on platform requirements
  ///
  /// For web platforms using HTTP, this ensures:
  /// - The URL starts with http:// or https://
  /// - The port is 4318 (OTLP/HTTP) instead of 4317 (OTLP/gRPC)
  ///
  /// For non-web platforms using gRPC, this ensures:
  /// - The URL doesn't start with http:// or https://
  ///
  /// Returns the adjusted endpoint string
  static String adjustEndpoint(String endpoint, {bool insecure = false, bool? forceHttp}) {
    final useHttp = forceHttp ?? isWeb;

    if (useHttp) {
      // For HTTP protocol
      String httpEndpoint = endpoint;

      // Ensure it starts with http:// or https://
      if (!httpEndpoint.toLowerCase().startsWith('http://') && !httpEndpoint.toLowerCase().startsWith('https://')) {
        httpEndpoint = insecure ? 'http://$httpEndpoint' : 'https://$httpEndpoint';
      }

      // Change port 4317 to 4318 if present
      if (httpEndpoint.contains(':4317')) {
        httpEndpoint = httpEndpoint.replaceAll(':4317', ':4318');
      }

      return httpEndpoint;
    } else {
      // For gRPC protocol
      String grpcEndpoint = endpoint;

      // Remove http/https from the endpoint
      if (grpcEndpoint.toLowerCase().startsWith('http://') || grpcEndpoint.toLowerCase().startsWith('https://')) {
        grpcEndpoint = grpcEndpoint.replaceAll(RegExp(r'^(http|https)://'), '');
      }

      return grpcEndpoint;
    }
  }
}
