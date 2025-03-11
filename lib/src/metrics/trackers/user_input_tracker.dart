// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'dart:async';
import '../flutter_metric_reporter.dart';

typedef InputMetricListener = void Function(UserInteractionMetric metric);

class InteractionResult {
  final String screenName;
  final String actionType;
  final Duration responseTime;
  final Duration processingTime;
  final Duration totalTime;
  final DateTime timestamp;
  final Map<String, dynamic>? attributes;

  InteractionResult({
    required this.screenName,
    required this.actionType,
    required this.responseTime,
    required this.processingTime,
    required this.totalTime,
    required this.timestamp,
    this.attributes,
  });
}

class UserInputTracker {
  static final UserInputTracker _instance = UserInputTracker._internal();
  factory UserInputTracker() => _instance;

  final Map<String, Duration> _firstInputDelays = {};
  final Map<String, List<InteractionResult>> _interactionHistory = {};
  final List<InputMetricListener> _listeners = [];

  // Track ongoing interactions for correlation with performance metrics
  final Map<String, DateTime> _pendingInteractions = {};

  late final StreamSubscription<UserInteractionMetric> _interactionSubscription;
  late final StreamSubscription<PerformanceMetric> _performanceSubscription;
  late final FlutterMetricReporter _reporter;

  UserInputTracker._internal() {
    _reporter = FlutterMetricReporter();

    _interactionSubscription = _reporter.interactionStream.listen((metric) {
      final key = '${metric.screenName}.${metric.actionType}';

      // Record first input delay for each screen
      if (!_firstInputDelays.containsKey(metric.screenName)) {
        _firstInputDelays[metric.screenName] = metric.responseTime ?? Duration.zero;
      }

      // Start tracking this interaction
      _pendingInteractions[key] = metric.timestamp;

      _processInteractionMetric(metric);
      _notifyListeners(metric);
    });

    _performanceSubscription = _reporter.performanceStream.listen((metric) {
      // Correlate performance metrics with pending interactions
      final componentName = metric.attributes?['component_name'] as String?;
      final actionType = metric.attributes?['action_type'] as String?;

      if (componentName != null && actionType != null) {
        final key = '$componentName.$actionType';
        final interactionStart = _pendingInteractions[key];

        if (interactionStart != null) {
          final responseTime = metric.attributes?['response_time'] != null ?
              Duration(milliseconds: metric.attributes!['response_time'] as int) :
              Duration.zero;

          final result = InteractionResult(
            screenName: componentName,
            actionType: actionType,
            responseTime: responseTime,
            processingTime: metric.duration,
            totalTime: metric.duration + responseTime,
            timestamp: metric.timestamp,
            attributes: metric.attributes,
          );

          _recordInteractionResult(result);
          _pendingInteractions.remove(key);
        }
      }
    });
  }

  void _processInteractionMetric(UserInteractionMetric metric) {
    final key = metric.screenName;
    if (!_interactionHistory.containsKey(key)) {
      _interactionHistory[key] = [];
    }
  }

  void _recordInteractionResult(InteractionResult result) {
    if (!_interactionHistory.containsKey(result.screenName)) {
      _interactionHistory[result.screenName] = [];
    }
    _interactionHistory[result.screenName]!.add(result);
  }

  Duration? getFirstInputDelay(String screenName) {
    return _firstInputDelays[screenName];
  }

  Map<String, Duration> getAllFirstInputDelays() {
    return Map.unmodifiable(_firstInputDelays);
  }

  List<InteractionResult>? getInteractionHistory(String screenName) {
    return _interactionHistory[screenName]?.toList();
  }

  Duration? getAverageInteractionTime(String screenName) {
    final interactions = _interactionHistory[screenName];
    if (interactions == null || interactions.isEmpty) return null;

    final total = interactions.fold<Duration>(
      Duration.zero,
      (sum, interaction) => sum + interaction.totalTime,
    );

    return Duration(microseconds: total.inMicroseconds ~/ interactions.length);
  }

  InteractionResult? getLongestInteraction(String screenName) {
    return _interactionHistory[screenName]?.reduce(
      (a, b) => a.totalTime > b.totalTime ? a : b,
    );
  }

  void addListener(InputMetricListener listener) {
    _listeners.add(listener);
  }

  void removeListener(InputMetricListener listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(UserInteractionMetric metric) {
    for (final listener in _listeners) {
      listener(metric);
    }
  }

  void dispose() {
    _interactionSubscription.cancel();
    _performanceSubscription.cancel();
    _listeners.clear();
  }
}
