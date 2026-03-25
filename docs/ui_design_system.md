# UI Design System Guide

This project uses a theme-first design system for all Flutter UI under `lib/ui`.

## Source Of Truth

- `ThemeData` is canonical:
  - `colorScheme`
  - `textTheme`
  - component themes (`filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`, `chipTheme`, `inputDecorationTheme`, `cardTheme`, `dialogTheme`)
- `ThemeExtension`s are compatibility aliases and should mirror theme tokens.

## Design System Layer

Use `lib/ui/design_system/design_system.dart` exports:

- Tokens:
  - `DsSpacing`
  - `DsRadii`
  - `DsIconSizes`
  - `DsMotion`
  - `DsSemanticColors`
- Widgets:
  - Buttons: `PrimaryButton`, `SecondaryButton`, `TertiaryButton`, `DestructiveButton`
  - Chips/Pills: `SelectionChip`, `StatusChip`, `MetaPill`
  - State views: `LoadingStateView`, `EmptyStateView`, `ErrorStateView`, `SuccessStateView`, `ProgressStateView`
  - Containers: `SectionCard`, `ExpandableSectionCard`, `InfoBanner`, `InlineMessage`
  - Inputs: `SearchInputField`

## Allowed Patterns In `lib/ui`

- `Theme.of(context).colorScheme...`
- `Theme.of(context).textTheme...`
- `.copyWith(...)` on theme-provided text styles
- DS widgets and DS tokens

## Disallowed Patterns In `lib/ui`

- `Colors.*`
- `Color(0x...)`
- `TextStyle(...)`

Use theme tokens and DS primitives instead.

## Style Guard

Run:

```bash
bash tool/check_ui_style_guard.sh
```

The guard fails if disallowed styling appears in `lib/ui`, except approved exclusions:

- `lib/ui/theme/**`
- `lib/ui/**/**painter.dart`
- `lib/ui/map/layers/**`

