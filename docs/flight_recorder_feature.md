# Flight Recorder — motion sensors in flight + post-flight recap (feature spec)

Status: **spec'd 2026-08-01; live-dashboard v1 shipped same day.** Background
recording (§2) and the recap (§4.5) remain unbuilt.

> **v1 shipped 2026-08-01 — the open-app motion dashboard.** Added `sensors_plus`
> (^6.1.0) + iOS `NSMotionUsageDescription`. New `MotionSensorService`
> ([lib/data/motion/](../lib/data/motion/)) fuses accelerometer + barometer into
> a `MotionSample` (total g + a low-passed `smoothedTotalG`, signed vertical g,
> horizontal g, auto-calibrated fore-aft longitudinal g, cabin pressure);
> physics + smoothing covered by unit tests ([test/data/motion/](../test/data/motion/)).
> New `FlightMotionSection`
> ([.../dashboard/motion/](../lib/ui/screens/flight/widgets/tabs/dashboard/motion/))
> sits at the **bottom** of the dashboard (below the GPS panel) in
> [dashboard_tab_view.dart](../lib/ui/screens/flight/widgets/tabs/dashboard/dashboard_tab_view.dart)
> — treated as secondary metrics — but still renders with no GPS fix.
>
> **Live tiles:** (1) **G-force** 180° gauge — the live needle uses a light
> ~0.25 s low-pass (responsive, de-jittered); **peak-hold** uses a separate
> heavier ~0.5 s low-pass so a brief tap can't set a false record while real
> turbulence/landings do (peak-hold + `resetPeak` live in the service, exposed
> as `MotionSample.peakG`); the peak dot is coloured by the peak's own g level;
> **tap the PEAK chip to reset**. Shows apparent-weight %.
> (2) **Cabin pressure** bar with a "feels like X cabin altitude" hint
> (barometric formula).
>
> **Permissions (opt-in, no prompt on entry).** The accelerometer needs no
> permission, so g-force runs immediately. The barometer needs Motion & Fitness
> on iOS, so it is split out of `start()` into `startBarometer()` and started
> only when allowed: Android starts it directly; iOS checks `Permission.sensors`
> and, if not granted, shows a **`CabinPressureEnableCard`** with an Enable
> button that requests it (never auto-prompted). No barometer hardware → the
> section is omitted entirely. **iOS build note:** `ios/Podfile` sets
> `PERMISSION_SENSORS=1` (permission_handler compiles the sensors strategy out
> otherwise) + `NSMotionUsageDescription` in Info.plist; needs `pod install`.
>
> **Per-section info sheets:** a reusable `MetricInfoSection` overlays an info
> button in every dashboard section's top-right corner ([metric_info.dart](../lib/ui/screens/flight/widgets/tabs/dashboard/metric_info.dart))
> → bottom sheet explaining what the metric means and why it's interesting.
> Wired onto G-force, cabin pressure, ground speed, altitude, heading, and
> outside temperature. Bodies localized across en/de/es/fr.
>
> **Cabin feel (side-view passenger)** was built then **removed** 2026-08-01 at
> the user's request (didn't feel useful). The design — a spring-driven side
> profile that leans back/forward with a tilting juice cup, driven off the
> service's `verticalG`/`longitudinalG` — is preserved in §4.1 above if it's
> ever revived. Turbulence strip, multi-passenger, and the GPS-off panel bypass
> stay deferred.

No sensor packages existed before this; the dashboard was 100% GPS-driven
([dashboard_panel.dart](../lib/ui/screens/flight/widgets/tabs/dashboard/dashboard_panel.dart)
gates everything on `GpsStatus`).

