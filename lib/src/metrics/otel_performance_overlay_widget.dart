// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:flutter/material.dart';
import 'flutter_metric_reporter.dart';

class OTelPerformanceOverlayWidget extends StatefulWidget {
  final Widget child;
  final String componentName;

  const OTelPerformanceOverlayWidget({
    super.key,
    required this.child,
    required this.componentName,
  });

  @override
  State<OTelPerformanceOverlayWidget> createState() => _OTelPerformanceOverlayWidgetState();
}

class _OTelPerformanceOverlayWidgetState extends State<OTelPerformanceOverlayWidget> {
  late DateTime _buildStartTime;

  @override
  void initState() {
    super.initState();
    _buildStartTime = DateTime.now();
  }

  @override
  void didUpdateWidget(OTelPerformanceOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _buildStartTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final buildDuration = DateTime.now().difference(_buildStartTime);
      FlutterMetricReporter().reportPerformanceMetric(
        'component_build_time',
        buildDuration,
        attributes: {'component_name': widget.componentName},
      );
    });

    return widget.child;
  }
}
