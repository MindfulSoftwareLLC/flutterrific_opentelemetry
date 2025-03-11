// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

part of 'ui_tracer_provider.dart';

/// Factory for creating UITracer instances
class UITracerProviderCreate {
  static UITracerProvider create({
    required TracerProvider delegate,
  }) {
    return UITracerProvider._(
        delegate: delegate,
    );
  }
}
