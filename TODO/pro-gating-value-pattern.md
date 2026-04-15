# Pro Gating Value Pattern

## Goal
Make Pro upsell and gated-value messaging more consistent across route creation and related screens.

## Why
The app explains Pro benefits in multiple places with slightly different tone and structure. That makes the upgrade story feel fragmented.

## Starting Points
- `lib/ui/screens/create_flight/flight_preview/steps/map_preview/flight_search_map_preview_step.dart`
- `lib/ui/screens/create_flight/flight_preview/steps/wikipedia_articles/flight_search_wikipedia_articles_step.dart`
- `lib/ui/screens/subscription/subscription_management_screen.dart`

## Notes
- Reuse the same benefit framing where possible.
- Avoid generic premium copy when the app can name the actual feature.
