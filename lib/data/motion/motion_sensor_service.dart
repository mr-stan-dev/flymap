import 'dart:async';
import 'dart:math' as math;

import 'package:flymap/data/motion/motion_sample.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Streams fused motion + pressure readings for the flight dashboard.
///
/// Physics notes:
/// - The accelerometer reports *specific force* including gravity, so at rest
///   its magnitude is ~9.81 m/s² (1.0 g). We low-pass it to estimate the
///   gravity direction, then subtract to get the dynamic (linear) acceleration.
/// - Vertical vs horizontal are split against the live gravity direction, so
///   both are correct no matter how the phone is held — no calibration needed.
/// - The fore-aft sign (forward push vs forward throw) is NOT recoverable from
///   a single reading, so we auto-calibrate: the first strong, sustained
///   horizontal acceleration (typically the takeoff roll) defines "forward".
///   Later readings only refine that axis line; they never flip its direction,
///   so braking after landing correctly reads as a forward throw.
class MotionSensorService {
  MotionSensorService({
    Duration accelerometerInterval = _defaultAccelInterval,
    Duration barometerTimeout = const Duration(seconds: 5),
    Stream<AccelerometerEvent> Function({Duration samplingPeriod})?
    accelerometerSource,
    Stream<BarometerEvent> Function()? barometerSource,
  }) : _accelInterval = accelerometerInterval,
       _barometerTimeout = barometerTimeout,
       _accelerometerSource = accelerometerSource ?? accelerometerEventStream,
       _barometerSource = barometerSource ?? barometerEventStream;

  static const _defaultAccelInterval = Duration(milliseconds: 20); // ~50 Hz
  static const _g0 = 9.80665;

  // Gravity is the slow DC component of the accelerometer signal. ~0.4 s time
  // constant at 50 Hz: crisp on the onset of a push, a bump or braking, while
  // a genuinely sustained acceleration is gradually absorbed into "gravity"
  // (the unavoidable limit of a single accelerometer — see the feature spec).
  static const _gravityAlpha = 0.95;
  // Smoothing for the horizontal magnitude used by the calibrator.
  static const _hMagAlpha = 0.85;
  // Two low-passes on total g. The LIVE gauge uses a light one (~0.25 s): it
  // stays responsive to real bumps while shedding sensor micro-jitter. PEAK-hold
  // uses a heavier one (~0.5 s) so a brief tap barely moves it and can't set a
  // false record, while sustained turbulence or a landing still registers.
  static const _liveAlpha = 0.92; // ~0.25 s at 50 Hz
  static const _peakAlpha = 0.96; // ~0.5 s at 50 Hz
  // Lock "forward" once smoothed horizontal accel crosses this (~0.15 g).
  static const _lockThresholdMs2 = 1.5;
  // Only nudge the axis on clearly-horizontal events, and only slightly.
  static const _refineThresholdMs2 = 2.0;
  static const _refineBeta = 0.02;

  final Duration _accelInterval;
  final Duration _barometerTimeout;
  final Stream<AccelerometerEvent> Function({Duration samplingPeriod})
  _accelerometerSource;
  final Stream<BarometerEvent> Function() _barometerSource;

  final StreamController<MotionSample> _controller =
      StreamController<MotionSample>.broadcast();

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<BarometerEvent>? _baroSub;
  Timer? _barometerTimeoutTimer;
  bool _started = false;
  bool _barometerStarted = false;

  // Running gravity estimate in the phone frame (m/s²).
  double? _gx, _gy, _gz;
  double _hMagSmooth = 0;
  double _totalGLive = 1; // ~0.25 s low-pass, the live gauge value
  double _totalGSlow = 1; // ~0.5 s low-pass, feeds peak-hold
  double _peakG = 1; // held maximum of the slow signal since last reset

  // Calibrated fore-aft unit axis in the phone frame; null until locked.
  double? _fx, _fy, _fz;
  bool _calibrated = false;

  double? _pressureHpa;
  bool _pressureAvailable = false;
  bool _hasMotion = false;

  MotionSample _latest = MotionSample.zero;

  Stream<MotionSample> get stream => _controller.stream;
  MotionSample get latest => _latest;

