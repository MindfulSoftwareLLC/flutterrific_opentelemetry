# Publication Checklist

This document outlines the steps to follow when publishing a new
version of Flutterrific OpenTelemetry. Modeled on
[`dartastic_opentelemetry`'s checklist][sdk-checklist] — same `-wip`
release-script flow, with Flutter-specific additions for the
platform-build matrix.

[sdk-checklist]: https://github.com/MindfulSoftwareLLC/dartastic_opentelemetry/blob/main/PUBLICATION_CHECKLIST.md

## Pre-release Checklist

### Code Quality
- [ ] All tests are passing (`flutter test`)
- [ ] No lint warnings (`flutter analyze`)
- [ ] Code is properly formatted (`dart format .`)
- [ ] Package scores well on `pana` analysis (`flutter pub global run pana`)
- [ ] Example app builds and runs on the platforms you target
- [ ] Code coverage measured via `tool/coverage.sh` (writes `coverage/lcov.info`); badge refreshed via `tool/update_coverage_badge.sh`

Coverage target: aim for `>=85%` before any **stable** (non-beta) release. Pre-stable releases land with the actual coverage number in the README badge — honesty over greenwashing. See `ROADMAP.md` for the test-coverage roadmap toward the stable cut.

### Flutter-Specific Testing
Verify the package consumes cleanly on every target you intend to support:

- [ ] Android (`flutter build apk` in the example app)
- [ ] iOS (`flutter build ios --no-codesign`)
- [ ] Web (`flutter build web` — uses Dartastic's auto-selected `WebTimeProvider` for sub-millisecond timing)
- [ ] Desktop targets (`flutter build macos` / `linux` / `windows`) when applicable

Notes:
- Web target is the one most likely to surface regressions in the underlying SDK — Dartastic only declared its main library web-safe in `1.1.0-beta.1`. Verify span export works in a browser via the OTLP/HTTP-protobuf exporter (and OTLP/HTTP-JSON if your collector prefers that wire format — see SDK 1.1.0-beta.3).
- iOS / Android tests on real devices are required for any release that touches platform-resource detection, lifecycle observers, or `package:web` usage.

### Documentation
- [ ] CHANGELOG entries for this release land under the `## [X.Y.Z-wip]` section (the release script dates and re-headers it).
- [ ] `pubspec.yaml` version still ends in `-wip` — the release script strips it.
- [ ] README "Quick Start" and any code snippets use the typed-enum semconv shorthand (e.g. `OTel.attributesFromSemanticMap({Http.requestMethod: 'GET'})`) rather than raw strings.
- [ ] If this release moves a feature out of "experimental" status (notably any of the client-OTel namespaces — see README "Client OpenTelemetry" section), call that out explicitly in the CHANGELOG.

### Compatibility
- [ ] Breaking changes are documented in CHANGELOG with a one-line migration recipe.
- [ ] `dartastic_opentelemetry` / `dartastic_opentelemetry_api` constraints in `pubspec.yaml` match the versions exercised in the test run. If you depend on an unreleased Dartastic beta via a `dependency_overrides:` git ref, the SDK / API need to publish to pub.dev *before* this package can be released — pub.dev's resolver refuses git refs from published packages.
- [ ] Compatible with the [OpenTelemetry specification](https://opentelemetry.io/docs/specs/otel/) and its in-development client/RUM semantic conventions (see README "Client OpenTelemetry" for the comparison).
- [ ] Flutter SDK constraint in `pubspec.yaml` matches what was tested.

## Release Process

Flutterrific follows the Flutter / Dart team's `-wip` convention. The
working `pubspec.yaml` version always ends in `-wip` and CHANGELOG
entries land under a `## [X.Y.Z-wip]` section header during
development. `dart run tool/release.dart` performs the release.

1. **Prepare**
   - [ ] Working tree is clean and on `main` (or the release branch).
   - [ ] CHANGELOG `## [X.Y.Z-wip]` section reflects everything in this release.
   - [ ] `dart pub publish --dry-run` is clean.

2. **Cut + publish** — run `dart run tool/release.dart`. The script:
   - Strips `-wip` from `pubspec.yaml` and the CHANGELOG header, dates the section.
   - Runs `flutter pub get`, `flutter analyze`, `flutter test`.
   - Commits as `Release X.Y.Z` and tags `vX.Y.Z`.
   - Bumps `pubspec.yaml` to the next `-wip` (auto-bumps the rightmost numeric component, or pass `--next X.Y.Z` to override).
   - Inserts a fresh `## [X.Y.Z-wip]` CHANGELOG section.
   - Commits as `Bump to X.Y.Z-wip`.
   - Checks out the `vX.Y.Z` tag and runs `dart pub publish` so the working tree being published matches the release version. pub.dev's own `Do you want to publish ...?` prompt is the gate.
   - Returns the working tree to your branch on success.
   - (If `gh` CLI is installed and authenticated) pushes the branch + tag and creates a GitHub release from the matching CHANGELOG section.

   Flags:
   - `--yes` — non-interactive confirm
   - `--no-publish` — local commits + tag only, no pub.dev push
   - `--skip-tests` — skip `flutter test` (useful when CI already verified)
   - `--no-github-release` — skip the gh release step
   - `--next X.Y.Z` — override the auto-bumped next dev version

3. **Verify** (after `dart pub publish` succeeds):
   - [ ] Package shows on pub.dev within ~1 minute.
   - [ ] pub.dev's analyzer score is acceptable (warnings on the rendered page are common but should not be net-new errors).
   - [ ] Example app `flutter pub get` resolves the new version on a fresh clone.

4. **Post-release**
   - [ ] If this release is consumed by downstream projects (Dartastic sample apps, etc.), open follow-up PRs to bump them.
   - [ ] Announce in Flutter community channels for any user-facing wins (web support, new auto-instrumentation, etc.).
   - [ ] If migration is required, link the relevant CHANGELOG section in the release notes.

## Flutter-Specific Considerations

### Platform compatibility
- [ ] Tested with the current stable Flutter release.
- [ ] Tested with Flutter beta, when time allows.
- [ ] `OTelNavigatorObserver` works alongside `go_router` (default integration) and standalone `MaterialApp` navigation.
- [ ] App-lifecycle observer fires on Android, iOS, and web.
- [ ] Web build does not break on `dart:io`-only paths — the SDK's web facade should keep things safe but verify on every release.

### Ecosystem
- [ ] Verified with common navigation packages (`go_router`, `auto_route` if a user reports needing it).
- [ ] Verified with common state-management packages — pure consumers; we don't reach into their internals.
- [ ] If we add a new auto-instrumentation, it must be opt-out (a setting on `FlutterOTel.initialize`).

## Emergency Fixes

If an emergency fix is required for a released version:

1. Create a hotfix branch from the tagged release (`git checkout -b hotfix/X.Y.Z+1 vX.Y.Z`).
2. Apply the minimal fix.
3. Update the CHANGELOG with a `## [X.Y.Z+1-wip]` section describing the fix.
4. Set `pubspec.yaml` to `X.Y.Z+1-wip`.
5. Run `dart run tool/release.dart`.
6. Merge the hotfix branch back to `main` (the new commits should fast-forward).

## CNCF Contribution Considerations

If preparing this package for CNCF contribution (as part of the
Dartastic / Flutterrific donation in flight):

- [ ] Legal requirements satisfied (license, NOTICE, CLAs).
- [ ] Governance docs current (`GOVERNANCE.md`, `CONTRIBUTING.md`, `SECURITY.md`).
- [ ] No vendor lock-in in defaults; the package works against any OTLP-compatible backend.
- [ ] Compatibility with [OpenTelemetry semantic conventions](https://github.com/open-telemetry/semantic-conventions) verified — especially the client/browser/mobile namespaces (currently `Development` status; track stabilization in the README "Client OpenTelemetry" section).

## Quality Gates

### Code
- [ ] Test coverage trending up release-over-release (target: `>=85%` for the stable cut).
- [ ] No critical security vulnerabilities (`dart pub deps` + `pub.dev` advisories clean).
- [ ] Package size reasonable for Flutter apps (`dart pub publish --dry-run` shows the file manifest).

### Documentation
- [ ] All public APIs have at least a one-line docstring.
- [ ] Breaking changes have a one-line migration in the CHANGELOG.
- [ ] README's "Client OpenTelemetry" section reflects the *current* spec status for each namespace.
- [ ] `example/` builds and runs.

### Community
- [ ] Open issues triaged.
- [ ] Breaking changes pre-discussed in an issue or PR before this release.

## Rollback

If a problem is discovered after release:

1. **Triage** — assess severity. For most issues, ship a patch release rather than retracting.
2. **Patch** — follow the emergency-fix flow above for a `X.Y.Z+1`.
3. **Retract** (last resort) — `dart pub retract X.Y.Z` and immediately publish the patch. Note retraction is reversible within 7 days but visible to consumers.
4. **Postmortem** — write up what went wrong, what test would have caught it, file the test as an issue.
