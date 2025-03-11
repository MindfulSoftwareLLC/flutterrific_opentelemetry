// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart' as sdk;
import 'otel_route_data.dart';

/// Common method for recording a nav span from OTelRouteData
/// Used by the [OTelGoRouterRedirect] and [OTelNavigatorObserver]
void recordNavigationChange(
  OTelRouteData newRouteData,
  OTelRouteData? previousRouteData,
  sdk.NavigationAction newRouteChangeType,
) {
  var routeDuration = previousRouteData?.timestamp.difference(
    newRouteData.timestamp,
  );
  FlutterOTel.tracer.recordNavChange(
    newRouteData.routeName,
    newRouteData.routePath,
    newRouteData.routeKey,
    newRouteData.routeArguments,
    newRouteData.routeId,
    newRouteData.timestamp,
    previousRouteData?.routeName,
    previousRouteData?.routePath,
    previousRouteData?.routeId,
    newRouteChangeType,
    routeDuration,
  );
}
