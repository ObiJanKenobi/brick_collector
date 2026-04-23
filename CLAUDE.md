# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Brick Collector is a Flutter app for importing LEGO parts from Rebrickable CSV exports and tracking collection progress. Users create MOCs (My Own Creations/Collections), import part lists, and mark parts as collected. Targets all platforms (iOS, Android, web, macOS, Windows, Linux).

## Build & Run Commands

```bash
flutter pub get                  # Install dependencies
flutter run                      # Run on connected device/emulator
flutter test                     # Run tests (minimal — single widget smoke test)
flutter analyze                  # Static analysis

# Code generation (Isar models, JSON serialization, Freezed)
dart run build_runner build --delete-conflicting-outputs

# Release builds
scripts/prod_release_apk.sh
scripts/prod_release_appbundle.sh
```

Compile-time environment variables for dev login prefill:
```bash
flutter run --dart-define=USER_ID=email --dart-define=USER_PASSWORD=pass
```

## Architecture

### Dependency Injection

`get_it` service locator registered in `main.dart:registerSingletons()`. Global getters (`appLogic`, `dbLogic`, `mocLogic`, `partsLogic`, `brickConverterLogic`, `rbService`) provide access. Widgets use `GetItMixin` for reactive binding.

### Layers

- **`lib/logic/`** — Business logic controllers as GetIt singletons
  - `AppLogic` — Bootstrap, file loading, CSV parsing, part merging, Rebrickable login
  - `DbLogic` — Isar database operations (MOCs, FilterPresets)
  - `MocLogic` — MOC CRUD, streams MOC list via RxDart `BehaviorSubject`
  - `PartsLogic` — Parts filtering, category/color streams, filter presets
- **`lib/model/`** — Isar `@collection` and `@embedded` data classes (`Moc`, `CollectablePart`, `FilterPreset`, `CollectablePartGroup`)
- **`lib/screens/`** — Full-page screens (StatefulWidgets)
- **`lib/ui/`** — Reusable widgets and theme constants

### State Management

RxDart `BehaviorSubject` streams in logic classes, consumed by StatefulWidgets. Inter-widget communication uses Flutter's `Notification` system (`SaveMocNotification`).

### Routing

GoRouter in `lib/router.dart`. Routes: `/` (splash), `/home` (MOC list), `/parts` (preset list), `/moc/:id`, `/partgroup/:partNum`, `/filter/:id`. Detail routes pass data via `GoRouterState.extra`.

### External Dependency: brick_lib

Local path dependency at `/Users/wagenblast/develop/brick-lib` (git alternative commented in pubspec.yaml). Provides `BrickPart` model, `BrickConverterLogic` (CSV parsing), `RebrickableService` (API client), color/category models.

### Database

Isar (via `isar_community` fork) for local persistence. Two collections: `Moc` (with embedded `CollectablePart` list) and `FilterPreset`.

### Barrel Import

`lib/common_libs.dart` re-exports frequently used packages. Import this instead of individual packages.
