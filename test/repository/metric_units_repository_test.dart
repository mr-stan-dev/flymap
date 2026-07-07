import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MetricUnitsRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = MetricUnitsRepository();
  });

  test('defaults temperature unit to celsius', () async {
    final unit = await repository.getTemperatureUnit();

    expect(unit, TemperatureUnit.celsius);
  });

  test('persists temperature unit', () async {
    await repository.setTemperatureUnit(TemperatureUnit.fahrenheit);

    final unit = await repository.getTemperatureUnit();

    expect(unit, TemperatureUnit.fahrenheit);
  });

  test('defaults altitude unit to meters', () async {
    final unit = await repository.getAltitudeUnit();

    expect(unit, AltitudeUnit.meter);
  });

  test('keeps an explicitly chosen feet altitude', () async {
    await repository.setAltitudeUnit(AltitudeUnit.foot);

    final unit = await repository.getAltitudeUnit();

    expect(unit, AltitudeUnit.foot);
  });

  test('defaults distance unit to km and persists miles', () async {
    expect(await repository.getDistanceUnit(), DistanceUnit.km);

    await repository.setDistanceUnit(DistanceUnit.mile);

    expect(await repository.getDistanceUnit(), DistanceUnit.mile);
  });
}
