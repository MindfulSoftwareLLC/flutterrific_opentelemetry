// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'dart:typed_data';

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart' as sdk;
import 'package:flutter/foundation.dart';

class OTelRouteData {
  final String routeName;

  /// a spanId equivalent for a route
  final Uint8List routeId;
  final String routePath;
  final String routeArguments;
  final String routeKey;
  final DateTime timestamp;

  OTelRouteData({
    required this.routeName,
    required this.routePath,
    required this.routeArguments,
    required this.routeKey,
  }) : routeId = sdk.OTel.spanId().bytes,
        timestamp = DateTime.now();

  static OTelRouteData empty() {
    return OTelRouteData(
      routeName: '',
      routePath: '',
      routeArguments: '',
      routeKey: '',
    );
  }
}
