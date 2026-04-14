# Offline Map Init Performance

## Context

Opening an offline map still feels slower than expected.

The current flow has two visible phases:

1. `Loading map style`
2. Map shown with initialization overlay before route/POI layers are ready

## Current likely bottlenecks

- `MbtilesValidator.validate(...)` runs on every offline map open in `lib/ui/screens/flight/widgets/tabs/map/flight_map.dart`.
- A fixed `Future.delayed(const Duration(milliseconds: 1000))` is used after style load before route/POI layers are added.
- POI sync happens as part of initial map setup instead of being deferred until after the base route is visible.
- The offline style asset is loaded from bundle each time instead of being cached in memory.
- Cache directory lookup happens multiple times in the same style-load path.

## Suggested next optimizations

### 1. Remove the fixed 1 second delay

Replace the hardcoded post-style delay with one of:

- a much shorter retry loop
- a post-frame driven retry
- a more specific native-ready condition

This is likely the most visible improvement.

### 2. Stop doing full MBTiles validation on every map open

Preferred approach:

- validate once when the map is downloaded/imported
- persist a validation result
- on map open, do only a cheap existence / size / mtime check

Alternative:

- cache validation results in memory keyed by file path + file metadata

### 3. Defer POI layer sync

Show the base route first, then add POIs after the first usable map frame.

### 4. Cache the offline style asset string in memory

Avoid repeated `rootBundle.loadString('assets/styles/openfreemap_offline_style.json')`.

### 5. Trim repeated path lookups

Reduce repeated `getApplicationCacheDirectory()` calls inside the same load path.

## Notes

- Sprite/glyph copying is already moved off the critical path with background warmup.
- The `text-font` warning from MapLibre is a separate issue and should not be mixed with this performance task.
