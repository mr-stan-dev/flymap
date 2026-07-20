# Route Story — AI route-description article (feature spec)

Status: **planned, not implemented.** This documents the design agreed in July 2026 so it
can be built later. It spans three repos: `flymap-app` (Flutter, primary), `flymap-backend`
(Firebase Cloud Functions, OpenAI), and mirrors the existing `flymap-web` articles pipeline
for content shape.

Internal identifiers used throughout: the new flow step is `CreateFlightStep.routeDescription`,
the app model is `RouteArticle`, the paywall source is `PaywallSource.routeDescription`, and the
backend callable is `get_route_article`. User-facing name: **"Route story."**

---

## 1. Goal & user story

When a user creates a new flight, after they preview the map by regions and **before** the
Wikipedia-articles step, show them a formatted, magazine-style description of what they will fly
over — the same window-view narration style as the web articles at
`https://flymap.app/articles/<slug>` (e.g. `london-dubai-black-sea-desert-route`), with a hero
route map and a few region maps.

- **Free users** see the hero image, title, and an intro preview, then a *Subscribe* gate that
  hides the rest of the story.
- **Pro users** (or free users who subscribe from the gate) see the full article, including up to
  4–5 key-region maps.
- Unlike the web, where an editor pastes ChatGPT output into Sanity by hand, the app generates the
  article **on demand via the OpenAI API through a Firebase callable**, cached per route.

The step is a **value-add, not a wall**: a *Continue* button is always available, so a free user
can proceed to the Wikipedia step without subscribing. The gate only hides the remainder of the
article body.

---

## 2. How the web pipeline works today (context)

Reference implementation we are mirroring for content shape:

1. `flymap-web/src/features/article-builder/ArticleBuilderAdmin.tsx` — an admin searches a route,
   pulls a historical FR24 track, and builds a "dossier" of regions + POIs + geometry, plus static
   Mapbox map JPGs (a hero + one per region).
2. `flymap-web/src/features/article-builder/promptBuilder.ts` (`buildArticlePrompt()`) emits a
   copy-ready ChatGPT prompt instructing the model to return **one JSON object**:
   `{ title, slug, excerpt, seo, route, hero, images[], body }`. `body` is a **constrained
   Markdown** string that must start at `##` and end with `## Route summary`, using
   `[IMAGE: id]` placeholders. It rotates 5 stylistic templates seeded by the route.
3. The editor pastes the prompt into ChatGPT, pastes the JSON back into Sanity Studio's `importJson`
   field, and uploads the map images separately.
4. `flymap-web/src/features/articles/articleMarkdown.tsx` (~400 lines, dependency-free) parses the
   Markdown into typed blocks and renders them, resolving `[IMAGE: id]` against uploaded assets.

The mobile version keeps the **content contract** (constrained Markdown, second-person window-view
tone, `## Route summary` ending) but replaces the manual LLM step with an API call, drops the CMS,
and generates images on-device from route geometry instead of hand-uploading them.

---

## 3. UX & placement

The create-flight preview is a **state machine**, not a wizard:
`CreateFlightStep { routeNotSupported, overview, wikipediaArticles }` in
`flight_preview_state.dart`. The body widget swaps on `state.step`. We insert `routeDescription`
between `overview` and `wikipediaArticles`:

```
overview (region preview)  ->  routeDescription (Route story)  ->  wikipediaArticles
```

### Screen layout (`routeDescription` step)

Top-to-bottom, scrollable:

1. **Hero image** — a full-route static map (always shown, free and Pro).
2. **Title** (`titleLarge`).
3. **Intro** — excerpt + the first body section (the free preview).
4. Then, branching on `SubscriptionCubit.state.isPro`:
   - **Free:** a premium gate teaser (reuse `OverviewPremiumGateCard`) — "Unlock the full route
     story" + a *Subscribe* CTA. The remaining body is not rendered.
   - **Pro / after purchase:** the full body, including up to 4–5 key-region maps (lazy-loaded on
     scroll), ending in the *Route summary*.
5. **Continue** button → advances to `wikipediaArticles`. Always present.

States: a skeleton/spinner while the article is generating; a lightweight, skippable error row if
generation fails (never blocks *Continue*).

---

## 4. Architecture

