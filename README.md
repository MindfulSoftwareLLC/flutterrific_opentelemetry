# OpenTelemetry SDK for Flutter

[![pub.dev](https://img.shields.io/pub/v/flutterrific_opentelemetry.svg)](https://pub.dev/packages/flutterrific_opentelemetry)
[![Flutter CI](https://github.com/MindfulSoftwareLLC/flutterrific_opentelemetry/actions/workflows/flutter.yml/badge.svg)](https://github.com/MindfulSoftwareLLC/flutterrific_opentelemetry/actions/workflows/flutter.yml)
[![codecov](https://codecov.io/gh/MindfulSoftwareLLC/flutterrific_opentelemetry/branch/main/graph/badge.svg)](https://codecov.io/gh/MindfulSoftwareLLC/flutterrific_opentelemetry)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

An OpenTelemetry SDK for Flutter applications built on the [Dartastic OpenTelemetry SDK](https://pub.dev/packages/dartastic_opentelemetry), providing comprehensive observability for Flutter applications across all platforms.

## Overview

This Flutter SDK implements the [OpenTelemetry](https://opentelemetry.io/) specification, enabling developers to collect distributed traces, metrics, and logs from Flutter applications. OpenTelemetry is the second most active [Cloud Native Computing Foundation (CNCF)](https://www.cncf.io/) project after Kubernetes, providing a vendor-neutral standard for observability.

## Why OpenTelemetry for Flutter?

- **Future-Proof**: OpenTelemetry is an industry standard with broad ecosystem support
- **Vendor Neutral**: Works with any OpenTelemetry-compatible backend
- **Comprehensive**: Covers traces, metrics, and logs in a unified approach
- **Cross-Platform**: Supports all Flutter platforms (Android, iOS, Web, Desktop)
- **Performance**: Designed for minimal overhead in production applications

## Features

- 🚀 **Simple Integration**: Get started with just a few lines of code
- 👣 **Automatic Instrumentation**: Navigation, app lifecycle, and user interaction tracking
- 📊 **Performance Metrics**: Web vitals, APDEX scores, and custom performance metrics
- 🧩 **Widget Extensions**: Easy-to-use extensions for widget-level observability
- 🐞 **Error Tracking**: Comprehensive error handling and reporting
- 📐 **Standards Compliant**: Full adherence to OpenTelemetry specification
- 🌐 **Multi-Platform**: Supports Android, iOS, Web, and Desktop platforms
- 💪 **Context Propagation**: Seamless trace correlation across async boundaries
- 🔧 **Configurable Sampling**: Multiple sampling strategies for cost optimization
- 🧷 **Type-Safe Semantics**: Strongly-typed semantic conventions

## Quick Start

### 1. Add Dependency

```yaml
dependencies:
  flutterrific_opentelemetry: ^0.3.0
```

### 2. Initialize OpenTelemetry

```dart
import 'package:flutter/material.dart';
import 'package:flutterrific_opentelemetry/flutterrific_otel.dart';

void main() {
  // Initialize error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterOTel.reportError('FlutterError.onError', details.exception, details.stack);
  };

  runZonedGuarded(() {
    // Initialize OpenTelemetry
    FlutterOTel.initialize(
      serviceName: 'my-flutter-app',
      serviceVersion: '1.0.0',
      tracerName: 'main',
      // Configure your exporter endpoint
      resourceAttributes: {
        'deployment.environment': 'production',
        'service.namespace': 'mobile-apps',
      }
    );
    
    runApp(MyApp());
  }, (error, stack) {
    FlutterOTel.reportError('Zone Error', error, stack);
  });
}
```

### 3. Automatic Instrumentation

The SDK automatically instruments:
- **Navigation**: Track route changes and user flows
- **App Lifecycle**: Monitor foreground/background transitions
- **Performance**: Collect frame rates and rendering metrics
- **Errors**: Capture and report exceptions with context

## Platform Support

| Platform | Support Level | Protocol | Notes |
|----------|---------------|----------|-------|
| Android  | Full         | OTLP/gRPC | Complete feature support |
| iOS      | Full         | OTLP/gRPC | Complete feature support |
| Web      | Full         | OTLP/HTTP | Auto-switches due to browser limitations |
| Windows  | Beta         | OTLP/gRPC | Desktop support |
| macOS    | Beta         | OTLP/gRPC | Desktop support |
| Linux    | Beta         | OTLP/gRPC | Desktop support |

## Advanced Usage

### Custom Tracing

```dart
void fetchUserData() async {
  final tracer = FlutterOTel.tracer;
  
  final span = tracer.startSpan('fetch_user_data', attributes: {
    'user.id': userId,
    'api.endpoint': '/users',
  });
  
  try {
    final result = await apiClient.getUser(userId);
    span.setStatus(SpanStatusCode.Ok);
    return result;
  } catch (e, stackTrace) {
    span.recordException(e, stackTrace: stackTrace);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
```

### Widget-Level Tracking

```dart
// Track button interactions
ElevatedButton(
  onPressed: handleSubmit,
  child: Text('Submit'),
).withOTelButtonTracking('submit_form');

// Monitor widget performance
ComplexWidget().withOTelPerformanceTracking('complex_widget');

// Error boundaries
RiskyWidget().withOTelErrorBoundary('risky_operation');
```

## Configuration

### Environment Variables

Standard OpenTelemetry environment variables are supported:

```bash
# Exporter endpoint
--dart-define=OTEL_EXPORTER_OTLP_ENDPOINT=https://your-collector:4317

# Protocol selection (grpc or http/protobuf)
--dart-define=OTEL_EXPORTER_OTLP_PROTOCOL=grpc

# Service information
--dart-define=OTEL_SERVICE_NAME=my-flutter-app
--dart-define=OTEL_SERVICE_VERSION=1.0.0
```

### Local Development

For local development, run an OpenTelemetry collector:

```bash
docker run -p 4317:4317 -p 4318:4318 --rm -ti grafana/otel-lgtm
```

## Documentation

- [Getting Started Guide](https://pub.dev/packages/flutterrific_opentelemetry#getting-started)
- [API Reference](https://pub.dev/documentation/flutterrific_opentelemetry/latest/)
- [Migration Guide](VERSIONING.md)
- [Best Practices](https://dartastic.io/docs/best-practices)

## Examples

- [Basic Integration Example](example/)
- [Wonderous OpenTelemetry](https://pub.dev/packages/wonderous_opentelemetry) - Complete app example

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/MindfulSoftwareLLC/flutterrific_opentelemetry.git
cd flutterrific_opentelemetry

# Install dependencies
make install

# Run tests
make test

# Run all checks
make all
```

## Governance

This project follows the [CNCF Code of Conduct](https://github.com/cncf/foundation/blob/main/code-of-conduct.md) and maintains [open governance](GOVERNANCE.md). We welcome community participation and contributions.

## Security

Security vulnerabilities should be reported privately to the maintainers. See our [Security Policy](SECURITY.md) for details.

## Compatibility

- **Flutter**: 3.7.0+
- **Dart**: 3.7.0+
- **OpenTelemetry Specification**: 1.31.0
- **Platforms**: Android, iOS, Web, Windows, macOS, Linux

## Roadmap

See our [Roadmap](ROADMAP.md) for planned features and improvements.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Community

- [GitHub Issues](https://github.com/MindfulSoftwareLLC/flutterrific_opentelemetry/issues) - Bug reports and feature requests
- [GitHub Discussions](https://github.com/MindfulSoftwareLLC/flutterrific_opentelemetry/discussions) - Community discussions
- [OpenTelemetry Community](https://opentelemetry.io/community/) - Broader OpenTelemetry community

## Acknowledgments

Built on the foundation of:
- [Dartastic OpenTelemetry SDK](https://pub.dev/packages/dartastic_opentelemetry)
- [OpenTelemetry Specification](https://opentelemetry.io/docs/specs/otel/)
- [Flutter Framework](https://flutter.dev/)

Maintained by [Michael Bushe](https://github.com/michaelbushe) and [Mindful Software LLC](https://mindfulsoftware.com).

---

*This project aims to be contributed to the [OpenTelemetry](https://opentelemetry.io/) organization under the [Cloud Native Computing Foundation](https://www.cncf.io/).*
