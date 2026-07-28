# Flight weather & cloud cover — "Will you see anything?" (feature spec)

Status: **simplified architecture decided 2026-07-28, app-side v1 in progress.**
Supersedes and absorbs section 4 of [flight_date_feature.md](flight_date_feature.md);
depends on its section 1 (travel date field), which shipped with exact STDs from
schedule picks.

> **2026-07-28 simplification (supersedes §3/§4/§5 details below):**
> - **One time slice per sample point — the "overhead time" model.** The user
>   needs the weather at each route point at the moment their plane is there,
>   which we can compute (STD + progress × block time). ~15–20 centerline
>   samples every 50–75 km, one timestamp each, instead of a grid × 24 hourly
>   slices. The rendered cloud field is time-correct along the route by
>   construction; the "timelapse" becomes our existing plane-along-path
>   animation flying over a static field. Scrubber/multi-hour deferred.
> - **No Firestore cell cache.** Cross-user corridor reuse is near zero at this
>   app's scale (same long-tail argument as the AeroDataBox cache). Politeness
>   is handled by low sample counts and limited concurrency instead.
> - **v1 is app-side only, no backend callable** — MET Norway is keyless and
>   designed for direct client use (identifying User-Agent + attribution).
>   A backend proxy remains the plan IF volume or provider swap demands it.
> - **Dedicated WEATHER STEP in flight creation** (decision 2026-07-28,
>   supersedes §3 "not a new step"): route overview → **weather step** →
>   Wikipedia articles. Airport weather + verdict + expectation line for
>   everyone; the cloud-field visualization Pro-gated.

The product promise of Flymap is "what's below you". Cloud cover is the honest
caveat to that promise, and turning it into a feature — *"will you actually see
the Alps, or a cloud carpet?"* — is uniquely on-brand. No competing flight app
answers this question.

---

## 1. The one-sentence pitch

> Before your flight, Flymap tells you **whether you'll see the ground**, what the
> weather is at both airports, and how bumpy the ride looks — and Pro users can
> **scrub a cloud timelapse along their whole route**, offline, from the window seat.

## 2. What users get

### Free tier
- **Airport weather** — departure and arrival forecast at scheduled local times:
  temp, precip, wind, visibility. Answers "jacket or t-shirt on landing?".
- **Window verdict** — one headline stat computed from the corridor cloud grid:
  *"Clear views"* / *"Patchy clouds"* / *"Cloud carpet below"* / *"Overcast —
  views at takeoff & landing only"*. This is the teaser that sells Pro: the
  verdict is free, the map behind it is not.

### Pro
- **Cloud timelapse on the map** — the corridor overlay animated hour by hour
  across the flight window. In flight, it follows the plane position (existing
  progress logic); on the ground it's a scrubbable slider. Fully offline.
- **Per-segment breakdown tied to regions** — reuse the regions-crossed data:
  *"☀️ Clear over the Alps · ☁️ overcast over Bavaria"*. This line also lands on
  the home card next to the countdown.
- ~~Bumpiness estimate~~ — **dropped (July 2026 decision, see §7)**: bad-weather
  news is unpleasant and a dedicated turbulence product was never the intent.

### Both tiers, lifecycle (the re-engagement loop)
Cloud forecasts are only credible ~3–5 days out (hourly data exists to 16 days,
skill decays fast). Stage the UX instead of pretending otherwise:

| When | What the user sees |
|---|---|
| > 7 days out | "Forecast unlocks N days before your flight" countdown |
| ≤ 7 days | First forecast + freshness stamp ("Forecast from Tue 08:00") |
| ≤ 48 h | Auto-refresh on app open, silent |
| ≤ 12 h | Final refresh on app open — the "boarding" fetch that flies with them |
| Post-flight | (v3) re-fetch *observed* clouds → replay + share stamp |

Never ask "do you want to update?" — refresh silently on app open inside the
window and show the freshness stamp. A manual refresh button exists on the
weather card. The "forecast is ready" moment is the natural payload for the
day-before local notification planned in flight_date_feature.md §3.

## 3. Where it lives in the flows

- **Flight creation**: NOT a new full-screen step. One "When are you flying?"
  row on the existing download/summary step (per flight_date_feature.md: ask at
  the end). Weather data joins the download bundle silently — it is noise-level
  small next to mbtiles (§5).
- **Download completed screen**: payoff line — "Your window forecast will be
  ready on ⟨date − 7d⟩" or, if within range, the verdict immediately.