```
                    flymap-app (Flutter)                         flymap-backend (Functions)
  ┌───────────────────────────────────────────────┐        ┌──────────────────────────────────┐
  │ FlightPreviewCubit                              │        │ get_route_article (onCall)        │
  │  └ prefetch during overview (unawaited)         │ https  │  ├ validation/routeArticleParams  │
  │      → GetRouteArticleUseCase                    │───────▶│  ├ Firestore cache route_articles │
  │          → RouteArticleApi (httpsCallable)       │        │  │    (get→TTL→miss→gen→set)      │
  │                                                  │◀───────│  └ openai.fetchRouteArticle()     │
  │ RouteArticle (title, excerpt, body md, qids)     │  JSON  │       → OpenAI Responses API      │
  │  └ RouteArticleMarkdown → List<ArticleBlock>     │        │          (stored prompt)          │
  │                                                  │        └──────────────────────────────────┘
  │ Rendering (native blocks) + gating:              │
  │  ├ Hero map     ┐  reuse MapboxStaticImageApi +   │        Images are on-device only — no
  │  ├ Region maps  ┘  StaticRouteMap + SharePainter  │        backend/Storage step required for v1.
  │  └ Premium gate → RoutePremiumGateInteractions    │
  └───────────────────────────────────────────────┘
```

Key reuse: text generation, caching, error mapping, and auth all follow the **existing**
`get_flight_wiki_articles` path; images reuse the **existing** share-card static-map compositor.
Almost nothing is built from scratch.

---

## 5. Backend — `get_route_article` callable

Backend is plain JavaScript, Node 20, `firebase-functions` v2 `onCall`. OpenAI is **already
integrated** (two live callables use the Responses API with dashboard-stored prompts; the
`OPENAI_API_KEY` is provisioned in `functions/openai_key.local.js`). This is a near-clone of
`callables/getFlightWikiArticles.js`.

### 5.1 New pieces

1. **OpenAI dashboard prompt** — a new stored prompt for route articles. Port the instruction text
   and the 5 stylistic templates from `flymap-web/.../promptBuilder.ts` `buildArticlePrompt()`.
   Variables: `airport_departure`, `airport_arrival`, `waypoints`, `regions`, `distance_km`,
   `duration_min`, `lang`, `user_interests`.
2. **`functions/openai.js`** → add `fetchRouteArticle(departure, arrival, waypoints, regions,
   metrics, promptVersion, lang, userInterests)`, mirroring `fetchFlightWikiArticles` (reuse
   `require("./openai_key.local").OPENAI_API_KEY` and `openai.responses.create({ prompt: { id,
   version, variables }})`).
3. **`functions/callables/getRouteArticle.js`** → `onCall(CALLABLE_OPTIONS_OPENAI, ...)` with a
   `validation/routeArticleParams.js` parser, `toCallableError`, and `summarizeOpenAiResponse`
   logging. Copy the structure of `getFlightWikiArticles.js`.
4. **Firestore cache** modeled on `functions/fr24/fr24RouteCache.js`: collection `route_articles`,
   doc id = normalized key, TTL + `schemaVersion`. See 5.3.
5. Register `exports.get_route_article = createGetRouteArticle();` in `functions/index.js`.

Auth/App Check follow the existing posture (App Check present but not enforced; app signs in
anonymously). No new secret, no new region — reuse `CALLABLE_OPTIONS_OPENAI` (`us-central1`,
`512MiB`, `timeoutSeconds: 90`).

### 5.2 Request / response contract

Request (app → callable):

```jsonc
{
  "departure": { "code": "LHR", "name": "London Heathrow Airport" },
  "arrival":   { "code": "DXB", "name": "Dubai International Airport" },
  "waypoints": [[51.47, -0.45], [/* … sampled, capped ~20 like the wiki path */]],
  "regions": [
    { "qid": "Q166", "name": "Black Sea", "type": "sea", "insideKm": 320, "firstKm": 2100 }
    /* … ordered by firstKm … */
  ],
  "metrics": { "distanceKm": 6338, "durationMin": 420, "countriesCount": 13 },
  "lang": "en",
  "promptVersion": "1",
  "userInterests": ["geography", "history"]   // optional
}
```

Response (callable → app, after normalization):

```jsonc
{
  "title": "London to Dubai: The Black Sea Before the Desert",
  "excerpt": "Follow the London–Dubai flight path from the North Sea to the Arabian deserts.",
  "body": "## Leaving Britain for the North Sea\n\n…\n\n## Route summary\n- …",
  "keyRegionQids": ["Q166", "Q_alps", "Q_rub_al_khali"],   // <= 5, ordered, LLM-suggested
  "lang": "en",
  "schemaVersion": 1,
  "promptVersion": "1"
}
```

