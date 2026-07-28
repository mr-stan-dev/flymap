# Flight date — optional travel date on flights (feature spec)

Status: **implemented 2026-07-27 (uncommitted), pending device verification.**
Backend `search_upcoming_flights_by_number` is deployed to production (create-only
deploy, existing functions untouched; smoke-tested live with LH1114). App side built:
`FlightSchedule` on `Flight` (+ `Flight.copyWith`, all rebuild sites converted),
DB persistence under the `schedule` key (no migration, legacy reads null), a dedicated
"When are you flying?" step (`TravelDatePickScreen`, route `/travel-date`) that
EVERY create-flight flow passes through before the route overview — the user
picks the flight/route first (one card per distinct flight, dates deduplicated
away), then the date on this step: real flights list the number's actual
scheduled departure days with times (7-day window; airport-pair flow fetches
them on this step, number flow passes them along from the search), approximate
and schedule-less flights get a generic Today..+6 list; both end with a
custom-date row (up to a year ahead, date-only) and a "continue without a
date" escape hatch, with the beyond-7-days freshness hint for real flights.
The travel-date step is the ONLY place a date is picked — the download
(Wikipedia articles) screen has no date UI. Home-card countdown pill
("Today · 09:15" / "Tomorrow" / "In X days") and date-aware sorting (dated
upcoming first, soonest on top). NOT built: past-date archive prompt, day-of
notification. The rest of this doc records the agreed motivation and design
constraints.

> **Update 2026-07-27 — release shape decided (supersedes entry-point details
> below):** ships as ONE release, not in parts, WITHOUT weather. Final flow:
>
> - **Real flights: the search results ARE the date picker.** Searching by
>   flight number or airport pair shows actual UPCOMING departures for the
>   next 7 days ("LH1114 · Tue 4 Aug 09:15"), via AeroDataBox (account exists,
>   free tier for dev). Picking one sets number + route + date + time in a
>   single tap — no separate date step. Beyond 7 days: soft gate — a polite
>   note that maps are most accurate within 7 days of the flight, plus a
>   "save without a date" escape hatch (today's dateless flow). Schedule miss
>   (charters, seasonal): fall back to the current historical-candidate flow,
>   dateless.
> - **Approximate flights: optional manual date.** A skippable
>   `[Today] [Tomorrow] [📅 Pick date]` chip row on the download step,
>   date-only, no time. Rationale for including them: the day-before
>   notification, countdown, sorting and archive are date-only and
>   flight-type-blind — free users are the biggest population and the
>   conversion pool, and a half-sorted home list would read as a bug.
> - **Schema stored from day one (weather-ready):** `travelDate` (date-only,
>   always optional) on every flight; `scheduledDepartureUtc` +
>   `departureUtcOffsetMinutes` only from schedule picks. Never prefill from
>   FR24 `historicalFlightDate` (stale cache).
> - Corridor/track still builds from the most recent RECORDED FR24 leg; the
>   schedule pick is stitched to it by flight number + airport pair behind
>   the scenes (see flight_weather_feature.md §6 for the backend shape).

Context for the decision: the date buys **nothing for data fetching today** — flights
download the most recent route/track regardless of date, and there is no per-date
schedule data. The value is in lifecycle, framing, and the date-dependent features below.
At least one real user has already looked for a "select flight date" field during flight
creation, which signals the mental-model gap: users think of a flight as a dated trip,
the app currently treats it as an undated saved route.

---

## 1. Data model & entry (the foundation)

- Optional `DateTime? travelDate` on `Flight` — **date-only semantics, no time of day**
  (time adds timezone pain and entry friction for near-zero value; a scheduled departure
  time could later come from FR24 operational data instead of manual entry).
- Nullable field + DB migration; legacy and dateless flights behave exactly as today.
  The date must never be required — every flow works unchanged when it is skipped.
- Entry points: an optional "When are you flying?" row on the route summary / download
  step of flight creation (ask at the end, not the beginning), and editable later from
  the flight screen — that is where the user who asked went looking for it.

## 2. v1 uses (no backend, ship with the field)

1. **Lifecycle**: flights with a past date get an "archive?" prompt on home open (or
   auto-archive with undo). Keeps "Upcoming flights (N)" honest without user discipline.
2. **Framing**: card headline countdown — "In 3 days" / "Tomorrow" / "Today ✈" — in the
   home card subtitle slot (flight number • places teaser • regions).
3. **Sorting**: upcoming list orders dated flights by travel date first, undated ones by
   the current recency order after them.

## 3. Day-of-flight notification (v2, the payoff)

Local notification, no backend needed: "Your flight is tomorrow — your offline map for
Vienna → Lisbon is ready." Also serves as the reminder to actually use the app in-flight
(a user who downloaded a map three weeks ago has likely forgotten). Best single
re-engagement lever this app can have; requires notification permission priming, which
should be requested in context (when the user sets a date), never during onboarding.

## 4. Weather / cloud-cover preview (v3, user idea from July 2026)

> **Superseded July 2026:** this section grew into a full spec of its own —
> see [flight_weather_feature.md](flight_weather_feature.md) (cloud grid +
> timelapse, provider decision, date/time acquisition incl. FR24 findings).

With a travel date we can fetch, close to the date:

- **Airport weather** for departure and arrival (forecast at the airports on the day).
- **Cloud cover along the route** — the differentiating one: overcast forecast along the
  corridor tells the user **whether they will see anything from the window at all**.
  This is uniquely on-brand for Flymap: the whole product promise is "what's below you",
  and cloud cover is the honest caveat. Could render as a simple per-segment
  clear/partly/overcast strip on the flight screen (or on the home card near the date),
  fetched 1–2 days before the travel date, cached offline with the flight.
- Candidate sources: any forecast API with gridded cloud-cover (e.g. Open-Meteo exposes
  cloud cover by lat/lon/hour, free tier, no key) sampled at a few waypoints along the
  route. Needs a backend proxy decision (direct from app vs. via Cloud Function) at
  build time.

## 5. Stale-route refresh (v3+)

"You saved this flight 3 weeks ago — want to re-check the route the day before?" A
date makes re-fetching the latest track/schedule meaningful right before the trip.
Optional prompt, never automatic (consistent with the user-triggered-fetch principle
from the real-route upgrade flow).

---

Build order when picked up: **1 → 2 → 3**, with 4 and 5 as separate follow-ups.
Effort for 1+2: moderate (nullable entity field + migration, one picker row, three card/
list touchpoints). The migration is low-risk because the field is nullable.
