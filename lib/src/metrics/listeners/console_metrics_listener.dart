// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:flutter/foundation.dart';
import '../trackers/page_tracker.dart';
import '../trackers/paint_tracker.dart';
import '../trackers/shift_tracker.dart';
import '../trackers/apdex_tracker.dart';
import '../trackers/user_input_tracker.dart';
import '../trackers/error_tracker.dart';
import '../flutter_metric_reporter.dart';

class ConsoleMetricsListener {
  static final ConsoleMetricsListener _instance = ConsoleMetricsListener._internal();
  factory ConsoleMetricsListener() => _instance;

  late final PageTracker _pageTracker;
  late final PaintTracker _paintTracker;
  late final ShiftTracker _shiftTracker;
  late final ApdexTracker _apdexTracker;
  late final UserInputTracker _userInputTracker;
  late final ErrorTracker _errorTracker;

  ConsoleMetricsListener._internal() {
    _initializeTrackers();
    _setupListeners();
  }

  void _initializeTrackers() {
    _pageTracker = PageTracker();
    _paintTracker = PaintTracker();
    _shiftTracker = ShiftTracker();
    _apdexTracker = ApdexTracker();
    _userInputTracker = UserInputTracker();
    _errorTracker = ErrorTracker();
  }

  void _setupListeners() {
    _pageTracker.addListener(_handlePageMetric);
    _paintTracker.addListener(_handlePaintMetric);
    _shiftTracker.addListener(_handleShiftMetric);
    _apdexTracker.addListener(_handleApdexUpdate);
    _userInputTracker.addListener(_handleUserInteraction);
    _errorTracker.addListener(_handleError);
  }

  void _handlePageMetric(PageLoadMetric metric) {
    debugPrint('\n📱 Page Load Metric:');
    debugPrint('  Page: ${metric.pageName}');
    debugPrint('  Load Time: ${_formatDuration(metric.loadTime)}');
    if (metric.transitionType != null) {
      debugPrint('  Transition: ${metric.transitionType}');
    }
    if (metric.attributes != null) {
      debugPrint('  Additional Data:');
      metric.attributes!.forEach((key, value) {
        debugPrint('    $key: $value');
      });
    }
    _printTimestamp(metric.timestamp);
  }

  void _handlePaintMetric(PaintMetric metric) {
    debugPrint('\n🎨 Paint Metric:');
    debugPrint('  Component: ${metric.componentName}');
    debugPrint('  Type: ${metric.paintType}');
    debugPrint('  Duration: ${_formatDuration(metric.paintDuration)}');
    if (metric.attributes != null) {
      debugPrint('  Details:');
      metric.attributes!.forEach((key, value) {
        debugPrint('    $key: $value');
      });
    }
    _printTimestamp(metric.timestamp);
  }

  void _handleShiftMetric(LayoutShiftMetric metric) {
    debugPrint('\n📐 Layout Shift:');
    debugPrint('  Component: ${metric.componentName}');
    debugPrint('  Score: ${metric.shiftScore.toStringAsFixed(4)}');
    if (metric.cause != null) {
      debugPrint('  Cause: ${metric.cause}');
    }
    if (metric.attributes != null) {
      debugPrint('  Context:');
      metric.attributes!.forEach((key, value) {
        debugPrint('    $key: $value');
      });
    }
    _printTimestamp(metric.timestamp);
  }

  void _handleApdexUpdate(String component, double score, Duration period) {
    debugPrint('\n📊 Apdex Score Update:');
    debugPrint('  Component: $component');
    debugPrint('  Score: ${score.toStringAsFixed(2)}');
    debugPrint('  Period: ${_formatDuration(period)}');

    final result = _apdexTracker.calculateApdexScore(component);
    if (result != null) {
      debugPrint('  Details:');
      debugPrint('    Satisfied: ${result.satisfiedCount}');
      debugPrint('    Tolerating: ${result.toleratingCount}');
      debugPrint('    Frustrating: ${result.frustratingCount}');
    }
    _printTimestamp(DateTime.now());
  }

  void _handleUserInteraction(UserInteractionMetric metric) {
    debugPrint('\n👆 User Interaction:');
    debugPrint('  Screen: ${metric.screenName}');
    debugPrint('  Action: ${metric.actionType}');
    if (metric.responseTime != null) {
      debugPrint('  Response Time: ${_formatDuration(metric.responseTime!)}');
    }
    if (metric.attributes != null) {
      debugPrint('  Context:');
      metric.attributes!.forEach((key, value) {
        debugPrint('    $key: $value');
      });
    }
    _printTimestamp(metric.timestamp);
  }

  void _handleError(ErrorMetric metric) {
    debugPrint('\n❌ Error:');
    debugPrint('  Message: ${metric.error}');
    if (metric.stackTrace != null) {
      debugPrint('  Stack Trace:');
      debugPrint('    ${metric.stackTrace.toString().split('\n').take(3).join('\n    ')}');
    }
    if (metric.attributes != null) {
      debugPrint('  Context:');
      metric.attributes!.forEach((key, value) {
        debugPrint('    $key: $value');
      });
    }
    _printTimestamp(metric.timestamp);

    // Print error rate information if available
    final errorType = metric.attributes?['error_type'];
    if (errorType != null) {
      try {
        final summary = _errorTracker.getErrorSummary(errorType.toString());
        debugPrint('  Error Summary:');
        debugPrint('    Occurrences: ${summary.occurrences}');
        debugPrint('    Affected Components: ${summary.affectedComponents.join(', ')}');
      } catch (_) {
        // Summary not available yet
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1) {
      return '${duration.inMicroseconds}µs';
    }
    if (duration.inSeconds < 1) {
      return '${duration.inMilliseconds}ms';
    }
    return '${duration.inSeconds}s ${duration.inMilliseconds % 1000}ms';
  }

  void _printTimestamp(DateTime timestamp) {
    debugPrint('  Timestamp: ${timestamp.toIso8601String()}');
    debugPrint('  ${'-' * 50}');
  }

  void dispose() {
    _pageTracker.removeListener(_handlePageMetric);
    _paintTracker.removeListener(_handlePaintMetric);
    _shiftTracker.removeListener(_handleShiftMetric);
    _apdexTracker.removeListener(_handleApdexUpdate);
    _userInputTracker.removeListener(_handleUserInteraction);
    _errorTracker.removeListener(_handleError);
  }
}