`body` is the **same constrained Markdown subset** as web: `##`/`###` headings, paragraphs,
bullet/numbered lists, one-line blockquotes, inline `**bold**` / `*italic*` / `` `code` `` /
`[text](href)`. It must end with `## Route summary`. We drop `slug`, `seo`, `hero`, and inline
`[IMAGE:]` placeholders (images are placed by the app — see §7).

`keyRegionQids` is the model's **suggestion** of the most story-worthy regions; the app validates
these against its own `routeRegions` and caps at 5 (see §7.2). It is advisory, not trusted.

### 5.3 Firestore cache

Collection `route_articles`, doc id:

```
`${dep}__${arr}__${source}__${lang}__v${promptVersion}`
// e.g.  LHR__DXB__greatCircle__en__v1
```

Include `source` (`greatCircle` vs `fr24Historical`) because the regions/waypoints — and therefore
the article — differ between a synthetic great-circle route and a historical track. Document shape
mirrors `fr24RouteCache.js`:

```jsonc
{
  "schemaVersion": 1,
  "article": { /* the normalized response above */ },
  "expiresAt": 1799999999999,     // Date.now() + TTL; miss when expired
  "updatedAt": "<serverTimestamp>"
}
```

Suggested TTL 30 days (same as FR24 caches). Bumping `promptVersion` or `schemaVersion` naturally
invalidates old entries by changing the key / failing the version check. Text is generated **once
per route globally**; every subsequent user (free or Pro) hits the cache.

---

## 6. App — data layer

Mirror `lib/data/api/route_overview_api.dart` and the wiki use-case.

- **`lib/domain/entity/route_article.dart`** — new `RouteArticle` (Equatable):

  ```dart
  class RouteArticle extends Equatable {
    const RouteArticle({
      required this.title,
      required this.excerpt,
      required this.body,            // constrained markdown
      required this.keyRegionQids,   // <= 5, validated against routeRegions
      required this.lang,
    });
    // + fromJson / toJson for the callable payload and for optional flight persistence
  }
  ```

- **`lib/data/api/route_article_api.dart`** — `RouteArticleApi`; `FirebaseFunctions.instance
  .httpsCallable('get_route_article').call(payload).timeout(...)`, decode-if-String, throw on
  non-object, `FirebaseFunctionsException` handling. Copy `route_overview_api.dart` verbatim in
  structure.

- **`lib/domain/usecase/get_route_article_use_case.dart`** — builds the request from
  `FlightPreviewState` (airports, `flightRoute.waypointLatLngs` sampled, `routeRegions` → the
  `regions` array, metrics, device locale, interests) and maps the response to `RouteArticle`.

- **`lib/data/.../route_article_mapper.dart`** — JSON ⇄ `RouteArticle`.

- **`RouteArticleMarkdown` parser** (`lib/ui/screens/create_flight/.../route_article_markdown.dart`)
  — a Dart port of `articleMarkdown.tsx`. Produces `List<ArticleBlock>` where
  `ArticleBlock` is a sealed/`sealed class` union: `Heading(level, text)`, `Paragraph(text)`,
  `UnorderedList(items)`, `OrderedList(items)`, `Blockquote(text)`, plus `RegionMap(qid)` blocks
  **injected by the step** (not parsed from the body — see §7.2). Inline spans (`bold/italic/
  code/link`) map to `TextSpan`s. This native block list (vs a WebView) is what lets us splice the
  paywall gate mid-content and lazy-mount region maps.
  - Alternative considered: `flutter_markdown` split into two `MarkdownBody`s around the gate.
    Rejected — less control over styling, region-map injection, and the gate boundary.

Register `RouteArticleApi` + `GetRouteArticleUseCase` in `lib/di/di_module.dart`.

---

## 7. Images — hero + key-region maps

**No new dependency.** The app already ships the full static-map compositor used by the share-card
feature:

- `lib/data/api/mapbox_static_image_api.dart` — `MapboxStaticImageApi.fetchStaticMapImage(center,
  zoom, width, height)` → PNG bytes (token via `MapboxEnvConfig`, `--dart-define=MAPBOX_ACCESS_TOKEN`).
- `lib/domain/usecase/generate_share_image_use_case.dart` — the pattern: fetch clean static map →
  decode to `ui.Image` → composite route line + markers via `ShareImagePainter` → export.
