import 'dart:io';
import 'package:flutter/foundation.dart';

/// OpenTelemetry endpoint configuration for different platforms and environments
class OTelConfig {
  static final endpointEnv = const String.fromEnvironment(
    'OTEL_EXPORTER_OTLP_ENDPOINT',
  );
  static final protocolEnv = const String.fromEnvironment(
    'OTEL_EXPORTER_OTLP_PROTOCOL',
  );

  /// Determines the appropriate OTLP endpoint based on platform and environment
  static String get endpoint {
    if (endpointEnv.isNotEmpty) {
      return endpointEnv;
    }
    if (kIsWeb) {
      // Web builds run in browsers, MUST use HTTP endpoint (4318)
      // Browsers cannot use gRPC directly
      return 'http://localhost:4318';
    } else if (!kIsWeb && Platform.isAndroid) {
      if (kDebugMode) {
        return androidEmulatorEndpoint;
      } else {
        return localEndpoint;
      }
    } else if (!kIsWeb && Platform.isIOS) {
      if (kDebugMode) {
        // iOS Simulator can access localhost directly
        return localEndpoint;
      } else {
        // For physical iOS devices, set OTEL_EXPORTER_OTLP_ENDPOINT to your
        // development machine's IP
        return localEndpoint;
      }
    } else {
      // Desktop platforms (macOS, Windows, Linux), OTel default
      return localEndpoint;
    }
  }

  /// Whether to use secure (TLS) connection
  static bool get secure => false; // Set to true for production HTTPS endpoints

  /// Gets the protocol scheme based on security setting
  static String get protocol => secure ? 'https' : 'http';

  /// Gets the port based on platform preferences
  static int get port {
    if (kIsWeb) {
      return 4318; // Web MUST use HTTP endpoint (4318)
    } else {
      return 4317; // gRPC endpoint for mobile/desktop
    }
  }

  /// Gets the full URL with correct path for web
  static String get fullEndpoint {
    if (kIsWeb) {
      return '$protocol://localhost:4318/v1/metrics';
    } else {
      return endpoint;
    }
  }

  /// Alternative endpoints for different environments
  static const String localEndpoint = 'http://localhost:4317';
  static const String localWebEndpoint = 'http://localhost:4318';
  static const String androidEmulatorEndpoint = 'http://10.0.2.2:4317';

  /// Web-specific endpoints with full paths
  static const String webMetricsEndpoint = 'http://localhost:4318/v1/metrics';
  static const String webTracesEndpoint = 'http://localhost:4318/v1/traces';

  /// Get endpoint for specific platform (useful for testing)
  static String getEndpointForPlatform(
    TargetPlatform platform, {
    bool isEmulator = false,
  }) {
    switch (platform) {
      case TargetPlatform.android:
        return isEmulator ? androidEmulatorEndpoint : localEndpoint;
      case TargetPlatform.iOS:
        return localEndpoint;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return localEndpoint;
      case TargetPlatform.fuchsia:
        return localEndpoint;
    }
  }

  /// Get metrics endpoint based on platform
  static String get metricsEndpoint {
    if (kIsWeb) {
      return webMetricsEndpoint;
    } else {
      return endpoint;
    }
  }

  /// Get traces endpoint based on platform
  static String get tracesEndpoint {
    if (kIsWeb) {
      return webTracesEndpoint;
    } else {
      return endpoint;
    }
  }

  /// Print current configuration for debugging
  static void printConfig() {
    if (kDebugMode) {
      print('=== OpenTelemetry Configuration ===');
      if (kIsWeb) {
        print('Platform: Web Browser');
        print('Protocol: HTTP (required for web)');
        print('Base Endpoint: $endpoint');
        print('Note: HTTP exporter will automatically append /v1/metrics');
      } else {
        print(
          'Platform: ${Platform.isAndroid
              ? 'Android'
              : Platform.isIOS
              ? 'iOS'
              : Platform.operatingSystem}',
        );
        print('Protocol: gRPC');
        print('Endpoint: $endpoint');
      }
      print('Secure: $secure');
      print('Port: $port');
      print(
        'Environment Override: ${endpointEnv.isEmpty ? 'None' : endpointEnv}',
      );
      print('===================================');
    }
  }

  /// Check if the current configuration is valid for the platform
  static bool get isValidConfiguration {
    if (kIsWeb) {
      // Web must use HTTP endpoint
      return endpoint.contains('4318') && endpoint.startsWith('http://');
    } else {
      // Native platforms can use gRPC or HTTP
      return endpoint.isNotEmpty;
    }
  }

  /// Get recommended headers for the current platform
  static Map<String, String> get recommendedHeaders {
    if (kIsWeb) {
      return {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      };
    } else {
      return {'Content-Type': 'application/x-protobuf'};
    }
  }
}
