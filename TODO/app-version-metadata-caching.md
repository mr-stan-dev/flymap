# App Version Metadata Caching

## Goal
Cache app version/build metadata centrally if it ends up being used in multiple places.

## Why
The Settings footer now reads version/build directly with `package_info_plus`. If that metadata appears elsewhere later, a shared source will be cleaner.

## Starting Points
- `lib/ui/screens/settings/widgets/app_version_footer.dart`
- existing `package_info_plus` usage in analytics and feedback flows

## Notes
- This is low priority.
- Do not add indirection unless the metadata is actually reused.
