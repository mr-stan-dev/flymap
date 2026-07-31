# Release-Readiness Review — 2026-07-31 (master)

Follow-up to `project_review_2026_07.md` (Jul 7). Covers the 75 commits since —
almost all of them the new **weather / cloud-map / flight-video / date /
notifications / offline** feature set. Five-dimension sweep (prior-findings
re-verify · new-feature correctness · resources/perf · data-integrity ·
infra/security); every claim verified in source at review time. The two
highest-impact new findings (B, C) were additionally hand-verified.

Baseline health is good: `fvm flutter analyze lib test` clean (1 deprecation
info), **624 tests green**, i18n 100% × 4 locales, Crashlytics + runZonedGuarded
wired, Android signing/minify solid, App Check on, **no server-side secrets
committed**. The new graphics code disposes images/pictures correctly (the old
"zero dispose in lib/" is gone). The **delete-flight path is complete** — it now
reclaims the weather record, all three route-map image variants (incl. the new
`weather` one), notifications, and ref-counted mbtiles/article media.

**Verdict: not ready to submit as-is.** No hard store-reject blocker, but there
are two guaranteed crashes (one on the core in-flight path), a revenue leak, an
entitlement-spoofing backup surface, and the still-open data-integrity/process
gaps. The high-impact fixes are individually small — a focused hardening pass
gets this shippable.

Status legend: `[ ]` open · `[x]` fixed.

> **Hardening pass, same day (2026-07-31):** fixed **A, B, C, D, E** (all
> blockers except the process ones), plus **I**, the dead-`config.dart`
> quick win, and the met.no half of **M**. **O reversed:** the iOS "Always"
> location string is KEPT — background in-flight tracking is planned, so it
> will be used (ideally land it in the same release as that feature, and add
> `UIBackgroundModes`/Android background-location plumbing then). Added regression tests for A
> (router redirect helper), B (emit-after-close), and the DB migration (**E/H**,
> in-memory sembast — no new deps). CI (**G**) is intentionally skipped in favour
> of tests per the maintainer; the **tile-engine** half of **H** is deferred
> because covering the mbtiles validator/verifier means running sqlite in
> desktop tests (a dev-only `sqflite_common_ffi`), which we chose not to add for
> now. `allowBackup` is set to **false** (not the earlier rules-exclusion
> approach). 633 tests green.

---

## 🔴 Blockers — fix before submitting

