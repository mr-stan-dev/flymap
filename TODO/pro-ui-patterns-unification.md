# Pro UI Patterns Unification

## Goal
Centralize the UI patterns used for Pro status, Pro upsell, and gated feature messaging.

## Why
Settings, Home, Subscription, and route creation all show Pro state slightly differently. Without shared patterns, they will drift again.

## Starting Points
- `lib/ui/screens/settings/widgets/subscription_top_banner.dart`
- `lib/ui/screens/home/tabs/home/widgets/home_summary_header_pro.dart`
- `lib/ui/screens/subscription/subscription_management_screen.dart`
- Pro-related widgets under `lib/ui/widgets/`

## Notes
- Different contexts can still have different density.
- The goal is shared language and components, not identical layouts everywhere.
