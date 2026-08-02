/// A single fused reading from the phone's motion + pressure sensors,
/// expressed in units the flight dashboard cares about.
///
/// All g values are multiples of standard gravity (1.0 g == 9.80665 m/s²).
/// The accelerometer measures *specific force* (proper acceleration), so a
/// phone resting on a table reads a total magnitude of ~1.0 g pointing "up".
class MotionSample {
  const MotionSample({
    required this.totalG,
    required this.smoothedTotalG,
    required this.peakG,
    required this.verticalG,
    required this.horizontalG,
    required this.longitudinalG,
    required this.pressureHpa,
    required this.pressureAvailable,
    required this.hasMotion,
    required this.calibrated,
  });

  /// Magnitude of the felt force, orientation-independent. ~1.0 at rest,
  /// spikes above during turbulence and the landing touchdown.
  final double totalG;

  /// [totalG] with a light low-pass (~0.25 s) — responsive but free of sensor
  /// micro-jitter. This is the live gauge value.
  final double smoothedTotalG;

  /// The highest g held since the last reset, measured on a slightly heavier
  /// (~0.5 s) filter so a brief tap can't set a false record. Reset via
  /// [MotionSensorService.resetPeak].
  final double peakG;

  /// Dynamic acceleration along the felt-gravity axis, gravity removed.
  /// Positive = pressed down into the seat (heavier); negative = floating
  /// (lighter). Robust regardless of how the phone is held.
  final double verticalG;

  /// Magnitude of the horizontal (in-cabin-plane) dynamic acceleration.
  final double horizontalG;

  /// Signed acceleration along the auto-calibrated fore-aft cabin axis.
  /// Positive = accelerating forward (you feel pushed back into your seat,
  /// e.g. the takeoff roll); negative = decelerating (thrown forward against
  /// the belt, e.g. braking after touchdown). Zero until [calibrated].
  final double longitudinalG;

  /// Cabin air pressure in hPa, or null when no barometer reading is available.
  final double? pressureHpa;

  /// Whether this device exposes a usable barometer.
  final bool pressureAvailable;

  /// Whether at least one accelerometer reading has arrived.
  final bool hasMotion;

  /// Whether the fore-aft axis has locked onto a real acceleration event, so
  /// [longitudinalG] carries a meaningful forward/back sign.
  final bool calibrated;

  static const zero = MotionSample(
    totalG: 1,
    smoothedTotalG: 1,
    peakG: 1,
    verticalG: 0,
    horizontalG: 0,
    longitudinalG: 0,
    pressureHpa: null,
    pressureAvailable: false,
    hasMotion: false,
    calibrated: false,
  );

  MotionSample copyWith({
    double? totalG,
    double? smoothedTotalG,
    double? peakG,
    double? verticalG,
    double? horizontalG,
    double? longitudinalG,
    double? pressureHpa,
    bool? pressureAvailable,
    bool? hasMotion,
    bool? calibrated,
  }) {
    return MotionSample(
      totalG: totalG ?? this.totalG,
      smoothedTotalG: smoothedTotalG ?? this.smoothedTotalG,
      peakG: peakG ?? this.peakG,
      verticalG: verticalG ?? this.verticalG,
      horizontalG: horizontalG ?? this.horizontalG,
      longitudinalG: longitudinalG ?? this.longitudinalG,
      pressureHpa: pressureHpa ?? this.pressureHpa,
      pressureAvailable: pressureAvailable ?? this.pressureAvailable,
      hasMotion: hasMotion ?? this.hasMotion,
      calibrated: calibrated ?? this.calibrated,
    );
  }
}
