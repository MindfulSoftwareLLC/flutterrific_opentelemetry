# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0-wip]

### Changed
- **Bumped `dartastic_opentelemetry` to `^1.1.0-beta.4` and `dartastic_opentelemetry_api` to `^1.0.0-beta.6`.** Picks up:
  - Late-binding global proxies on `OTel.tracer()` / `OTel.tracerProvider()` / `OTel.loggerProvider()` / `OTel.logger()`, so a reference captured at module load survives a later `OTel.initialize`. This is the foundation `FlutterOTel` already assumes for its observers and tracker singletons.
  - Web compatibility for the SDK's main library (Flutter web, dart2js, dart2wasm) without `dart:io` import-time crashes.
  - Sub-millisecond span timing on web via the platform-aware `WebTimeProvider` default.
  - OTLP/HTTP-JSON wire format on every signal.
  - Beta.6 semantic-convention rename: `HttpResource` → `Http`, `UrlResource` → `Url`, `UserSemantics` → `User`, etc. Six enums kept the `Resource` suffix to avoid Dart/Flutter/library type conflicts: `ErrorResource`, `ExceptionResource`, `FileResource`, `ProcessResource`, `ServerResource`, `EventResource`. `SessionViewSemantics` was split — OTel-spec session keys (`session.id`, `session.previous_id`) live on `Session`; the Datadog/Dynatrace-style RUM view keys live on `RumSessionView`.
- **Breaking (re-export surface):** the renames above flow through `lib/flutterrific_opentelemetry.dart`'s `show` clauses. Code that imported via `package:flutterrific_opentelemetry/...` needs the same find/replace as code importing the API directly. The `lib/src/flutterrific_otel.dart` internal use of `SessionViewSemantics.viewName` was migrated to `RumSessionView.viewName`.
- `Tracer.recordSpan` / `recordSpanAsync` overrides removed from `UITracer` — these methods no longer exist on the parent (removed in SDK 0.8.3 as redundant with `startActiveSpan` / `startActiveSpanAsync`). Existing callers should rewrite `tracer.recordSpan(name: x, fn: f)` to `tracer.startActiveSpan(name: x, fn: (_) => f())`.
- `UITracer` / `UITracerProvider` now expose the `timeProvider` getter/setter added in SDK 1.1.0-beta.2. Auto-selects `WebTimeProvider` on web (sub-ms via `window.performance.now()`), `SystemTimeProvider` on native.
- `UILogger` / `UILoggerCreate` now wrap `OTelLogger` (the SDK renamed `Logger` → `OTelLogger` to avoid clashing with `package:logging`'s `Logger`).
- Adopted the SDK's `-wip` release flow: working `pubspec.yaml` version always ends in `-wip`, CHANGELOG work-in-progress lands under `## [X.Y.Z-wip]`. `dart run tool/release.dart` cuts the release.
- `example/lib/main.dart` `_simulateNetworkRequest` now wraps the awaited work in `tracer.withSpanAsync(span, () async { ... })` so the span is active for the duration of the `await` — nested instrumentation that reads `Context.current.span` sees this span as its parent. The previous shape (start span → await → end span) recorded the timing fine but left the span inactive during the awaited work.

### Removed
- **Breaking: `UITracer.startSpanWithContext` removed.** Mirrors the removal in `dartastic_opentelemetry` 1.1.0-beta.5 (deprecated since SDK 1.1.0-beta). Migration: `tracer.startSpanWithContext(name: x, context: ctx, ...)` → `tracer.startSpan(x, context: ctx, ...)`. To make the returned span active for a scope, wrap the work with `tracer.withSpan` (sync) or `tracer.withSpanAsync` (async).

### Added
- `tool/release.dart` — ported from `dartastic_opentelemetry/tool/release.dart`, adapted for Flutter (`flutter pub` / `flutter analyze` / `flutter test`). Strips `-wip`, dates the CHANGELOG section, tags `vX.Y.Z`, optionally `dart pub publish`es and creates a GitHub release via `gh release create`. See PUBLICATION_CHECKLIST.md for the full flow.
- `tool/update_coverage_badge.sh` — reads `coverage/lcov.info` and rewrites the README coverage badge line in place.
- README coverage badge — currently honest about the gap (low). Coverage gating before the next stable release is documented in PUBLICATION_CHECKLIST.md.
- README "Client OpenTelemetry" section comparing Flutterrific's current event/attribute shapes to the in-development OTel client semantic conventions (`device.app.lifecycle`, `app.screen.click`, `browser.web_vital`, etc.) so consumers know which keys are spec-aligned today and which are RUM-style placeholders.

## 0.4.0 2026/04/05

* **Log Signal support**: Added OpenTelemetry Log Signal integration for Flutter
  * UILogger — Flutter-specific Logger wrapper with convenience methods:
    emitEvent, emitFlutterError, emitLifecycleEvent, emitNavigationEvent
  * UILoggerProvider — Flutter-specific LoggerProvider wrapper
  * OTelFlutterFactory overrides loggerProvider for Flutter-specific wrapping
  * FlutterOTel.initialize() now accepts log configuration parameters:
    enableLogs, logRecordExporter, logRecordProcessor, logPrint,
    logPrintLoggerName, enableAutoLogEvents
  * FlutterOTel.logger() and FlutterOTel.loggerProvider static accessors
  * Auto-emits structured OTel log events for lifecycle changes, navigation,
    and errors (opt-out via enableAutoLogEvents: false)
  * Platform-specific log exporters: HTTP for web, gRPC for native
  * Re-exports all dartastic log types for convenience
* Upgraded to dartastic_opentelemetry ^1.0.1-alpha / API ^1.0.0-alpha

## 0.3.4 2025/10/11

* Updated to Dartastic SDK 0.9.2 / API 0.8.8, supports standard env vars and gets OTelLog fixes

## 0.3.3 2025/09/29

* Fixed issues with grpc processor creation, updated to Dartastic 0.8.7

## 0.3.2 2025/06/22

* Doc only, wondrous demo will only live in github, not pub.dev

## 0.3.1 2025/06/17

* Works with Wondrous demo, Dartastic 0.8.6

## 0.3.0

* Initial release