  /// Starts the accelerometer only. This needs no OS permission on either
  /// platform, so the g-force gauge runs the instant the screen opens without
  /// any prompt. The barometer is started separately via [startBarometer].
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _accelSub = _accelerometerSource(samplingPeriod: _accelInterval).listen(
      _onAccelerometer,
      onError: (_) {},
      cancelOnError: false,
    );
  }

  /// Subscribes to the barometer. Call this only once the platform allows it
  /// (Android: always; iOS: after Motion & Fitness is granted), because on iOS
  /// subscribing is what triggers the Motion permission prompt.
  void startBarometer() {
    if (_barometerStarted) return;
    _barometerStarted = true;
    try {
      _baroSub = _barometerSource().listen(
        _onBarometer,
        onError: (_) => _markBarometerUnavailable(),
        cancelOnError: false,
      );
      // Some devices simply never emit (no barometer). Give up after a while.
      _barometerTimeoutTimer = Timer(_barometerTimeout, () {
        if (!_pressureAvailable) _markBarometerUnavailable();
      });
    } catch (_) {
      _markBarometerUnavailable();
    }
  }

  /// Clears the held peak back to the current force.
  void resetPeak() {
    _peakG = _totalGSlow;
  }

  /// Forget the fore-aft calibration so the next strong event re-locks it.
  void recalibrate() {
    _fx = _fy = _fz = null;
    _calibrated = false;
  }

  void _onAccelerometer(AccelerometerEvent event) {
    final ax = event.x, ay = event.y, az = event.z;
    _hasMotion = true;

    // Seed / update the gravity estimate.
    if (_gx == null) {
      _gx = ax;
      _gy = ay;
      _gz = az;
    } else {
      _gx = _gravityAlpha * _gx! + (1 - _gravityAlpha) * ax;
      _gy = _gravityAlpha * _gy! + (1 - _gravityAlpha) * ay;
      _gz = _gravityAlpha * _gz! + (1 - _gravityAlpha) * az;
    }

    final gMag = _magnitude(_gx!, _gy!, _gz!);
    final totalG = _magnitude(ax, ay, az) / _g0;
    // Light filter for the live value; heavier one feeds a tap-resistant peak.
    _totalGLive = _liveAlpha * _totalGLive + (1 - _liveAlpha) * totalG;
    _totalGSlow = _peakAlpha * _totalGSlow + (1 - _peakAlpha) * totalG;
    if (_totalGSlow > _peakG) _peakG = _totalGSlow;

    // Dynamic (linear) acceleration = raw minus gravity.
    final lx = ax - _gx!, ly = ay - _gy!, lz = az - _gz!;

    // Split against the gravity direction.
    double verticalG = 0, horizontalG = 0;
    double hx = lx, hy = ly, hz = lz;
    if (gMag > 1e-3) {
      final ugx = _gx! / gMag, ugy = _gy! / gMag, ugz = _gz! / gMag;
      final vDot = lx * ugx + ly * ugy + lz * ugz;
      // ug points "up" (along the seat's normal force). Accelerating upward
      // grows the specific force along ug, which is exactly when you feel
      // heavier, so positive == pressed down and negative == floating.
      verticalG = vDot / _g0;
      hx = lx - vDot * ugx;
      hy = ly - vDot * ugy;
      hz = lz - vDot * ugz;
      horizontalG = _magnitude(hx, hy, hz) / _g0;
    }

    final longitudinalG = _updateForeAftAxis(hx, hy, hz);

    _latest = MotionSample(
      totalG: totalG,
      smoothedTotalG: _totalGLive,
      peakG: _peakG,
      verticalG: verticalG,
      horizontalG: horizontalG,
      longitudinalG: longitudinalG,
      pressureHpa: _pressureHpa,
      pressureAvailable: _pressureAvailable,
      hasMotion: _hasMotion,
      calibrated: _calibrated,
    );
    if (!_controller.isClosed) _controller.add(_latest);
  }

  /// Locks / refines the forward axis and returns signed longitudinal g.
  double _updateForeAftAxis(double hx, double hy, double hz) {
    final hMag = _magnitude(hx, hy, hz);
    _hMagSmooth = _hMagAlpha * _hMagSmooth + (1 - _hMagAlpha) * hMag;

    if (!_calibrated) {
      if (_hMagSmooth > _lockThresholdMs2 && hMag > 1e-3) {
        // First strong sustained horizontal push defines "forward".
        _fx = hx / hMag;
        _fy = hy / hMag;
        _fz = hz / hMag;
        _calibrated = true;
      }
      return 0;
    }

    // Refine the axis line without flipping its forward/back sense.
    if (hMag > _refineThresholdMs2) {
      final dot = (hx * _fx! + hy * _fy! + hz * _fz!) / hMag;
      final sign = dot >= 0 ? 1.0 : -1.0;
      var nx = _fx! * (1 - _refineBeta) + (hx / hMag) * sign * _refineBeta;
      var ny = _fy! * (1 - _refineBeta) + (hy / hMag) * sign * _refineBeta;
      var nz = _fz! * (1 - _refineBeta) + (hz / hMag) * sign * _refineBeta;
      final nMag = _magnitude(nx, ny, nz);
      if (nMag > 1e-3) {
        _fx = nx / nMag;
        _fy = ny / nMag;
        _fz = nz / nMag;
      }
    }

    final proj = hx * _fx! + hy * _fy! + hz * _fz!;
    return proj / _g0;
  }

  void _onBarometer(BarometerEvent event) {
    _barometerTimeoutTimer?.cancel();
    _pressureHpa = event.pressure;
    _pressureAvailable = true;
  }

  void _markBarometerUnavailable() {
    _barometerTimeoutTimer?.cancel();
    _pressureAvailable = false;
    _pressureHpa = null;
  }

  double _magnitude(double x, double y, double z) =>
      math.sqrt(x * x + y * y + z * z);

  Future<void> stop() async {
    _started = false;
    _barometerStarted = false;
    _barometerTimeoutTimer?.cancel();
    _barometerTimeoutTimer = null;
    await _accelSub?.cancel();
    await _baroSub?.cancel();
    _accelSub = null;
    _baroSub = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