- `lib/ui/screens/share_flight/utils/static_route_map.dart` — `StaticRouteMap.buildViewport(points,
  width, height, padding)` frames an arbitrary point set; `projectRoute(...)` projects geo→pixel.
- `RouteRegion.geometry` is raw **GeoJSON** (`RouteRegionGeometry { type, geoJson }`), on
  `state.routeRegions` — the shapes needed to frame a per-region map are already on-device.

### 7.1 Which images, and the free/Pro split (the two constraints)

- **Hero** = full-route map. Points = `flightRoute.waypointLatLngs`, framed by
  `StaticRouteMap.buildViewport`, route line composited on top. Shown to **everyone**.
- **Key-region maps** = at most **4–5**, each framed on one region's geometry with the route
  segment through it highlighted. Placed within the article body (§7.2).
- **Free users generate only the hero.** This is automatic, not a special case: region-map blocks
  live in the **gated** portion of the body, which is never mounted for a locked (free) view. So a
  free view issues exactly **one** Mapbox request (the hero); region maps are fetched lazily only
  when the unlocked body renders (Pro, or immediately after purchase). See §10 (cost).

### 7.2 Key-region selection (deterministic, LLM-advised)

The app owns final image placement; the LLM only advises.

1. Take `keyRegionQids` from the response, **validate** each against `state.routeRegions` (drop
   unknown qids), preserve order, cap at 5.
2. **Fallback** if fewer than N valid (or the field is missing): rank `routeRegions` by a salience
   score and take the top N:
   - prefer scenic `RouteRegionType`s (`ocean`, `sea`, `mountainRange`, `desert`, `island`,
     `glacier`, …) over generic `country` / `state`;
   - weight by `pathLengthInsideKm` (more route time inside → more screen-worthy);
   - then sort the chosen set by `pathFirstEncounterKm` for display order.
3. For each chosen region, inject a `RegionMap(qid)` block into the block list, positioned **after
   the body section that mentions it** (match section heading text → region name; else append after
   the intro-following sections in route order).

`N` (default 5) and the salience weights are the tuning knobs; put them in a small
`RouteArticleImagePolicy` analogous to `RouteRegionPremiumGatePolicy`.

### 7.3 Rendering, caching, attribution

- Each map block is a widget that renders bytes from a `Future` (fetch + composite), with a
  skeleton placeholder while loading and a graceful empty state on failure (never blocks the
  article). Mirror how the share pipeline decodes/composites.
- **Cache composited bytes on-device** keyed by a deterministic map key (`routeCode` for the hero;
  `region.qid` + style + size for region maps) so repeat views and re-entry cost nothing.