> Related prior decision: flight_weather_feature.md §7 dropped **forecast**
> bumpiness ("bad-weather news is unpleasant"). This spec does not reopen that.
> Live measured turbulence is the opposite emotional beat: it describes what the
> passenger is *already feeling* and labels it as normal — reassurance, not
> threat. All turbulence copy in this feature must be calming ("Light chop —
> normal for this phase"), never predictive or alarming.

---

## 1. The one-sentence pitch

> Your phone is a flight recorder: during the flight the dashboard shows the
> forces you actually feel — and after touchdown Flymap hands you a shareable
> report of your takeoff, your cruise, and how buttery your pilot's landing was.

Why it fits Flymap: the dashboard's weak spot is that GPS often has no fix in a
cabin (aisle seat, phone away from window) and the whole tab degrades to
"searching…". Accelerometer, gyroscope and barometer work **always, in airplane
mode, with no runtime permission on either platform**. Sensor instruments give
aisle-seat users a live dashboard for the first time — and the recap gives every
user a reason to reopen the app after landing (the moment they currently churn).

## 2. Background recording — platform reality

**Today the app has zero background capability**: no `UIBackgroundModes` in
Info.plist, no foreground service / background location in the Android
manifest. GPS streams only while the flight screen is foreground. Whatever we
promise, the recap must be built on a **segments model** (record when we can,
stitch gaps, degrade gracefully) — never assume an unbroken trace.

Three tiers, shipped in this order:

### Tier 1 — foreground sessions + Recorder Mode (v1, no OS background work)
Record whenever the app is open. Flymap *is* an in-flight companion; the target
user already keeps it open. The one rule of this tier: **recording lives and
dies with the screen being on** — so give users a cheap way to keep it on:

**Recorder Mode** — a wakelock-driven, OLED-black, dimmed screen state so the
app can stay open for hours without draining the battery or lighting up a dark
cabin. Placement is free: hand, lap, seat pocket, or tray table during cruise.

> Corrected 2026-08-01: the original "Tray Table Mode" framing was wrong —
> trays are stowed exactly during takeoff and landing, and a loose phone
> rattles or gets grabbed in real turbulence. Placement barely matters for the
> core metrics (see §6); the only placement-dependent extra is real deck angle,
> which auto-unlocks whenever the phone happens to be resting still.

Battery: dimmed static OLED screen + 50 Hz accel + existing GPS ≈ a few %/hour.
`wakelock_plus` + brightness floor. Exit on tap.

### Tier 2 — Android foreground service (v1.5)
"Recording your flight ✈️" persistent notification + partial wake lock →
full-suite background recording on Android (standard telematics pattern:
sensor listeners in an FGS survive screen-off; use batched delivery). Moderate
effort, no permission friction beyond the notification.

### Tier 3 — iOS background location session (v2)
Add `UIBackgroundModes: location`; a session started in foreground with
`allowsBackgroundLocationUpdates` continues under **When-In-Use** permission
(blue pill indicator, no "Always" needed), and while the process is alive
CMMotionManager/CMAltimeter keep delivering. Legitimate App Review story for a
flight tracker. Optional resilience add-on: **CMSensorRecorder** — the motion
coprocessor records 50 Hz accelerometer for up to ~12 h *even if the app is
suspended*; retrieve after landing to backfill gaps. Accel only (no baro/gyro),
needs Motion & Fitness permission, retrieval is slow — backfill, not backbone.

## 3. What gets recorded (the recap's raw material)

Storage: **per-second aggregate rows** (sqflite, ~50 B/row → < 1 MB for a
long-haul) + **raw 100 Hz event windows** (±10 s) around takeoff roll,
touchdown, and the worst turbulence bursts. Never persist raw continuous
streams.

Per-second row: vertical-accel mean/RMS/peak (gravity-frame), longitudinal g
(cabin-frame, once calibrated), pitch estimate + stationarity flag, baro
pressure → cabin altitude, gyro rotation magnitude, GPS lat/lon/alt/speed when
fixed, phase label.

Derived events for the report:
- **Phase timeline** — taxi start, takeoff-roll start, liftoff, top of climb,
  descent start (cabin baro leads the real descent by ~20–30 min), touchdown,
  taxi-in. Detectable with zero GPS.
- **Takeoff** — roll duration, avg/peak longitudinal g, rotation moment,
  rotation groundspeed (GPS if fixed), initial climb deck angle.
- **Cruise** — % smooth air, per-minute turbulence bands, worst-bump moment
  (time, g, location if GPS), bank-turn count (gyro), max altitude/speed (GPS).
- **Cabin** — max cabin altitude (headline: "your cabin climbed to 7,100 ft"),
  pressurization profile, biggest ears-pop moment (max |dP/dt|).
- **Landing** — touchdown peak vertical g → butter tier, braking peak decel.
- **Apparent weight** — max/min moments ("heaviest at 14:32, +18% during
  rotation").
- Meta (internal only): % of session phone-stationary, per-metric confidence —
  the report silently omits low-confidence sections instead of showing junk.

## 4. V1 feature set — UX visions

### 4.1 Cabin Live (the hero — side-view cabin illustration)
Flat-vector **side-view cabin cutaway in airline-safety-card art style** (matches
the app's whimsical aviation touches — EXAMPLE badge, plane-landing page-turn).
Two–three passengers in profile on a bench of seats, window strip behind them.

- **Liquids tell the truth**: a juice cup on the tray table whose surface tilts
  to the *real* net-force angle (`atan(a_long / a_vert)`) and ripples during
  chop. Physically accurate, instantly funny, the screenshot moment.
- Passenger posture is spring-driven by real g: pressed **back** during the
  roll (we show what you *feel* — eyeballs-back, opposite the acceleration
  arrow), sink at rotation (~1.15 g), gentle float on bumps, thrown **forward**
  under braking after touchdown.
- Felt-force arrow + live readout: *"0.31 g — pushed into your seat with 31% of
  your weight."*
- The whole cabin tilts to the true deck angle when the phone is stationary
  (climb ≈ 12–15°, descent ≈ 3°); canned angles when handheld.
- Windows: ground blur → tilting horizon → cruise sky → stars (real local
  time). Descent adds an "ears moment" badge when |dP/dt| spikes.
- Lifecycle: auto-appears taxi→seatbelt-chime altitude and descent→gate;
  collapses to a chip during cruise; auto-expands during turbulence episodes
  with calming copy ("Light chop — normal").
- Implementation: CustomPainter + spring sims; no Rive dependency for v1.

### 4.2 Recorder Mode (screen-awake recording)
Full-black dimmed screen: huge g readout, seismograph strip, cabin altitude,
phase label, mini cabin illustration. Purpose: let the app stay open for hours
(Tier 1's only requirement) without battery or light annoyance. No placement
instructions — all core metrics work handheld; the UI simply unlocks the
real-tilt bonus (§4.1) whenever motion variance says the phone is resting
still, wherever that is.

### 4.3 Two new instrument tiles (existing `instruments/` grid)
- **G-meter** — round aviation-style gauge, needle + peak-hold marker; tap
  toggles g ↔ apparent-weight %. Orientation-independent (magnitude), so it
  works before any calibration.
- **Cabin altitude** — dual-arc gauge: cabin altitude (baro) vs aircraft
  altitude (GPS). The needles diverging during climb is the nerd-candy moment;
  degrades to cabin-only with no GPS fix (aisle-seat win).

### 4.4 Turbulence seismograph
Full-width strip under the cluster: scrolling 15-min vertical-accel sparkline,
banded green/teal ("Smooth", "Light chop"). EKG-of-your-flight aesthetic.
Reassurance framing only — see the header note on the dropped forecast feature.

### 4.5 Flight Recap (the report — Wrapped-style)
Trigger: touchdown detected (vertical spike + baro floor + decel signature) →
local notification *"Your flight report is ready ✈️"* + badge on the home
flight card.

Full-screen swipeable story pages, **reusing the Cabin Live illustration to
replay each moment with the user's own numbers**:
1. **Cover** — route + date, boarding-pass stamp aesthetic.
2. **Takeoff** — cabin scene replays the roll; your g curve, roll seconds,
   rotation speed (if GPS).
3. **Climb** — cabin-altitude line racing aircraft-altitude line.
4. **Cruise** — smoothness ring ("94% smooth air"), worst-bump annotation,
   turbulence bands over the route map if GPS.
5. **Landing** — the jolt replay, then the stamp reveal:
   **BUTTER < 1.15 g · SMOOTH < 1.35 · FIRM < 1.6 · "POSITIVE CONTACT" ≥ 1.6**
   with the honesty tag *"as felt at your seat"*.
6. **Summary card** — share via the existing share-card stack; every page
   individually shareable. Later: recap stats feed the flight-video feature.
Gaps are first-class: "recorded 2 h 10 m of 2 h 45 m", missing sections omitted.

### 4.6 Stretch: descent-started notification
Baro dP/dt while recording: *"Descent has begun — roughly 25 min to landing."*
Ships with whatever tier keeps us alive at top-of-descent (an open app /
Recorder Mode in v1).

## 5. Build order

- **Phase 0 — de-risk (do first, ~1–2 days):** add `sensors_plus` (6.x has
  `barometerEvents`); build a silent **SensorTraceLogger** debug screen dumping
  JSONL traces; verify baro availability + screen-off behavior on both
  platforms. Owner flies with it before any UI is built — thresholds (roll
  signature, touchdown spike, turbulence bands) get tuned on real traces.
- **Phase 1 — pipeline + tiles:** `AppMotionService` mirroring the
  `AppLocationService` DI pattern; gravity/linear separation (OS-fused
  streams); cabin-frame auto-calibration (during the takeoff roll the dominant
  sustained horizontal acceleration *is* "forward" — no calibration UI);
  `PhaseDetector` v0; per-second aggregator + sqflite tables. Ship G-meter +
  cabin-altitude tiles + seismograph.
- **Phase 2 — Cabin Live + Recorder Mode.**
- **Phase 3 — recap:** segments/session model, landing detection, Recap UI +
  share cards + local notification.
- **Phase 4 (v1.5/v2):** Android FGS → iOS background location →
  CMSensorRecorder backfill → turbulence-on-map → percentiles ("smoother than
  78% of landings") once a corpus exists.

## 6. Honest limits & mitigations

- **Orientation is arbitrary** → magnitude-based instruments work immediately;
  cabin-frame metrics activate after roll calibration; recap marks
  low-confidence values instead of faking precision.
- **Coordinated turns are invisible to an accelerometer** (net force stays
  through the floor) → bank detection uses gyro + the subtle 1/cos(bank) g
  rise; never show a naive tilt-based bank angle.
- **Touchdown g depends on where the phone sits** (hand vs lap vs seat pocket)
  → band-pass relative to local baseline, wide tier thresholds, "as felt at
  your seat" copy. Detection is reliable anywhere; only the exact number varies.
- **iOS Tier 1 records only while screen-on** → Recorder Mode is the honest
  bridge; never promise a landing score we might miss (recap shows what was
  captured).
- **PostHog policy** (quota): product events only — `recorder_session_started`
  (mode), `recap_viewed`, `recap_page_shared`, `tray_mode_started`. Sensor
  diagnostics stay Firebase-only.

## 7. Explicitly out of scope

- Magnetometer compass (useless in a metal fuselage; GPS-course compass stays).
- Microphone/engine-noise detection (privacy + App Review perception).
- Turbulence *forecasts* of any kind (decided July 2026, weather spec §7).
- Background recording beyond Tier 1 in v1.
