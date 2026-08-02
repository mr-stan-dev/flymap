import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/motion/motion_sensor_service.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  late StreamController<AccelerometerEvent> accel;
  late StreamController<BarometerEvent> baro;
  late MotionSensorService service;
  final ts = DateTime(2020);

  setUp(() {
    accel = StreamController<AccelerometerEvent>.broadcast();
    baro = StreamController<BarometerEvent>.broadcast();
    service = MotionSensorService(
      accelerometerSource: ({Duration samplingPeriod = Duration.zero}) =>
          accel.stream,
      barometerSource: () => baro.stream,
      barometerTimeout: const Duration(seconds: 30),
    );
    service.start();
  });

  tearDown(() async {
    await service.dispose();
    await accel.close();
    await baro.close();
  });

  Future<void> feed(double x, double y, double z, {int count = 1}) async {
    for (var i = 0; i < count; i++) {
      accel.add(AccelerometerEvent(x, y, z, ts));
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('at rest reads ~1 g, level, uncalibrated', () async {
    await feed(0, 0, 9.80665, count: 5);
    expect(service.latest.hasMotion, isTrue);
    expect(service.latest.totalG, closeTo(1.0, 0.02));
    expect(service.latest.verticalG, closeTo(0.0, 0.05));
    expect(service.latest.calibrated, isFalse);
  });

  test('upward acceleration reads heavier (positive verticalG)', () async {
    await feed(0, 0, 9.80665, count: 5); // seed gravity
    await feed(0, 0, 12.0); // sudden push up
    expect(service.latest.verticalG, greaterThan(0.05));
  });

  test('downward acceleration reads lighter (negative verticalG)', () async {
    await feed(0, 0, 9.80665, count: 5);
    await feed(0, 0, 7.0); // dropped
    expect(service.latest.verticalG, lessThan(-0.05));
  });

  test('total g tracks specific-force magnitude', () async {
    await feed(0, 0, 9.80665, count: 3);
    await feed(0, 0, 19.6133); // 2 g
    expect(service.latest.totalG, closeTo(2.0, 0.05));
  });

  test('forward roll locks the axis (push = back); braking flips the sign',
      () async {
    await feed(0, 0, 9.80665, count: 5); // seed
    await feed(3.0, 0, 9.80665, count: 7); // sustained forward push
    expect(service.latest.calibrated, isTrue);
    expect(service.latest.longitudinalG, greaterThan(0.0));

    await feed(0, 0, 9.80665, count: 5); // settle
    await feed(-3.0, 0, 9.80665); // brake
    expect(service.latest.longitudinalG, lessThan(0.0));
  });

  test('the live value stays calm on a single-sample jolt', () async {
    await feed(0, 0, 9.80665, count: 5); // settle at rest
    await feed(0, 0, 19.6133); // one 2 g spike (a hand knock)
    expect(service.latest.totalG, greaterThan(1.9)); // raw sees it
    expect(service.latest.smoothedTotalG, lessThan(1.2)); // live barely moves
  });

  test('the live value follows a real sustained change', () async {
    await feed(0, 0, 9.80665, count: 5);
    await feed(0, 0, 14.71, count: 15); // ~1.5 g held ~0.3 s
    expect(service.latest.smoothedTotalG, greaterThan(1.2)); // responsive
  });

  test('peak-hold resists a brief tap', () async {
    await feed(0, 0, 9.80665, count: 5);
    await feed(0, 0, 19.6133, count: 3); // a ~0.06 s spike
    await feed(0, 0, 9.80665, count: 10); // back to rest
    expect(service.latest.peakG, lessThan(1.25));
  });

  test('peak-hold captures a sustained event', () async {
    await feed(0, 0, 9.80665, count: 5);
    await feed(0, 0, 14.71, count: 60); // ~1.5 g held ~1.2 s
    expect(service.latest.peakG, greaterThan(1.35));
  });

  test('resetPeak clears the held maximum', () async {
    await feed(0, 0, 9.80665, count: 5);
    await feed(0, 0, 14.71, count: 60); // build a peak
    await feed(0, 0, 9.80665, count: 60); // return to rest
    service.resetPeak();
    await feed(0, 0, 9.80665, count: 5);
    expect(service.latest.peakG, lessThan(1.1));
  });

  test('barometer pressure flows into the sample once started', () async {
    service.startBarometer();
    await feed(0, 0, 9.80665);
    baro.add(BarometerEvent(843.0, ts));
    await Future<void>.delayed(Duration.zero);
    await feed(0, 0, 9.80665); // next accel sample carries the pressure
    expect(service.latest.pressureAvailable, isTrue);
    expect(service.latest.pressureHpa, closeTo(843.0, 0.1));
  });
}
