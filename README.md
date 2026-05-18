# Selvator

Selvator is an offline-first Flutter quotes app for Android and Windows. It curates a large raw quote catalog into mood-based pools, stores user state locally with Hive, and adapts recommendations from mood choices, likes, skips, freshness, and session behavior. App state is managed with Riverpod.

## Main Features

- Multi-mood quote recommendations across 15 moods with manual refresh.
- Mood-aware Home greetings with local name, nickname, and gender personalization.
- Selvator mascot art that changes with the selected mood.
- Local mood journal page with recent entries per selected mood.
- Offline quote catalog shipped as Flutter assets.
- Local profile, favorites, and session persistence through Hive.
- Android home-screen quote widget integration.
- Windows tray menu for quote previews, mood switching, copy, next quote, and quit.
- Responsive mobile, tablet, and desktop UI.

## Project Layout

- `lib/main.dart` is the composition root: Flutter setup, Hive path setup, platform provider bindings, and Riverpod `ProviderScope`.
- `lib/src/domain/` contains pure entities, repository contracts, curation logic, and recommendation business rules.
- `lib/src/application/` contains Riverpod state, app orchestration, and platform port contracts.
- `lib/src/data/` contains Hive adapters and the Hive-backed repository implementation.
- `lib/src/infrastructure/` contains platform adapters for clipboard/share, Android widget sync, Windows tray, and process exit.
- `lib/src/presentation/` contains screens, widgets, and theme.
- `tool/build_quotes_cache.dart` curates `quotes.json` into shipped assets.
- `tool/validate_quote_index.dart` validates curated mood coverage.
- `android/app/src/main/kotlin/` contains the Android widget provider.

## Setup

```powershell
flutter pub get
```

The raw catalog is `silvator/quotes.json`. The app ships the generated assets in `assets/data/quotes_curated.json` and `assets/data/catalog_version.json`.
Selvator mascot source art lives in `silvator/mood-pics/`; runtime copies are declared from `assets/images/silvator/`.

## Catalog Workflow

Regenerate the curated quote catalog from `silvator/quotes.json`:

```powershell
dart run tool\build_quotes_cache.dart
```

Validate mood coverage and author distribution:

```powershell
dart run tool\validate_quote_index.dart
```

## Verification

Run static analysis and tests:

```powershell
flutter analyze
flutter test
dart format lib test tool
```

## Android Release Signing

Release builds are not signed with debug keys. To enable release signing, copy `android/key.properties.example` to `android/key.properties`, place the keystore under `android/`, and fill in the real values:

```properties
storePassword=...
keyPassword=...
keyAlias=wisely
storeFile=upload-keystore.jks
```

`android/key.properties` and keystore files are ignored by git.
