# Offline Map Loading States

## Goal
Replace the generic `Loading map style` message with clearer staged loading feedback for offline map startup.

## Why
Current messaging is technically correct but vague. Users do not know whether the app is checking the map file, building style JSON, or waiting for layers.

## Starting Points
- `lib/ui/screens/flight/widgets/tabs/map/flight_map.dart`
- `lib/ui/screens/flight/widgets/tabs/map/map_style_loading_view.dart`

## Notes
- Prefer 2-4 simple phases, not a long progress checklist.
- Keep the wording user-facing, not implementation-facing.