- **Flight screen**: weather card (airports + verdict; Pro: open timelapse).
- **Home card**: countdown already planned; add verdict emoji + region line when
  forecast is live. One line, no layout rework.
- **In flight**: timelapse layer toggle on the map, defaulting to "now" at the
  plane position.

## 4. Data architecture — a cloud *grid*, not cloud *tiles*

The defining constraint is **offline**. Raster forecast tiles (OpenWeatherMap
Weather Maps 2.0 etc.) are paid, and pre-downloading a tile pyramid × zooms ×
24+ timestamps per flight is megabytes of mostly-wasted raster. Wrong tool.

Instead: **sample the forecast on a grid along the corridor and render the
overlay ourselves** in MapLibre.

- Sample points every ~25 km along the route polyline, ± 1–2 lateral offsets
  across the corridor width (the corridor geometry already exists server-side).
- Per point, hourly for departure−2h … arrival+2h: `cloud_cover_low/mid/high`,
  `visibility`, `precipitation`, plus airport points with surface variables.
- Payload: ~80 points × ~24 h × ~6 vars ≈ 50–150 KB gzipped JSON. Trivial next
  to the map download; cache it in the flight bundle like POIs/wiki.
- Rendering: corridor cells as a MapLibre fill layer, two visual plies — dense
  low/mid cloud (opaque white, soft edges) and thin high cirrus (translucent
  veil). Timelapse = restyling by timestamp index; no new tiles, no reload.
  Interpolate between hours for smooth scrubbing.
- Bonus: post-flight replay and share-card stamps reuse the same grid.

**Verdict algorithm** (window score): ground is hidden by `low + mid` cover;
heavy `low` with clear above = "cloud carpet" (still pretty — frame it
positively); `high` only = "ground visible through thin haze" (cruise ≈ 10–12 km
sits inside/above high band). Weight by segment length; produce one overall
verdict + per-segment values for the Pro breakdown.

## 5. Providers (decision + rationale)

**Start free: MET Norway Locationforecast 2.0 (api.met.no)** — free **including
commercial use** (public service; CC-BY-style attribution + a unique
`User-Agent` identifying the app are mandatory, ~20 req/s soft limit — be
polite and cache). Crucially it has the same three-band variables
(`cloud_area_fraction_low/_medium/_high`), global coverage, ~9–10 day horizon
(hourly near-term, 6-hourly further out). Limitations vs Open-Meteo: **one
coordinate per request** (a corridor = ~30–40 sequential calls — fine with the
backend cell cache), no batch, no historical archive (post-flight replay would
need another source later). Perfect for proving the feature at $0.

**Upgrade when proven: Open-Meteo** — the whole feature runs on this one API.
- Has exactly the needed variables: `cloud_cover(_low/_mid/_high)`, visibility,
  precipitation, wind, CAPE, freezing level, **pressure-level winds** (for the
  bumpiness estimate), hourly to 16 days; plus a historical/ERA5 archive API for
  post-flight replay.
- Batches many coordinates in one request (comma-separated lat/lon lists) — one
  or two calls fetch a whole flight's grid.
- Pricing (verified July 2026): free tier is **non-commercial only** (10k
  calls/day); commercial **API Standard $29/month, 1M calls** — one call ≈ one
  flight refresh, so 1M calls is far beyond our volume. No overage billing.
- Switch trigger: feature retention proves out, or MET Norway call volume /
  courtesy limits start to pinch. The grid schema is provider-agnostic by
  design, so the swap is a backend-only change.
- Either way, access via a **backend callable proxy** (consistent with the FR24
  pattern): key/User-Agent stays server-side, and popular corridors can be
  cached per (cell, model-run) in Firestore to dedupe.
- Endgame at real scale (optional): ECMWF/GFS open data GRIBs processed by a
  scheduled backend job — $0 per call, but real pipeline work; not before the
  feature earns it.

**Garnish (optional, free, no key): aviationweather.gov** — METAR/TAF for the
airports, decoded ("RWY visibility 10 km, broken at 2,500 ft"). Avgeek
credibility; also SIGMET polygons later for real severe-weather areas.

**Explicitly not chosen**
- OpenWeatherMap tiles: forecast tiles are a paid tier, raster unfit for the
  offline bundle, generic look vs. our own styled overlay.
- RainViewer: observational nowcast only (~2 h), licensing for commercial apps
  unclear — useless for a 3-days-out forecast.