- [ ] **A. `/flight` route crashes on malformed `extra`.** `router/app_router.dart:164`
  `final flight = extra?['flight'] as Flight;` — the only route with a
  non-nullable cast on nullable content; siblings (share-image :177, video :192,
  download-completed :205) all null-guard. Any navigation/deep-link with a
  missing `flight` → `TypeError`. *(prior #2, still open — hand-verified)*
  **Fix:** `as Flight?` + null-guard→redirect like the siblings.

- [ ] **B. Emit-after-close crash leaving an active flight (core in-flight path).**
  `flight/viewmodel/flight_screen_cubit.dart:336-340` `close()` calls
  `_gpsProvider.stop()` **without await** then `super.close()`; the GPS
  `onUpdate` callback (:96-112) and `_emitTelemetryUpdate` (`emit` at :316) have
  **no `isClosed` guard**. A GPS position queued while `stop()` is still pending
  fires `emit()` on a closed cubit → `StateError`, as an uncaught async error
  during the feature's primary use. *(new — hand-verified)*
  **Fix:** `if (isClosed) return;` at the top of the callback/emit path, and
  `close() async { _gpsCheckTimer?.cancel(); await _gpsProvider.stop(); return super.close(); }`.

- [ ] **C. One-time flight unlock isn't consumed on the saved-flight path (revenue leak).**
  `flight/sections/flight_weather_screen.dart:86-96` `_onFlightUnlocked` flips the
  flight to Pro (`updateFlightAccessTier`) but never calls
  `FlightUnlockRepository.consumeUnlock()` — the create-flight download path does
  (`…/delegates/download_flow_delegate.dart:330-331`). The gate sheet skips the
  purchase when a balance exists (`flight_unlock_gate_sheet.dart:64-82`). Result:
  with a balance ≥1 → **unlimited** free unlocks from one credit; buying with
  balance 0 → flight unlocked **and** a spare credit kept. *(new — hand-verified)*
  **Fix:** `consumeUnlock()` in `_onFlightUnlocked` (guarded `!isPro`, mirroring the download flow).

- [ ] **D. `android:allowBackup` unset → true; entitlements spoofable in plaintext.**
  `android/app/src/main/AndroidManifest.xml` sets no `allowBackup` and no
  data-extraction/backup rules. Auto Backup then includes the sembast DB
  (`flightAccessTier: 'pro'` plain string) and the SharedPreferences unlock
  counter `flight_unlock.unused_count.v1` — which is the **only** source of truth
  for the unused balance (no server reconciliation; `restoreUnlock()` blindly
  `+1`s). `adb backup`→edit→restore (no root) flips a flight to Pro or inflates
  the balance. *(prior #12c + #4, still open; flagged by 2 agents)*
  **Fix:** ship `dataExtractionRules`/`fullBackupContent` that **exclude** the
  unlock pref (keep flights backable so reinstalls keep downloads); treat client
  tier as a cache validated against RevenueCat on launch.

- [ ] **E. Local DB migration gated on internet.** `data/local/migrations/flights_db_migration_runner.dart:28-32`
  early-returns when offline; the only migration (v1→v2) is a purely-local
  backfill. Offline updaters never advance schema version, and it adds a ~2s
  socket probe to every cold start. Impact *today* is ~nil (the migrated
  `type='map'` rows are write-only, never read), but it's a latent trap for the
  next migration that matters. *(prior #3, still open; flagged by 3 agents)*
  **Fix:** run local schema migrations unconditionally; gate only network ones.

- [ ] **F. Old share-card pipeline leaks ~14–15 MB native per generation.**
  `domain/usecase/generate_share_image_use_case.dart:88,100,105,222` (mapImage
  ~6.9 MB + planeImage + composited ~6.9 MB + the `ui.Picture`) and
  `ui/screens/share_flight/share_flight_image_screen.dart:212` (captured image up
  to ~15.5 MB) are **never disposed**. Runs on `ShareImageCubit` construction and
  every `retry()`; ui.Image memory frees only on GC finalization → accumulates,
  OOM risk under repeated share opens. *(prior #6 — now PARTIAL: the NEW weather/
  video renderers dispose correctly; only this old path leaks; flagged by 2 agents)*
  **Fix:** `try/finally` dispose all four in the use case + the captured image.

- [ ] **G. No CI / quality gate.** No `.github/`, no CI config anywhere; nothing
  enforces the 624 green tests or `analyze` on a push. The `Makefile` already has
  `make analyze` / `make test`. *(prior #10, still open)*
  **Fix:** ~15-line PR action: `fvm flutter pub get && fvm flutter analyze && fvm flutter test`.

- [ ] **H. Zero tests on the two highest-risk modules.** DB migrations have **no**
  test; the tile-download engine core (`vector_tiles_downloader/worker/db`,
  `mbtiles_verifier/validator`) has none (only pure helpers are covered). These
  are exactly where a regression means offline-map data loss. Weather, by
  contrast, is now well covered (7 files). *(prior #11, still PARTIAL)*
  **Fix:** at minimum a v1→v2 migration idempotency test + an mbtiles verify/validate test.

## 🟠 Should fix soon (majors)

- [ ] **I. Picking a date on the saved-flight weather screen never schedules its
  notifications.** `flight/sections/flight_weather_screen.dart:108-133` persists
  the schedule but never calls `FlightNotificationScheduler.syncForFlightId` (the
  create flow does, `flight_preview_screen.dart:511`). Alerts only appear after
  the next cold-start `resyncAll()`; a "forecast ready" alert whose fire time
  falls before that is dropped forever. *(new)*
- [ ] **J. Shared-singleton download state.** `DownloadMapUseCase` + both
  wiki-download use cases are lazySingletons holding per-download cancel state
  (`di_module.dart:305,338,380`); two preview screens on the stack cancel each
  other's downloads. *(prior #5)*
- [ ] **K. Startup blocks first paint + large assets parsed sync on the UI isolate.**
  `main.dart:35-60` serially awaits ~9 init steps (incl. 2 Firebase round-trips +
  the 2s migration probe) before `runApp`. Airports CSV (~950 KB,
  `airports_database.dart`), land-mask GeoJSON (1.6 MB, `land_mask_provider.dart`),
  and geo-quiz (1.9 MB) decode synchronously — no `compute()`. `cities_database.dart:44`
  is the correct pattern to copy. *(prior #7 + quick wins)*
- [ ] **L. Weather corridor samples misplaced across the anti-meridian.**
  `domain/usecase/fetch_flight_weather_use_case.dart:_samplePoints` interpolates
  longitude naively (no shortest-path wrap), unlike the ring/grid helpers and
  `RoutePathSampler`. A trans-Pacific 2-waypoint route samples through lon 0 →
  wrong forecast/verdict/cloud-map. Degrades (not crashes) on dense-waypoint
  routes. *(new)*
- [ ] **M. Network timeouts missing.** Firebase callables
  (`flight_info_api`/`flight_number_search`/`upcoming_flight_search`/
  `flight_route_search`/`flight_route_preview`) have no `HttpsCallableOptions(timeout:)`
  → ~70s SDK default; and `met_norway_api.dart:65` has no `.timeout()`, so on
  stalled (not-cleanly-offline) Wi-Fi one of ~30 weather requests hangs the step.
  *(prior #9 + new; flagged by 3 agents)*
- [ ] **N. Restrict the committed Mapbox `pk.` token.** `env/app_config.prod.json:6`
  (+ debug) — public-by-design, but scope it to the app bundle/URLs + needed APIs
  in the dashboard to prevent bill-scraping. ~5 min. *(prior #12a)*
- [ ] **O. iOS declares unused "Always" location.** `ios/Runner/Info.plist:54`
  `NSLocationAlwaysAndWhenInUseUsageDescription`, but the app only ever requests
  When-In-Use — an over-declaration Apple can flag (5.1.1). Remove the key. *(new)*

## 🟡 Minor / quick wins

- [ ] Home tab: 5× `getAllFlights()` per refresh with per-flight article hydration (`home_tab_cubit.dart`). *(prior #8)*
- [ ] Home flight-card map image decoded at 1280×960 (~4.9 MB) with no `cacheWidth` → scroll churn (`home_flight_card_map_header.dart:157`; `cacheWidth` used nowhere in lib).
- [ ] Onboarding weather payoff builds all 3×24 cloud frames on the **UI isolate** (`onboarding_weather_payoff_step.dart:201-235`) — jank during the page-turn; the flight card correctly uses `Isolate.run`.
- [ ] `WeatherShareRenderer` TextPainters never disposed → ~1,900 `ui.Paragraph` accumulate across a 192-frame video export (`weather_share_renderer.dart:299,328`).
- [ ] `CompleteFlightUseCase(deleteOfflineData:true)` doesn't delete the weather store record / `weather` image / cancel notifications (incomplete vs `DeleteFlightUseCase`); route both through one teardown.
- [ ] One transient airport request failure throws away the whole forecast (`fetch_flight_weather_use_case.dart:106-110`) — only throw when *both* airports fail.
- [ ] Notification-tap deep link doesn't `reload()` the underlying flight screen (`flight/flight_screen.dart:214-228`) — unlock/date change leaves a stale boarding card.
- [ ] `FlightWeatherCubit.fetchIfNeeded` early-returns on `isLoading` even with `force:true` (latent; not currently reachable).
- [ ] `isBeyondForecastHorizon` uses `Duration`-based date math → a DST hour can tip a flight exactly 7 days out into "too early"; use calendar-component math.
- [ ] Migrate off discontinued `flutter_markdown` (`pubspec.yaml:49`; renders Wikipedia-derived content). *(prior #12b)*
- [ ] Delete dead `lib/config.dart` (unimported placeholder secrets + only `http://` URL in repo). *(prior quick win)*
- [ ] Day/night map timers keep firing while backgrounded (`flight_map_day_night_controller.dart:78-83`) — pause on lifecycle.
- [ ] 2 bare `print()` in release paths (`vector_tiles_worker.dart:223`, `tile_utils.dart:94`) → Logger.
- [ ] Dependency drift — `purchases_flutter` a full major behind (9.15→10.6); schedule the RevenueCat + Firebase bumps.
- [ ] `FlightWeatherDbMapper` hard-casts required fields and stores no schema version (fine while weather is ephemeral).
- [ ] Sky-camera media isn't reclaimed on flight delete (appears by-design — captures are standalone geo-memories; Storage screen doesn't count it, so no reported-vs-actual mismatch). Consider clearing the dangling `flightId`.

## ✅ Verified healthy (no action)
- Delete-flight teardown is complete (weather store + all 3 map-image variants + notifications + ref-counted mbtiles/article media). Notification IDs stable across process runs; cancel hits the right slots.
- New weather/cloud/video graphics dispose images/pictures/controllers/timers correctly; home does no per-build disk work (stored-weather load is `initState`-gated to upcoming flights).
- Offline degradation graceful everywhere (stored-first weather, gradient/plain-header fallbacks, no crashes); "no backfill for legacy flights" is consistent.
- Crash pipeline textbook (`runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError`, release-gated); Android `exported`/minify/`shrinkResources`/hard-fail signing correct; iOS no ATS override; App Check enabled; flight-owned file model intact (no route-keyed regression).

## Suggested order
1. **B** (in-flight crash) → **A** (route crash) → **C** (revenue) → **D** (backup rules) — the four high-impact, low-effort fixes.
2. **G** (CI) + **H** (migration/tile tests) — stand up the gate before trusting the offline core; then **E** (unconditional migration).
3. **N** + **O** (dashboard + Info.plist, ~10 min) → **F** (share leaks) → **I/L/M** → performance (**K**) and the quick wins opportunistically.
