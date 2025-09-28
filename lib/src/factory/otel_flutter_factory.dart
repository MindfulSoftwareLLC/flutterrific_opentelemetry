// Licensed under the Apache License, Version 2.0
// Copyright 2025, Michael Bushe, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import '../metrics/ui_meter_provider.dart';
import '../trace/ui_tracer_provider.dart';

OTelFlutterFactory otelFlutterFactoryFactoryFunction({
  required String apiEndpoint,
  required String apiServiceName,
  required String apiServiceVersion,
}) {
  return OTelFlutterFactory(
    apiEndpoint: apiEndpoint,
    apiServiceName: apiServiceName,
    apiServiceVersion: apiServiceVersion,
  );
}

/// The factory used when no SDK is installed. The OpenTelemetry specification
/// requires the API to work without an SDK installed
/// All construction APIs use the factory, such as builders or 'from' helpers.
class OTelFlutterFactory extends OTelSDKFactory {
  OTelFlutterFactory({
    required super.apiEndpoint,
    required super.apiServiceName,
    required super.apiServiceVersion,
  }) : super(factoryFactory: otelFlutterFactoryFactoryFunction);

  @override
  UITracerProvider tracerProvider({
    required String endpoint,
    String serviceName = "@dart/opentelemetry_api",
    String? serviceVersion,
    Resource? resource,
  }) {
    return UITracerProviderCreate.create(
      delegate:
          super.tracerProvider(
                endpoint: endpoint,
                serviceVersion: serviceVersion,
                serviceName: serviceName,
                resource: resource,
              )
              as TracerProvider,
    );
  }

  @override
  UIMeterProvider meterProvider({
    required String endpoint,
    String serviceName = "@dart/opentelemetry_api",
    String? serviceVersion,
    Resource? resource,
  }) {
    return UIMeterProviderCreate.create(
      super.meterProvider(
            endpoint: endpoint,
            serviceVersion: serviceVersion,
            serviceName: serviceName,
            resource: resource,
          )
          as MeterProvider,
    );
  }
}
