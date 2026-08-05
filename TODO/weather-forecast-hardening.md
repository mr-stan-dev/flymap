# Weather Forecast Follow-ups

## Current decision

Keep MET Norway behind the Flymap backend for the first production version. It
is a strong fit for the low/mid/high cloud bands used by the visualization.

The mobile domain depends on `WeatherForecastProvider`, and production uses a
single batched Firebase callable, `get_flight_weather_forecast`. Provider URLs,
HTTP behavior, parsing, retries, throttling, and shared caching live only on the
backend. A provider change should preserve the versioned Flymap contract and
therefore require no mobile release.

The weather screen intentionally stays simple:

- departure and arrival cards
- animated cloud map
- one compact overall verdict below the map

Do not restore the estimated-time banner or the route-segment list without a
new product decision.

## High priority

### Verify attribution and derived-visualization compliance

- Audit the exact wording and link requirements against the current
  [MET Norway terms](https://docs.api.met.no/doc/TermsOfService.html).
- Make attribution reachable as a link, not only plain text.
- Confirm that generated share images and videos carry the required credit.
- State clearly that Flymap transforms forecast values into an illustrated
  cloud field rather than displaying an official MET Norway map.

### Monitor the weather proxy

One mobile call contains roughly 45–58 coordinate locations. The backend
deduplicates requests, caches across users, conditionally revalidates upstream
responses, retries transient failures, and applies both a global deadline and
an aggregate request-start limit.

- Add dashboards for calls per forecast, cache hit rate, 429 responses,
  latency, partial-location failures, and total failures.
- Alert on sustained provider failures and Firebase function saturation.
- Revisit cache and instance limits from measured production traffic.

### Rebuild animation state when forecast input changes

`WeatherRouteMapCard` derives its route projection, cloud samples, frames, and
map image in `initState`. A refresh can update the widget with new weather while
the old frames remain on screen.

- Implement `didUpdateWidget` for route/sample/flight changes.
- Dispose superseded `ui.Image` frames.
- Prevent an older asynchronous rasterization from replacing newer frames.
- Add a widget test that refreshes the same card with materially different
  samples and verifies that the rendered frame set changes.

## Forecast accuracy and honesty

### Validate the verdict model

The current verdict treats combined low and mid cloud as hidden ground and
uses high cloud to distinguish a cloud carpet from overcast. That is a useful
product heuristic, not a visibility guarantee.

- Build a small validation corpus across seasons, regions, route lengths, and
  departure periods.
- Compare forecast verdicts with satellite imagery or structured post-flight
  feedback such as “Could you see the ground?”.
- Calibrate thresholds only from that corpus; avoid tuning to a few memorable
  flights.
- Revisit how overlapping low/mid cloud percentages are combined. Adding the
  bands can overstate cover when layers overlap.

### Make daylight part of the presentation

Night flights can have meteorologically clear views but no meaningful ground
visibility. Use the existing solar-position utilities to distinguish daylight,
twilight, and darkness along the route. Keep this separate from cloud cover so
the UI can say “clear skies, mostly dark” rather than changing the meteorology.

### Preserve precipitation interval semantics

Farther-out MET Norway entries often describe six-hour precipitation totals.
The current normalization to an hourly-looking value is approximate. Carry the
source interval through the provider-neutral model and avoid presenting it as
an instantaneous measurement.

## Cloud animation

### Accessibility and controls

- Respect reduced-motion/accessibility settings.
- Provide pause/replay instead of forcing an endless loop.
- Decide whether the plane should reset visibly or cross-fade at the loop
  boundary.
- Use linear time progression for forecast time unless an eased motion is
  explicitly presented as decorative.

### Visual labeling and calibration

- Label the layer as an illustrated or modelled cloud forecast.
- Test cloud opacity and field interpolation on both light and dark imagery.
- Check sparse grids, fronts, coastlines, polar routes, and dateline routes for
  interpolation artifacts.
- Do not imply wind-driven cloud motion until pressure-level winds are fetched
  and a defensible advection model exists.

### Rendering performance

- Profile frame rasterization, image decoding, memory, and battery use on older
  iOS and Android devices.
- Share exports already do substantial image work; move any remaining large
  raster operations off the UI isolate.
- Cap or downscale frame generation based on device constraints if profiling
  shows pressure.

## Provider evaluation

Do not swap providers only to reduce the number of HTTP calls. First benchmark
forecast quality and operating constraints on the same route corpus.

### Open-Meteo prototype

- Implement a second `WeatherForecastProvider` adapter behind a development
  flag.
- Prototype batched coordinates using the
  [Open-Meteo forecast API](https://open-meteo.com/en/docs).
- Compare cloud-band definitions, temporal resolution, horizon, latency,
  licensing, commercial pricing, and real route output with MET Norway.
- Expect numerical differences: providers do not necessarily define altitude
  bands or precipitation intervals identically.

### WeatherKit benchmark

- Benchmark [WeatherKit](https://developer.apple.com/weatherkit/) only if its
  platform coverage, cloud variables, attribution rules, and request pricing
  fit the Android and iOS product together.
- Avoid an Apple-only source unless provider parity and saved-flight behavior
  are specified explicitly.

## Architecture cleanup

The provider dependency is now inverted, but the use case still imports UI map
projection utilities, `dart:ui.Offset`, a fixed 540 px viewport, and the share
map implementation to choose area sample coordinates.

- Move geographic sampling and viewport-independent projection into a domain
  service.
- Pass a sampling specification into the use case instead of importing a UI
  card size.
- Keep rendering density decisions in the presentation/share layers.
- Keep mobile contract tests provider-neutral and keep provider response
  parsing tests in the backend adapter.

## Suggested order

1. Attribution audit and refresh-safe animation state.
2. Proxy telemetry and operational alerts.
3. Validation corpus and daylight-aware presentation.
4. Accessibility and device performance profiling.
5. Open-Meteo benchmark; change provider only if evidence supports it.
6. Remove the remaining UI sampling dependencies from the domain use case.
