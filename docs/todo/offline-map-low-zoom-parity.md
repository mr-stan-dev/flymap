# Offline Map Low-Zoom Parity With Online Map

## Context
Users report that online maps show rich context (green areas, mountains, desert tones) at very low zoom, while offline maps look mostly gray until zooming in.

## Problem Statement
In the current implementation, online and offline map rendering are not equivalent at low zoom levels.

## What We See Today
- Online map (preview) shows richer low-zoom terrain and land context.
- Offline map uses a flatter appearance at low zoom and only becomes detailed after zooming in.

## Why It Happens (Root Causes)
1. Different style inputs between online and offline.
2. Online style includes extra low-zoom raster relief context (Natural Earth shaded source), while offline style does not.
3. Offline source data is corridor-clipped and optimized for route download size, which removes broader world context at low zoom.
4. Several thematic layers are only visible starting from higher `minzoom`, so low zoom feels sparse.

## Impact
- Perceived quality mismatch between online and offline map experience.
- Users can interpret offline map as "broken" or incomplete.
- Reduced orientation/context at cruise-level viewing.

## Task Goal
Bring offline low-zoom map visuals closer to online quality without unacceptable bundle-size growth.

## Implementation Options

### Option A: Style-Only Improvement (Fast)
- Tune offline style for low zoom:
  - improve background/water/landcover palette,
  - review `minzoom` thresholds for key context layers,
  - ensure low-zoom labels remain readable.
- No new data sources.

Pros:
- Fast and low risk.
- No major storage changes.

Cons:
- Cannot fully match online relief/terrain feel.

Estimated effort:
- 0.5-1 day.

### Option B: Add Low-Zoom Raster Relief Offline (Parity-Oriented)
- Add offline raster source equivalent to online low-zoom shaded relief.
- Package and reference it in offline style/source mapping.
- Keep existing vector route tiles for detailed zooms.

Pros:
- Best visual parity with online at low zoom.
- Stronger context over mountains/deserts/coastlines.

Cons:
- More complex implementation.
- Increases download/storage size.
- Requires careful Android/iOS validation for raster MBTiles/source handling.

Estimated effort:
- 2-4 days including testing/tuning.

## Recommended Rollout
1. Ship Option A first (quick win).
2. Measure user feedback and map-size impact.
3. If needed, implement Option B as a second iteration.

## Acceptance Criteria
- Offline map at zoom 0-6 no longer appears mostly gray for typical long routes.
- Visual gap between online and offline is reduced for low zoom context.
- No crashes/regressions in offline rendering on Android/iOS.
- Download size increase remains within acceptable product thresholds.

## Risks / Problematics
- Raster source integration may differ by platform behavior.
- Low-zoom global context can significantly increase downloaded data if unconstrained.
- Style edits may unintentionally reduce readability/contrast in dark or bright regions.
- Need to preserve compatibility for already-downloaded legacy flights.

## Notes
- Keep existing route-focused download model intact unless explicitly expanded to global low-zoom coverage.
- Validate with representative routes: short continental, long-haul ocean crossing, and mountain-heavy corridors.
