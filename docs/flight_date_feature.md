# Flight date — optional travel date on flights (feature spec)

Status: **planned, not implemented.** Decision made July 2026: we will add an optional
travel date to flights, but not in the current iteration. This documents the agreed
motivation, design constraints, and the future features the date unlocks, so it can be
built later without re-litigating the "why".

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
