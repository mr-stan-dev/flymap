# flymap

Offline maps for flights

## Flutter SDK

This project should be run with `fvm` so the Flutter SDK version stays pinned per repo.

Install `fvm`:

```bash
brew install fvm
```

Initial project setup:

```bash
fvm use <flutter-version>
fvm flutter pub get
```

After `.fvmrc` is committed, a fresh clone can be set up with:

```bash
fvm install
fvm flutter pub get
```

Use `fvm`-prefixed commands for day-to-day work:

```bash
make run-debug
fvm flutter analyze
fvm flutter test
```

### Firebase App Check in debug builds

Debug builds use fixed, per-platform App Check debug tokens so reinstalling the
app does not generate a new token. Set them up once per development machine:

1. Copy `env/app_check.debug.local.example.json` to
   `env/app_check.debug.local.json`.
2. Replace both placeholders with UUIDv4 values.
3. In Firebase Console, open **App Check > Apps > Manage debug tokens** and
   register the iOS value for the iOS app and the Android value for the Android
   app.
4. Run the app with `make run-debug` (or `make rd`).

The local token file is ignored by Git. Treat these tokens as secrets: never
commit them, share them, or include them in a release build. Revoke and replace
any token that is exposed.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## UI Style Guard

Run the style guard before opening a PR:

```bash
bash tool/check_ui_style_guard.sh
```

Rules for `lib/ui` (outside approved exclusions):

- disallow `Colors.*`
- disallow `Color(0x...)`
- disallow `TextStyle(...)`

Use `ThemeData` (`colorScheme`, `textTheme`) and `lib/ui/design_system` widgets/tokens.

Detailed migration and usage guide:
- `docs/ui_design_system.md`