- NASA GIBS satellite imagery (free WMTS): **observational only** — no forecast.
  Keep as v3 candidate for a "real satellite replay" of the completed flight.

## 6. Flight date & time acquisition

Weather needs a **time**, not just the date-only field from
flight_date_feature.md — the timelapse, verdict and sun position are all
time-of-day dependent. Extend the schema:

- `scheduledDepartureUtc` (nullable instant) + `departureUtcOffsetMinutes`
  captured at fetch time, + planned duration → arrival estimate. Date-only
  remains valid (lifecycle features work); weather then uses midday ± "estimate"
  badge, or daily-level cloud outlook only.
- Airport timezones: airports.csv has **no tz column**. Resolve the UTC offset
  via Open-Meteo's `timezone=auto` response (`utc_offset_seconds`) *for the
  travel date* — DST-correct, no bundled tz database, no extra provider.

**Manual/route flights (free users):** date + time picker row (departure local
time). Time optional; skipping degrades gracefully as above.

**Flight-number flights:** the official FR24 API (which the backend uses —
`fr24api.flightradar24.com` v1) has **no future-schedule endpoint** — verified
July 2026: live positions, historic positions, flight summary (historic, from
May 2016), flight tracks, airline/airport info. `flight-summary` windows end at
"now"; there is nothing to fetch for a flight that hasn't departed.

**Decision July 2026: real schedule data, not inference.** Deriving date/time
from recent ops (weekday-modal takeoff time + confirm step) was considered and
rejected on UX grounds — the user should pick from *actual* upcoming flights:
"LH1234 — Mon 3 Aug 09:15 · Tue 4 Aug 09:15 · …", one tap, times included.
Recent-ops inference survives only as the **offline/miss fallback** (always
behind an editable confirm, never silent).

Provider landscape for schedules (verified July 2026) — the uncomfortable
truth is that **no affordable single provider covers both positional history
(tracks) and future schedules**:

| Provider | Future schedules | Historic GPS tracks | Commercial floor |
|---|---|---|---|
| FR24 official API (current) | ❌ none | ✅ excellent | already paying |
| FlightAware AeroAPI | ✅ 12 months out | ✅ back to 2011 | **$200/mo minimum** (Standard; the $5-credit Personal tier is personal/academic only) |
| AeroDataBox | ✅ `/flights/number/{num}/{date}` | ❌ no track polylines | ~$5–30/mo tiers |
| aviationstack / AirLabs / Aviation Edge | ✅ schedule records | ❌ | ~$10–50/mo |
| ADS-B Exchange / airplanes.live | ❌ | ✅ | varies |

So the choice is: (a) migrate everything to AeroAPI for one-provider purity at
$200/mo minimum + track-quality migration risk, or (b) keep FR24 for
routes/tracks and bolt on a **schedule-only lookup** (one endpoint: number +
date → STD/STA) behind the same callable. The schedule surface is tiny and
isolated — trivially swappable — which makes (b) the pragmatic default.

**Decision 2026-07-27: AeroDataBox it is.** Stan has an account (free tier).
Verified 2026-07-27: the **date-range endpoint**
(`/flights/number/{num}/{dateFrom}/{dateTo}`) covers the whole 7-day window in
ONE call (max range is plan-dependent, 7–30 days; 7 on lower plans — exact
fit). Pricing (RapidAPI): Free 600 units/mo → Pro $5.35/mo 6,000 → Ultra
$32/mo 60,000; endpoints cost 1/2/6 units by tier — the flights-by-number
range endpoint is **Tier 2 (2 units/call, confirmed 2026-07-27)**.
**Every path costs a flat 2 units** (decision 2026-07-27, Stan's
simplification): airport-pair search keeps today's two-step UX — FR24
candidates first (0 ADB units), user picks a flight number, THEN one range
call for that number's 7-day schedule. No per-number fan-out; a route-search
fan-out callable was built and deliberately deleted. Free ≈ 300 selections/mo
(plenty for dev), Pro ≈ 3,000. Abandoned searches cost zero.
**Caching: deliberately light** — cross-user same-number+date hits are rare at
this app's scale (long-tail flight numbers), so only a short-TTL (~1h)
retry-absorber cache + a unit-usage log; revisit only if telemetry says so.
The provider client stays behind its own backend module boundary (like
`fr24/`) so a later provider swap touches one file.

**Release decision 2026-07-27: no partial releases.** The flight-date feature
ships as ONE release: date + upcoming-flight search + lifecycle payoffs —
WITHOUT weather. Weather remains the follow-up that reuses the schema
(`scheduledDepartureUtc` + `departureUtcOffsetMinutes` stored from day one).

