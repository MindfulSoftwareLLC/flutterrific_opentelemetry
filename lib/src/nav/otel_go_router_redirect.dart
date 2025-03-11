// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart' as sdk;
import './nav_util.dart';
import 'otel_route_data.dart';

/// A wrapper for a GoRouter redirect function that performs
/// OTel instrumentation.
/// Use it by wrapping your redirect:
/// ```
///String? _handleRedirect(BuildContext context, GoRouterState state) {
///  ... your redirect logic...
//   return null; // don't redirect
// }
/// final goRouter = GoRouter(
//   redirect: OTelGoRouterRedirect(_handleRedirect), // your go_router redirect
//   // ... other configuration ...
// );
/// ```
class OTelGoRouterRedirect {
  /// The original (delegate) redirect function supplied by the app.
  final GoRouterRedirect wrappedRedirect;
  OTelRouteData? currentOTelRouteData;

  OTelGoRouterRedirect(this.wrappedRedirect);

  Future<String?> callRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    // Extract the current path from the GoRouter state.
    final String currentPath = state.uri.path;

    // Here you can insert any OTel instrumentation code,
    // e.g., record a span or log the current route.
    // For example:
    // OTelTracer.recordRoutePath(currentPath);

    // Delegate to the original redirect function.
    final String? redirectPath = await wrappedRedirect(context, state);
    final newOtelRouteData = _routeDataForGoRouterState(state);
    if (redirectPath == null) {
      recordNavigationChange(
        newOtelRouteData,
        currentOTelRouteData,
        sdk.NavigationAction.redirect, //TODO - not exactly
      );
      currentOTelRouteData = newOtelRouteData;
    } else {
      // FlutterOTel.tracer.recordRedirectDecision(redirectPath);
    }
    return redirectPath;
  }

  OTelRouteData _routeDataForGoRouterState(GoRouterState state) {
    return OTelRouteData(
      routeName: state.name ?? state.uri.toString(),
      routePath: state.fullPath ?? state.path ?? state.uri.toString(),
      routeArguments: state.pathParameters.toString(),
      routeKey: state.pageKey.value,
      //TODO extra, error
    );
  }
}
