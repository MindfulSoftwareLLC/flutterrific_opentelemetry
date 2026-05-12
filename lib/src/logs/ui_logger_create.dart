// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

part of 'ui_logger.dart';

/// Factory for creating [UILogger] instances.
class UILoggerCreate {
  static UILogger create({required OTelLogger delegate}) {
    return UILogger._(delegate: delegate);
  }
}
