# flymap

Offline maps for flights

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
