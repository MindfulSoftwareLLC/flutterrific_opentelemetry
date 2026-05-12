// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutterrific_opentelemetry/src/semantics/flutter_semantics.dart';

part 'ui_logger_create.dart';

/// UILogger wraps the SDK [Logger] to provide Flutter-specific convenience
/// methods for emitting structured log events in Flutter applications.
///
/// In addition to the standard OTel Logger methods (emit, trace, debug, info,
/// warn, error, fatal), UILogger provides Flutter-specific methods for emitting
/// structured events following OTel client instrumentation semantics:
///
/// - [emitEvent] — emit a structured OTel Event (log with EventName)
/// - [emitFlutterError] — emit a [FlutterErrorDetails] as an ERROR log
/// - [emitLifecycleEvent] — emit an app lifecycle state change
/// - [emitNavigationEvent] — emit a navigation/route change
///
/// You do not create this directly; obtain one via [FlutterOTel.logger()] or
/// [UILoggerProvider.getLogger()].
///
/// Example:
/// ```dart
/// final logger = FlutterOTel.logger('my-feature');
/// logger.info('Feature loaded');
/// logger.emitEvent('user.action', body: 'Button tapped',
///   attributes: {'button.id': 'submit'}.toAttributes());
/// ```
class UILogger implements OTelLogger {
  final OTelLogger _delegate;

  UILogger._({required OTelLogger delegate}) : _delegate = delegate;

  // -- Delegate standard Logger interface --

  @override
  String get name => _delegate.name;

  @override
  String? get version => _delegate.version;

  @override
  String? get schemaUrl => _delegate.schemaUrl;

  @override
  Attributes? get attributes => _delegate.attributes;

  @override
  bool get enabled => _delegate.enabled;

  @override
  LoggerProvider get provider => _delegate.provider;

  @override
  Resource? get resource => _delegate.resource;

  @override
  void emit({
    DateTime? timeStamp,
    DateTime? observedTimestamp,
    Context? context,
    Severity? severityNumber,
    String? severityText,
    dynamic body,
    Attributes? attributes,
    String? eventName,
  }) {
    _delegate.emit(
      timeStamp: timeStamp,
      observedTimestamp: observedTimestamp,
      context: context,
      severityNumber: severityNumber,
      severityText: severityText,
      body: body,
      attributes: attributes,
      eventName: eventName,
    );
  }

  @override
  void trace(dynamic body, {Attributes? attributes, String? eventName}) =>
      _delegate.trace(body, attributes: attributes, eventName: eventName);

  @override
  void debug(dynamic body, {Attributes? attributes, String? eventName}) =>
      _delegate.debug(body, attributes: attributes, eventName: eventName);

  @override
  void info(dynamic body, {Attributes? attributes, String? eventName}) =>
      _delegate.info(body, attributes: attributes, eventName: eventName);

  @override
  void warn(dynamic body, {Attributes? attributes, String? eventName}) =>
      _delegate.warn(body, attributes: attributes, eventName: eventName);

  @override
  void error(dynamic body, {Attributes? attributes, String? eventName}) =>
      _delegate.error(body, attributes: attributes, eventName: eventName);

  @override
  void fatal(dynamic body, {Attributes? attributes, String? eventName}) =>
      _delegate.fatal(body, attributes: attributes, eventName: eventName);

  // -- Flutter-specific convenience methods --

  /// Emits a structured OTel Event (a log record with an EventName).
  ///
  /// Events are the recommended way to emit structured telemetry in the
  /// emerging OTel client instrumentation standard. The [eventName] uniquely
  /// identifies the event class/type (e.g. 'user.click', 'feature.loaded').
  ///
  /// [body] is the log message body (optional).
  /// [attributes] are structured key-value attributes for the event.
  /// [severity] defaults to [Severity.INFO].
  void emitEvent(
    String eventName, {
    dynamic body,
    Attributes? attributes,
    Severity severity = Severity.INFO,
  }) {
    emit(
      severityNumber: severity,
      severityText: severity.name,
      body: body,
      attributes: attributes,
      eventName: eventName,
    );
  }

  /// Emits a [FlutterErrorDetails] as an ERROR-level OTel log record.
  ///
  /// This captures the exception type, message, stack trace, and widget
  /// context from Flutter's error reporting system.
  ///
  /// Example:
  /// ```dart
  /// FlutterError.onError = (details) {
  ///   FlutterOTel.logger().emitFlutterError(details);
  /// };
  /// ```
  void emitFlutterError(FlutterErrorDetails details) {
    final errorType = details.exception.runtimeType.toString();
    final errorMessage = details.exception.toString();
    final widgetContext = details.context?.toString();
    final stackTrace = details.stack?.toString();

    final attrs = <String, Object>{
      ErrorSemantics.errorType.key: errorType,
      ErrorSemantics.errorMessage.key: errorMessage,
      if (widgetContext != null)
        FlutterErrorSemantics.errorWidgetContext.key: widgetContext,
      if (stackTrace != null)
        ExceptionResource.exceptionStacktrace.key: stackTrace,
    };

    emit(
      severityNumber: Severity.ERROR,
      severityText: 'ERROR',
      body: 'Flutter error: $errorMessage',
      attributes: attrs.toAttributes(),
      eventName: FlutterEventNames.appError.key,
    );
  }

  /// Emits an app lifecycle state change as a structured OTel Event.
  ///
  /// [newState] is the lifecycle state name (e.g. 'resumed', 'paused').
  /// [previousState] is the previous state name, if any.
  /// [duration] is how long the previous state lasted, if known.
  void emitLifecycleEvent(
    String newState, {
    String? previousState,
    Duration? duration,
  }) {
    final attrs = <String, Object>{
      AppLifecycleSemantics.appLifecycleState.key: newState,
      if (previousState != null)
        AppLifecycleSemantics.appLifecyclePreviousState.key: previousState,
      if (duration != null)
        AppLifecycleSemantics.appLifecycleDuration.key: duration.inMilliseconds,
    };

    emitEvent(
      FlutterEventNames.appLifecycle.key,
      body: 'App lifecycle: $newState',
      attributes: attrs.toAttributes(),
    );
  }

  /// Emits a navigation/route change as a structured OTel Event.
  ///
  /// [toRoute] is the destination route name.
  /// [fromRoute] is the source route name, if any.
  /// [action] is the navigation action (push, pop, replace, remove).
  void emitNavigationEvent(
    String toRoute, {
    String? fromRoute,
    String? action,
  }) {
    final attrs = <String, Object>{
      NavigationSemantics.routeName.key: toRoute,
      if (fromRoute != null)
        NavigationSemantics.previousRouteName.key: fromRoute,
      if (action != null) NavigationSemantics.navigationAction.key: action,
    };

    emitEvent(
      FlutterEventNames.navigation.key,
      body: 'Navigation: ${fromRoute ?? '(none)'} -> $toRoute',
      attributes: attrs.toAttributes(),
    );
  }
}
