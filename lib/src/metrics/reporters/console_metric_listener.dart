// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:flutter/widgets.dart';
import 'metric_listener_base.dart';

class ConsoleMetricListener implements MetricListenerBase {
  @override
  void onPerformanceMetric({
    required String name,
    required Duration duration,
    Map<String, dynamic>? attributes,
  }) {
    debugPrint('📊 Performance Metric: $name');
    debugPrint('⏱️ Duration: ${duration.inMilliseconds}ms');
    if (attributes != null) {
      debugPrint('📝 Attributes: $attributes');
    }
    debugPrint('---');
  }

  @override
  void onError({
    required String error,
    StackTrace? stackTrace,
    Map<String, dynamic>? attributes,
  }) {
    debugPrint('❌ Error: $error');
    if (stackTrace != null) {
      debugPrint('📚 Stack Trace: $stackTrace');
    }
    if (attributes != null) {
      debugPrint('📝 Attributes: $attributes');
    }
    debugPrint('---');
  }

  @override
  void onUserInteraction({
    required String screenName,
    required String actionType,
    Map<String, dynamic>? attributes,
  }) {
    debugPrint('👆 User Interaction - Screen: $screenName, Action: $actionType');
    if (attributes != null) {
      debugPrint('📝 Attributes: $attributes');
    }
    debugPrint('---');
  }

  @override
  void reportNavigationChange(Route<dynamic>? route, Route<dynamic>? previousRoute) {
    debugPrint('🔄 Navigation Change');
    debugPrint('📍 From: ${previousRoute?.settings.name ?? 'unknown'}');
    debugPrint('📍 To: ${route?.settings.name ?? 'unknown'}');
    debugPrint('---');
  }
}
