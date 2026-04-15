# Low Priority: Settings Component System

## Goal
Finish extracting reusable settings UI pieces into a small coherent component set.

## Why
Settings has improved, but the screen still mixes generic rows, special-case rows, grouped cards, and custom bottom sheets that could be more systematic.

## Starting Points
- `lib/ui/screens/settings/widgets/`
- `lib/ui/screens/settings/settings_screen.dart`

## Notes
- Focus on reusable row variants, grouped cards, and shared selection-sheet patterns.
- Avoid over-abstracting simple one-off actions.