**Flow decision 2026-07-27 (revised same day): pick number first, then date.**
For real flights the user reaches a dated 7-day schedule list ("Tue 4 Aug ·
09:15") via `search_upcoming_flights_by_number` — soft-gated beyond 7 days
with a dateless escape hatch. Flight-number search: number → dated list
directly. Airport-pair search: KEEPS today's candidate step (FR24, 0 ADB
units) — the user picks the flight number exactly as now, and only then the
schedule call runs for that one number. Backend stitches each upcoming
departure to the most recent RECORDED FR24 leg of the same number+pair, so
the track/corridor pipeline is unchanged. Approximate flights get an optional
manual date-only chip row instead (see flight_date_feature.md).

## 7. Turbulence / severe weather — dropped (July 2026 decision)

The original voice note meant only "warn if there's a storm on the route", not
a turbulence forecast product — and on reflection even that is **unpleasant
news with no user action attached**, so it is cut from the feature entirely.

Two things preserve the value without the dread:
- Storms are already **visible implicitly** in the cloud timelapse (dense dark
  cells + precipitation) — no scary labels required; users who can read a sky
  will read it.
- Optional **good-news-only** line: when winds aloft + CAPE are clearly benign,
  show "✨ Smooth skies expected". When they aren't — show *nothing*. Silence,
  never warnings. (Cheap to compute from the same fetch; ship only if copy
  feels right in testing.)

## 8. Zero-API extras that make it magical

- **Sun-side recommendation** — pure local math (solar azimuth vs. heading
  along route at actual times): *"Sit on the LEFT — sunset over the sea at
  18:40."* Needs only the time field; no network. Highly shareable; candidate
  to pull forward into phase 1.
- **Golden hour / sunset window on the timelapse** — day/night shading along
  the corridor; night segments show city-lights framing instead of clouds copy
  ("clear night — you'll see the lights of Vienna").
- **Share-card stamp** — verdict emoji + "70% clear views" on the existing
  share card; post-flight version uses observed data ("flew above the clouds").

## 9. Free/Pro split (decided)

| Capability | Free | Pro |
|---|---|---|
| Airport weather (dep/arr) | ✅ | ✅ |
| Window verdict (one stat) | ✅ teaser | ✅ |
| Cloud timelapse on map | — | ✅ |
| Per-segment/region breakdown | — | ✅ |
| "Smooth skies" good-news-only line (optional) | — | ✅ |
| Sun-side tip | ✅ (it markets the app) | ✅ |

## 10. Phasing

- **Phase 0 (prereq)** — date+time schema + migration; "When are you flying?"
  row on download step; schedule lookup for flight-number flights (provider
  TBD, §6) with recent-ops prefill as offline fallback. (Ships the
  flight_date_feature.md v1 lifecycle wins for free.)
- **Phase 1** — backend weather callable (MET Norway first, §5; corridor
  sampling + Firestore cell cache); airport weather card; verdict; cloud grid
  in the offline bundle; Pro timelapse layer + scrubber; staged refresh policy.
- **Phase 2** — sun-side + golden hour; forecast-ready notification (with
  flight_date v2); paywall bullet ("See if you'll see"); optional "smooth
  skies" good-news line; Open-Meteo switch if volume warrants.
- **Phase 3** — post-flight observed replay + share stamp (needs a historical
  source — Open-Meteo archive or ERA5); NASA GIBS satellite replay experiment.

## 11. Risks & open questions

- **Forecast disappointment risk**: a wrong "clear views" call burns trust —
  always show forecast age + "forecasts firm up closer to departure" copy on
  first render; verdict copy uses hedged language beyond 3 days out.
- **MET Norway terms compliance** is the launch gate for the $0 start:
  identifying User-Agent, attribution in-app ("Weather data: MET Norway"),
  polite request rates via the backend cache. Open-Meteo ($29/mo) is the paid
  upgrade once proven; its free tier is non-commercial and not an option.
- Corridor cell cache hit-rate is unproven — measure before optimizing.
- In-flight refresh is impossible (offline) — the ≤12 h "boarding fetch" is the
  last data; make the freshness stamp visible in flight so stale ≠ wrong.
- A rendering mock of the cloud grid (corridor-only, low/mid/high plies,
  scrubber, per-segment verdicts) was built July 2026 to validate the visual
  direction before implementation.
