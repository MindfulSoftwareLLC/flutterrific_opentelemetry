// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:flutter/material.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import '../flutterrific_otel.dart';
import 'ui_tracer.dart';

/// Tracks user interactions with UI elements and creates spans automatically.
class OTelInteractionTracker {
  final UITracer? _tracer;

  /// Creates a new OTelInteractionTracker
  OTelInteractionTracker({UITracer? uiTracer}) : _tracer = uiTracer;

  UITracer get tracer => _tracer ?? FlutterOTel.tracer;

  /// Track a button click
  void trackButtonClick(BuildContext context, String buttonId) {
    if (!tracer.enabled) return;

    final routeName = _getRouteName(context);
    tracer.recordUserInteraction(
      routeName,
      InteractionType.click,
      targetName: buttonId,
    );
  }

  /// Track a text input
  void trackTextInput(BuildContext context, String inputId) {
    if (!tracer.enabled) return;

    final routeName = _getRouteName(context);
    tracer.recordUserInteraction(
      routeName,
      InteractionType.textInput,
      targetName: inputId,
    );
  }

  /// Track a list item selection
  void trackListItemSelected(BuildContext context, String listId, int index) {
    if (!tracer.enabled) return;

    final routeName = _getRouteName(context);
    tracer.recordUserInteraction(
      routeName,
      InteractionType.listSelection,
      targetName: listId,
      attributes:
          {InteractionType.listSelectionIndex.key: index}.toAttributes(),
    );
  }

  /// Track a drag gesture
  void trackDragGesture(BuildContext context, String elementId, Offset delta) {
    if (!tracer.enabled) return;

    final routeName = _getRouteName(context);
    tracer.recordUserInteraction(
      routeName,
      InteractionType.drag,
      targetName: elementId,
      attributes:
          {
            InteractionType.gestureDeltaX.key: delta.dx,
            InteractionType.gestureDeltaY.key: delta.dy,
          }.toAttributes(),
    );
  }

  /// Track a swipe gesture
  void trackSwipeGesture(
    BuildContext context,
    String elementId,
    String direction,
  ) {
    if (!tracer.enabled) return;

    final routeName = _getRouteName(context);
    tracer.recordUserInteraction(
      routeName,
      InteractionType.swipe,
      targetName: elementId,
      attributes:
          {InteractionType.gestureDirection.key: direction}.toAttributes(),
    );
  }

  /// Track a long press gesture
  void trackLongPress(BuildContext context, String elementId) {
    if (!tracer.enabled) return;

    final routeName = _getRouteName(context);
    tracer.recordUserInteraction(
      routeName,
      InteractionType.longPress,
      targetName: elementId,
    );
  }

  /// Track a scroll event
  void trackScroll(BuildContext context, String scrollableId, double position) {
    if (!tracer.enabled) return;

    final routeName = _getRouteName(context);
    tracer.recordUserInteraction(
      routeName,
      InteractionType.scroll,
      targetName: scrollableId,
      attributes: {'scroll.position': position}.toAttributes(),
    );
  }

  /// Track form submission
  void trackFormSubmit(BuildContext context, String formId) {
    if (!tracer.enabled) return;

    final routeName = _getRouteName(context);
    tracer.recordUserInteraction(
      routeName,
      InteractionType.formSubmit,
      targetName: formId,
    );
  }

  /// Track dropdown/menu selection
  void trackMenuSelection(
    BuildContext context,
    String menuId,
    String selection,
  ) {
    if (!tracer.enabled) return;

    final routeName = _getRouteName(context);
    tracer.recordUserInteraction(
      routeName,
      InteractionType.menuSelect,
      targetName: menuId,
      attributes:
          {InteractionType.menuSelectedItem.key: selection}.toAttributes(),
    );
  }

  /// Helper to get current route name from context
  String _getRouteName(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route != null && route.settings.name != null) {
      return route.settings.name!;
    }
    return 'unknown_route';
  }
}

/// Extension to add OpenTelemetry tracking to common Flutter widgets
extension OTelTrackingExtensions on Widget {
  /// Adds OpenTelemetry tracking to a button
  Widget withOTelButtonTracking(String buttonId) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            final tracker = OTelInteractionTracker(
              uiTracer: FlutterOTel.tracer,
            );
            tracker.trackButtonClick(context, buttonId);
          },
          child: this,
        );
      },
    );
  }

  /// Adds OpenTelemetry tracking to a TextField
  Widget withOTelTextFieldTracking(String fieldId) {
    return Builder(
      builder: (context) {
        return Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              final tracker = OTelInteractionTracker(
                uiTracer: FlutterOTel.tracer,
              );
              tracker.trackTextInput(context, fieldId);
            }
          },
          child: this,
        );
      },
    );
  }
}