- **Attribution is mandatory** — Mapbox static tiles carry no baked attribution (see
  `map_frame_renderer.dart`), so every article map must overlay `© Mapbox © OpenStreetMap © Maxar`
  (string reused from the video renderer's `defaultAttribution`).
- **Optional later optimization:** cache composited bytes in Firebase Storage keyed by the same map
  key, so a popular route/region is rendered once *globally* rather than once per device. Not
  required for v1.

---

## 8. Paywall & gating

RevenueCat; the "preview-then-gate" pattern already exists in this exact flow (the region gate in
the overview step).

- **Entitlement:** read `context.read<SubscriptionCubit>().state.isPro` inside a
  `BlocBuilder<SubscriptionCubit, SubscriptionState>` so the body re-renders the instant Pro status
  changes (the cubit republishes RevenueCat's `CustomerInfo` stream).
- **Present paywall:** reuse `RoutePremiumGateInteractions.onGateTap(context:, source:
  PaywallSource.routeDescription, useOfflineInfoSheet: false, onActivated: …)`. It early-outs if
  already Pro, presents RevenueCat's native paywall, and runs `onActivated` on purchase.
- **Teaser card:** reuse `OverviewPremiumGateCard` (title / description / ctaLabel / onTap) — or a
  thin `RouteStoryGateCard` if the layout needs to differ.
- **New `PaywallSource` value:** add `routeDescription` to `lib/subscription/paywall_source.dart`
  (enum + its `analyticsValue` switch).
- **Free-preview cutoff policy:** a small helper deciding how much body is free — default
  **excerpt + first `##` section**, then gate. One constant; easy to tune. (Mirror
  `RouteRegionPremiumGatePolicy`.)

Gating model for v1: **Pro subscription only** (like Learn articles). The one-off "flight unlock"
consumable (`FlightUnlockRepository`) is out of scope unless we later decide the story should be
unlockable per-flight.

---

## 9. Flow integration (state-machine changes)

Dart's exhaustive `switch` on the enum will flag every site that must change. Concretely:

1. **Enum** — add `routeDescription` to `CreateFlightStep` (`flight_preview_state.dart`). Add
   `routeArticle` (`RouteArticle?`) and `isRouteArticleLoading` (bool) to `RoutePreviewState`.
2. **Prefetch** — in `preview_preparation_delegate.dart`, alongside the existing
   `unawaited(_prefetchWiki(...))` (~line 201), add `unawaited(_prefetchRouteArticle(...))` with the
   same stale-route guard (compare `routeCode`). This starts generation while the user is still on
   the overview step, so the story is usually ready by the time they tap Continue.
3. **Boundary** — `map_and_step_navigation_delegate.dart` `continueFromOverview()` (~line 12): emit
   `step: routeDescription` instead of `wikipediaArticles`. Add `continueFromRouteDescription()`
   emitting `wikipediaArticles`. Update `handleBackAction`: `wikipediaArticles` pops to
   `routeDescription`; `routeDescription` pops to `overview`.
4. **Cubit** — add a `continueFromRouteDescription()` wrapper on `FlightPreviewCubit` (mirror
   `continueFromOverview`, ~line 116) and wire it to the step's Continue button.
5. **Four switch/util sites** in `flight_preview_screen.dart`:
   - `_buildContent` (~215): `case routeDescription:` → return the new step widget.
   - `_stepIndex` (~448): add an index for the slide animation.
   - `_titleForState` (~503): add an app-bar title + a matching i18n key.
   - the step-transition animation and any `BlocConsumer` listeners as needed.
6. **New widget** — `steps/route_description/flight_search_route_description_step.dart` taking
   `state` + `isProUser` + callbacks, structured per §3.

No `Navigator`/router changes — the whole sub-flow lives inside `FlightPreviewScreen`, driven by
`state.step`.

---

## 10. Caching & cost model

Two independent costs, both bounded:

- **OpenAI (text):** one call per `(route, lang, promptVersion)`, cached in Firestore for ~30 days.
  Free and Pro share the cache. First viewer of a route pays ~a few seconds of latency (hidden by
  the overview-step prefetch); everyone after is a cache hit.
- **Mapbox (images):** dominated by **free users = 1 request each** (hero only), because region maps
  sit behind the gate. On-device byte caching makes re-entry free. Unlocked views add ≤5 region-map
  requests, lazy on scroll. Optional Firebase Storage byte-cache collapses this to once-per-route
  globally if volume warrants.

Net: the high-traffic path (free users) is 1 cached OpenAI call shared across all users + 1 cached
hero image per device. This is the reason for constraint #2 (free = hero only).

---

## 11. Analytics, i18n, edge cases

- **Analytics** (mirror existing `PaywallSource` events + a new event file under
  `lib/analytics/events/`): step viewed; article resolved (cache hit/miss + latency); gate shown;
  paywall presented from `routeDescription`; purchase attributed to this source; continue tapped.
- **i18n** (4 locales en/de/es/fr, then `dart run slang`): step/app-bar title, loading label, gate
  card title/description/CTA, error+skip label, map attribution string.
- **Edge cases:**
  - *Generation fails / offline:* show a lightweight skippable message; never block *Continue*.
  - *Short domestic hop / no notable regions:* fewer or zero region maps; hero still renders.
  - *`routeNotSupported`:* unchanged — that branch never reaches `routeDescription`.
  - *Language:* pass device locale; the prompt takes `lang`. Cache key includes `lang`.

---

## 12. Build plan (phases)

- [ ] **A — Backend callable.** New stored prompt; `openai.fetchRouteArticle`; `getRouteArticle.js`;
  `validation/routeArticleParams.js`; `route_articles` Firestore cache; register in `index.js`.
  *Accept:* callable returns a valid normalized JSON for a sample route; second call is a cache hit.
  *(Critical path — start here; it's a near-copy of `getFlightWikiArticles`.)*
- [ ] **B — App data layer.** `RouteArticle` entity + mapper; `RouteArticleApi`;
  `GetRouteArticleUseCase`; `RouteArticleMarkdown` parser; DI registration.
  *Accept:* a unit test parses a sample body into the expected block list; the API decodes a sample
  response.
- [ ] **C — Image layer.** Hero (full-route) + region-map widgets reusing `MapboxStaticImageApi` +
  `StaticRouteMap` + compositor; `RouteArticleImagePolicy` (selection, cap N=5); on-device byte
  cache; attribution overlay.
  *Accept:* hero renders for a route; region maps render for validated qids; failure degrades
  gracefully.
- [ ] **D — Step widget + gating.** `flight_search_route_description_step.dart`; free preview cutoff;
  `OverviewPremiumGateCard` wired to `RoutePremiumGateInteractions`; `PaywallSource.routeDescription`.
  *Accept:* free view = hero + intro + gate (1 image); Pro view = full body + region maps; purchase
  expands in place.
- [ ] **E — Flow integration.** Enum + state fields; prefetch; delegate boundary + back nav; cubit
  wrapper; four switch sites; i18n titles; analytics.
  *Accept:* overview → routeDescription → wikipedia forward/back works; prefetch populates state.
- [ ] **F — Tests.** Parser unit tests; image-policy selection tests; a widget test for the step
  (free vs Pro branch, gate tap → paywall stub, Continue advances). Follow existing widget-test
  patterns.
- [ ] **G — (Extension) Offline persistence.** Persist the generated `RouteArticle` + composited
  image bytes into the saved flight (sembast, like wiki `article_media`) so it is re-readable in the
  flight's Read tab offline. Deferred; not v1.

---

## 13. Open decisions

1. **Map style** — the existing static API defaults to `mapbox/satellite-streets-v12` (the
   share/video look). Web article maps read more cartographic. Pick satellite (consistent with
   share images) or a cleaner style. One-line change in `MapboxStaticImageApi` / a per-call param.
2. **Free-preview cutoff** — excerpt only, or excerpt + first section (recommended). One constant.
3. **Prompt hosting** — OpenAI dashboard stored prompt (matches existing convention) vs inline
   prompt string in the function. Recommend stored prompt for parity + easy iteration.
4. **Prefetch vs on-demand** — prefetch during overview (recommended, hides latency) vs generate on
   step entry.
5. **Offline persistence (Phase G)** — whether the story should live with the saved flight for
   offline reading. Nice-to-have.
6. **Region-map cost ceiling** — device-only byte cache (v1) vs also Firebase Storage global cache
   (if Mapbox volume grows).

---

## 14. Key file touch-list

**flymap-backend/functions:** `openai.js` (+`fetchRouteArticle`), `callables/getRouteArticle.js`
(new), `validation/routeArticleParams.js` (new), `fr24/fr24RouteCache.js` (reference for the new
`route_articles` cache module), `index.js` (register). Reference: `callables/getFlightWikiArticles.js`,
`callables/shared/callableSupport.js`.

**flymap-app/lib:**
- `domain/entity/route_article.dart` (new), `domain/entity/route_region.dart` +
  `route_region_type.dart` (`geometry.geoJson` source), `domain/entity/flight_route.dart`
  (`waypointLatLngs`).
- `data/api/route_article_api.dart` (new; copy `route_overview_api.dart`),
  `data/api/mapbox_static_image_api.dart` + `domain/usecase/generate_share_image_use_case.dart` +
  `ui/screens/share_flight/utils/static_route_map.dart` (image reuse).
- `domain/usecase/get_route_article_use_case.dart` (new), mapper (new),
  `domain/policy/route_article_image_policy.dart` (new; cf. `route_region_premium_gate_policy.dart`).
- `ui/screens/create_flight/flight_preview/`:
  `viewmodel/flight_preview_state.dart` (enum + fields), `viewmodel/flight_preview_cubit.dart`
  (wrapper), `viewmodel/delegates/map_and_step_navigation_delegate.dart` (boundary + back),
  `viewmodel/delegates/preview_preparation_delegate.dart` (prefetch), `flight_preview_screen.dart`
  (switch sites), `steps/route_description/**` (new widget + `route_article_markdown.dart`).
- `subscription/paywall_source.dart` (new enum value),
  `ui/screens/shared/premium/route_premium_gate_interactions.dart` (reuse),
  `ui/screens/create_flight/flight_preview/steps/overview/widgets/overview_premium_gate_card.dart`
  (reuse).
- `di/di_module.dart` (registrations), `i18n/*.i18n.json` (×4), `analytics/events/**` (new event).

**flymap-web (reference only):** `src/features/article-builder/promptBuilder.ts` (prompt to port),
`src/features/articles/articleMarkdown.tsx` (parser/renderer to port),
`src/features/share-card/client/staticRouteMap.ts` (static-map URL reference).
