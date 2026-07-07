# Project Review — July 2026 (master)

Full-codebase review (architecture/data, performance, security/release, tests/quality).
All critical/major claims below were verified in source at review time. `flight_video`
lives on the `video-rendering` branch and is not covered here.

**Overall:** disciplined codebase — clean `flutter analyze`, exemplary i18n (4 locales,
100% key-complete), real design system, well-tested subscription logic, careful lifecycle
handling in the hairiest classes, no security criticals. One genuine data-loss bug in the
core feature, a handful of majors, and one process gap (no CI).

Status legend: `[ ]` open · `[x]` fixed.

---

## 🔴 Critical

- [x] **1. Offline maps are keyed by route, not flight — deleting one flight destroys
  another's map.** *(Fixed 2026-07-07 in two steps: (a) NEW
  downloads are flight-owned — map files are named `{routeCode}_{flightId}_{layer}.mbtiles`
  and article bundles include the flightId, so same-route flights never share or
  overwrite each other's data and deleting a flight always frees its storage; (b) LEGACY
  shared files from older installs are protected by `FlightAssetsDeleter`
  reference-counted deletion (single owner of deletion logic for both delete + complete
  use cases, tested). `VectorTilesDownloader` additionally writes to a `.mbtiles.part`
  work file promoted only after verification, and storage stats dedupe legacy shared
  files.)* `download_map_use_case.dart` names files `{routeCode}_{layer}.mbtiles`
  (no flightId), so two flights on the same route share one physical file.
  `delete_flight_use_case.dart` / `complete_flight_use_case.dart` delete unconditionally
  (no reference counting). Consequences: delete or "complete + clean" flight A → flight
  B's offline map silently vanishes (discovered mid-flight, offline); a *failed*
  re-download of the same route (<70% success gate) deletes a previously-good file;
  storage stats double-count.
  *Fix direction: reference-counted deletion + download-to-temp with atomic rename
  (no migration of existing files needed).*

## 🟠 Major — correctness

- [ ] **2. `/flight` route crashes on missing `extra`.** `app_router.dart:144-145` does
  `extra?['flight'] as Flight` (null cast → TypeError). Only unguarded route; siblings
  null-check and redirect.
- [ ] **3. Local DB migration gated on internet.** `flights_db_migration_runner.dart:27-32`
  skips the purely-local V1→V2 migration when offline; offline users never migrate. The
  check also adds a ~2s socket probe to every cold start.
- [ ] **4. Consumable unlock balance is local-only.** `flight_unlock_repository.dart`:
  SharedPreferences counter — lost on reinstall/new device; app-kill between purchase and
  credit = paid, got nothing; restore blindly increments. Needs RevenueCat-side
  reconciliation (non-subscription transactions vs consumed count).
- [ ] **5. Shared-singleton download state.** `DownloadMapUseCase` + both wiki-download
  use cases are lazy singletons holding per-download cancel state (`di_module.dart:235,
  268,310`); two preview screens on the stack can cancel each other's downloads.

## 🟠 Major — performance

- [ ] **6. Every `ui.Image`/`Picture` leaks.** Zero `.dispose()` calls in all of `lib/`.
  Each share-card generation leaks ~14MB native memory
  (`generate_share_image_use_case.dart`, `share_flight_image_screen.dart:212`).
- [ ] **7. Startup blocks first paint.** `main.dart:30-57` serially awaits App Check
  network attestation, anonymous Firebase sign-in, and the migration connectivity probe
  before `runApp`. Separately, the 882KB airports CSV parses synchronously on the UI
  isolate (`airports_database.dart:50-58`) — `cities_database.dart:44` shows the correct
  `compute()` pattern.
- [ ] **8. Home tab: 5× full-table scans per refresh.** Four stats getters + the list
  each call `getAllFlights()` with per-flight article hydration
  (`home_tab_cubit.dart:88-108`). Stats don't need hydrated articles.
- [ ] **9. Cloud-function calls mostly lack timeouts.** Only route-overview has one
  (25s); lookup/search/feedback hang up to ~70s (SDK default) on flaky networks.

## 🟠 Major — process & platform

- [ ] **10. No CI.** No analyze/test gate anywhere (only a build Makefile); master can go
  red unnoticed. *(The stale `app_advocacy_dialog_test.dart` assertion was fixed
  2026-07-07 — suite is green again; the CI gate itself is still missing.)*
- [ ] **11. Zero tests on the two highest-risk modules:** the tile download engine
  (`lib/data/tiles_downloader/`, ~1000 lines) and DB migrations. Issue #1 lives exactly
  there.
- [ ] **12. Security config items:**
  - Restrict the committed Mapbox `pk.` token (`env/app_config.prod.json`) to the app
    bundle IDs in the Mapbox dashboard (billing-abuse surface).
  - Migrate off discontinued `flutter_markdown` (renders Wikipedia-derived content).
  - Set `android:allowBackup=false` or add extraction rules — flights DB + the spoofable
    unlock counter currently back up in plaintext.

## 🟡 Quick wins

- [ ] Land-mask (1.6MB, `land_mask_provider.dart`) and geo-quiz (1.8MB) JSON decode on
  the UI thread → `compute()`.
- [ ] 232×232 POI PNGs decoded for 24×24 list markers — add `cacheWidth`
  (`home_route_preview_strip.dart:118`; `cacheWidth` used nowhere in the app).
- [ ] Day/night map timers keep firing while backgrounded
  (`flight_map_day_night_controller.dart:78-83`) — pause on lifecycle.
- [ ] Delete dead `lib/config.dart` (never imported; placeholder "secrets"; the only
  `http://` URL in the repo).
- [ ] 2 bare `print()` in release paths (`vector_tiles_worker.dart:223`,
  `tile_utils.dart:94`) → Logger; log the silent DB catch in
  `learn_pack_local_db.dart:147`.
- [ ] Drop the unused iOS "Always" location permission string (`Info.plist`) — app never
  requests Always and has no background modes.
- [ ] `geo_quiz_screen.dart` is 2,538 lines — split when next touched (timer hygiene is
  fine, verified).
- [ ] Pro-gate cards re-implemented per feature (`OverviewPremiumGateCard`,
  `TimelinePremiumGateCard`, …) — already tracked in `TODO/pro-ui-patterns-unification.md`.

## ✅ Verified healthy

Tile-downloader isolate/cancellation/backpressure mechanics; `FlightPreviewCubit` /
`DownloadFlowDelegate` lifecycle; subscription logic tests (~1,276 lines) with
server-validated entitlements; GPS lifecycle pauses in background; App Check, release
minification, ATS/cleartext defaults, no committed secrets; privacy-conscious telemetry
(anonymous auth, no session replay, Logger no-ops in release); i18n 100% complete ×4
locales; zero hand-written lint suppressions; zero commented-out code.

## Suggested order

1 (data loss) → 2 (crash) → 10 (CI + green suite) → 3 + 6 (offline migration, image
leaks) → 12 dashboard items (~5 minutes) → rest opportunistically.
