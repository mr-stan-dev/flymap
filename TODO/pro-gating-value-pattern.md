# Mid Priority: Pro Gating Value Pattern

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

## Concrete Places To Change

### 1. `lib/ui/screens/subscription/subscription_management_screen.dart`

Make this the canonical source of Pro benefit wording.

Keep the three core Pro benefits aligned here and reuse them elsewhere:
- detailed offline maps
- more route discoveries
- unlimited offline articles

### 2. `lib/ui/screens/create_flight/flight_preview/steps/map_preview/flight_search_map_preview_step.dart`

Current Pro moment:
- free user selects Pro map detail

What to improve:
- explain the benefit as `detailed offline maps`
- keep the CTA wording aligned with other Pro prompts
- avoid a one-off message style that only exists on this screen

### 3. `lib/ui/screens/create_flight/flight_preview/steps/wikipedia_articles/flight_search_wikipedia_articles_step.dart`

Current Pro moment:
- free user hits the article selection limit

What to improve:
- explain the value as `unlimited offline articles`
- align the limit message and CTA with the same voice used in other Pro gates
- visually and structurally match the map-detail gate where possible

### 4. `lib/ui/screens/settings/widgets/subscription_top_banner.dart`

Current role:
- Pro status / upgrade entry point from Settings

What to improve:
- keep Pro state lightweight
- for free users, align banner language with the same benefit framing used elsewhere
- avoid introducing another wording set

### 5. `lib/ui/screens/home/tabs/home/widgets/home_summary_header_pro.dart`

Current role:
- Pro presentation on Flights tab

What to improve:
- mostly visual consistency
- if any Pro copy appears here later, it should reuse the same product wording

### 6. Shared widget layer under `lib/ui/widgets/`

Possible implementation step after wording is aligned:
- extract a shared gate/upsell component such as `ProGateCard` or `ProFeaturePrompt`

Useful inputs for the component:
- title
- message
- CTA label
- optional icon

Likely first consumers:
- map preview Pro gate
- article limit Pro gate

## Suggested Execution Order

1. Align wording in `subscription_management_screen.dart`
2. Align `flight_search_map_preview_step.dart`
3. Align `flight_search_wikipedia_articles_step.dart`
4. Extract a shared Pro gate component only if the duplication is clearly worth it
