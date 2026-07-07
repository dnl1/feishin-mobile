# feishin_mobile

Native Flutter rewrite of [Feishin](https://github.com/jeffvli/feishin) (currently
Electron + React), targeting iOS first — a self-hosted music client for
Navidrome, with Jellyfin/Subsonic and other platforms planned as additive work
once the Navidrome path is solid.

See [docs/PLAN.md](docs/PLAN.md) for the full migration plan: architecture
decisions (audio engine, visualizer), what's intentionally dropped vs.
deferred, and the phase-by-phase breakdown. Update that file as phases
complete or decisions change — it's the source of truth for scope, not this
README.

## Why this exists

The original Feishin app already has a browser-only playback path (Web Audio
API, no dependency on the Electron-only `mpv` binary) and a mobile-oriented
layout, which made a native mobile client a good next step. Full context on
the source app's architecture is in the plan doc.

## Development environment

This repo is developed primarily on Linux, where you can do everything
**except** build/run for iOS:

- `flutter pub get`, `dart run build_runner build`, `flutter analyze`,
  `flutter test`, and all pure-Dart domain/business logic work fine on Linux.
- Building and running on an iOS simulator/device, and anything touching
  native iOS plugins (audio engine, background audio, lock screen controls),
  requires macOS/Xcode — done via the `ios-build` job in
  [`.github/workflows/ci.yml`](.github/workflows/ci.yml) (GitHub Actions
  `macos-latest` runner) since there's no local Mac in this loop yet.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Generated code (`*.freezed.dart`, `*.g.dart`) is gitignored and regenerated
by CI and locally via the command above — it is not committed.

## Status

Phase 0 (foundations) in progress — see [docs/PLAN.md](docs/PLAN.md) for
what's done vs. pending. The two highest-risk architecture questions (audio
engine, visualizer) are already decided and documented there; the audio spike
itself still needs to run on a macOS runner/device to be validated.
