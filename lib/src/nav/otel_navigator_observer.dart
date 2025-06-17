// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:flutter/widgets.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import '../../flutterrific_opentelemetry.dart';
import './nav_util.dart';
import 'otel_route_data.dart';

/// Observer for route changes in Flutter navigation
class OTelNavigatorObserver extends NavigatorObserver {
  /// a spanId equivalent for a route
  OTelRouteData? currentRouteData;

  OTelNavigatorObserver();

  void _routeChanged({
    required Route? newRoute,
    required Route? previousRoute,
    required NavigationAction newRouteChangeType,
  }) {
    OTelRouteData newOTelRouteData =
        newRoute == null ? OTelRouteData.empty() : _routeDataForRoute(newRoute);
    recordNavigationChange(
      newOTelRouteData,
      currentRouteData,
      newRouteChangeType
    );
    currentRouteData = newOTelRouteData;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeChanged(
      newRoute: route,
      previousRoute: previousRoute,
      newRouteChangeType: NavigationAction.push,
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _routeChanged(
      newRoute: newRoute,
      previousRoute: oldRoute,
      newRouteChangeType: NavigationAction.replace,
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeChanged(
      newRoute: route,
      previousRoute: previousRoute,
      newRouteChangeType: NavigationAction.pop,
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeChanged(
      newRoute: route,
      previousRoute: previousRoute,
      newRouteChangeType: NavigationAction.remove,
    );
  }

  // /// Helper method for integrating with GoRouter redirect logic
  // String? handleRedirect(BuildContext context, String? fromPath, String? toPath) {
  //   if (fromPath != null && toPath != null && fromPath != toPath) {
  //     recordRedirect(fromPath, toPath, null);
  //   }
  //   return toPath;
  // }

  OTelRouteData _routeDataForRoute(Route route) {
    final String routeName =
        route.settings.name ?? route.navigator?.widget.toString() ?? "unknown";
    String routeArguments;
    if (route.settings.arguments == null) {
      routeArguments = 'none';
    } else {
      try {
        routeArguments = route.settings.arguments!.toString();
      } catch (e) {
        // Fallback if arguments do not contain a uri.
        routeArguments = 'failed toString()';
      }
    }

    var page = (route.settings as Page);
    LocalKey routeKey =
        route.settings is Page
            ? page.key ?? ValueKey(route.settings.name ?? 'unknown')
            : ValueKey(route.settings.name ?? 'unknown');
    String routePath = routeName; //fallback
    if (route.settings.arguments != null) {
      if (route.settings is Page && page.key is ValueKey) {
        routePath = (page.key as ValueKey).value;
      } else {
        try {
          final dynamic args = route.settings.arguments;
          final dynamic uri = args.uri;
          routePath = uri?.toString() ?? routeName;
        } catch (_) {}
      }
    }

    return OTelRouteData(
      routeSpanId: OTel.spanId(), //NB: Route SpanIds are generated here
      routeName: routeName,
      routePath: routePath,
      routeKey: routeKey.toString(),
      routeArguments: routeArguments,
    );
  }

  /*
  Consider:

  /// Extract route parameters from GoRouter or other routers
  Map<String, dynamic> _extractRouteParameters(Route<dynamic> route) {
    final parameters = <String, dynamic>{};

    // Try to extract from arguments
    final arguments = route.settings.arguments;
    if (arguments != null) {
      if (arguments is Map<String, dynamic>) {
        // Look for common parameter keys
        for (final key in ['params', 'parameters', 'queryParams', 'queryParameters', 'pathParameters']) {
          if (arguments.containsKey(key) && arguments[key] is Map) {
            parameters.addAll(Map<String, dynamic>.from(arguments[key] as Map));
          }
        }

        // For GoRouter's state object format
        if (arguments.containsKey('uri') && arguments['uri'] is Uri) {
          final uri = arguments['uri'] as Uri;
          parameters.addAll(uri.queryParameters);
        }
      }
    }

    return parameters;
  }

  String _capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  /// Updates all active routes with frame time metrics
  // void recordFrameTime(double frameTimeMs) {
  //   for (final span in _routeSpans.values) {
  //     span.setDoubleAttribute(PerformanceSemantics.frameTime.key, frameTimeMs);
  //   }
  // }

  /// Record a GoRouter redirect
  void recordRedirect(String fromPath, String toPath, Map<String, dynamic>? parameters) {
    // First check if we have an existing span for the fromPath
    final existingSpan = _goRouterPaths[fromPath];

    if (existingSpan != null) {
      // Add redirect information to the existing span
      existingSpan.setStringAttribute('redirect.to', toPath);
      existingSpan.setStringAttribute(NavigationSemantics.navigationAction.key, NavigationAction.redirect.value);
      if (parameters != null && parameters.isNotEmpty) {
        existingSpan.setStringAttribute(NavigationSemantics.routeParameters.key, parameters.toString());
      }
    } else {
      // Create a new span for the redirect
      final tracer = FlutterOTel.tracer;
      final lifecycleSpan = FlutterOTel.lifecycleObserver.getCurrentLifecycleSpan() ??
          FlutterOTel.lifecycleObserver.getAppSessionSpan();

      final attributes = <String, Object>{
        NavigationSemantics.navigationAction.key: NavigationAction.redirect.value,
        NavigationSemantics.routePath.key: fromPath,
        'redirect.to': toPath,
        RouteSemantics.lifecycleTimestamp.key: DateTime.now().millisecondsSinceEpoch,
      };

      if (parameters != null && parameters.isNotEmpty) {
        attributes[NavigationSemantics.routeParameters.key] = parameters.toString();
      }

      final span = tracer.startSpan(
        'ui.navigation.redirect',
        kind: SpanKind.client,
        attributes: sdk.OTel.attributesFromMap(attributes),
        parentSpan: lifecycleSpan,
      );

      // End the span immediately since redirect happens quickly
      span.end();
    }

    if (kDebugMode) {
      print('OTelRouteObserver: REDIRECT $fromPath → $toPath');
    }
  }
  /// Extract route path from GoRouter if available
  String _getRoutePath(Route<dynamic> route) {
    // Try to get GoRouter path from settings.name
    if (route.settings.name != null && route.settings.name!.isNotEmpty) {
      // GoRouter typically uses formats like "/home/settings" or "/product/123"
      if (route.settings.name!.startsWith('/')) {
        return route.settings.name!;
      }
    }

    // Try to extract from arguments
    final arguments = route.settings.arguments;
    if (arguments != null) {
      if (arguments is Map<String, dynamic>) {
        // Common keys for paths in different routing systems
        for (final key in ['path', 'fullPath', 'routePath', 'location', 'uri']) {
          if (arguments.containsKey(key) && arguments[key] is String) {
            return arguments[key] as String;
          }
        }
      }
    }

    // Try GoRouter specific extraction
    final goRouterPath = _extractGoRouterPath(route);
    if (goRouterPath != null) {
      return goRouterPath;
    }

    return '';
  }


  /// Extract GoRouter specific name
  String? _extractGoRouterName(Route<dynamic> route) {
    final arguments = route.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      // GoRouter stores state in the arguments
      if (arguments.containsKey('name')) {
        return arguments['name'] as String?;
      }

      // For GoRouter v5+ with RouteData
      if (arguments.containsKey('routeData')) {
        final routeData = arguments['routeData'];
        if (routeData is Map && routeData.containsKey('name')) {
          return routeData['name'] as String?;
        }
      }

      // Extract name from GoRouter path
      final path = _extractGoRouterPath(route);
      if (path != null && path.isNotEmpty) {
        // Convert path to name: "/home/settings" -> "HomeSettings"
        final segments = path.split('/')
            .where((s) => s.isNotEmpty)
            .map((s) => s.contains(':') ? s.split(':')[0] : s)
            .map(_capitalizeFirstLetter)
            .toList();
        if (segments.isNotEmpty) {
          return segments.join();
        }
      }
    }
    return null;
  }

  /// Extract GoRouter specific path
  String? _extractGoRouterPath(Route<dynamic> route) {
    final arguments = route.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      // GoRouter stores uri in the arguments
      if (arguments.containsKey('uri') && arguments['uri'] is Uri) {
        return (arguments['uri'] as Uri).path;
      }

      // For GoRouter with RouteData
      if (arguments.containsKey('routeData')) {
        final routeData = arguments['routeData'];
        if (routeData is Map && routeData.containsKey('path')) {
          return routeData['path'] as String?;
        }
      }

      // For older GoRouter versions
      if (arguments.containsKey('location')) {
        final location = arguments['location'] as String?;
        if (location != null) {
          final uri = Uri.tryParse(location);
          if (uri != null) {
            return uri.path;
          }
          return location;
        }
      }
    }
    return null;
  }

   */
}
