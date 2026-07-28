import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/zoned_instant.dart';

void main() {
  test('serializes to ISO-8601 with the offset preserved', () {
    expect(
      ZonedInstant(
        utc: DateTime.utc(2026, 7, 28, 22, 15, 30),
        offsetMinutes: 60,
      ).toIso8601String(),
      '2026-07-28T23:15:30.000+01:00',
    );
    expect(
      ZonedInstant(
        utc: DateTime.utc(2026, 8, 3, 4, 45),
        offsetMinutes: -330,
      ).toIso8601String(),
      '2026-08-02T23:15:00.000-05:30',
    );
    // Known zero offset is explicit, unknown offset stays plain UTC.
    expect(
      ZonedInstant(
        utc: DateTime.utc(2026, 8, 3, 7),
        offsetMinutes: 0,
      ).toIso8601String(),
      '2026-08-03T07:00:00.000+00:00',
    );
    expect(
      ZonedInstant(utc: DateTime.utc(2026, 8, 3, 7)).toIso8601String(),
      '2026-08-03T07:00:00.000Z',
    );
  });

  test('round-trips through parse', () {
    for (final instant in [
      ZonedInstant(utc: DateTime.utc(2026, 7, 28, 22, 15, 30), offsetMinutes: 60),
      ZonedInstant(utc: DateTime.utc(2026, 8, 3, 4, 45), offsetMinutes: -330),
      ZonedInstant(utc: DateTime.utc(2026, 8, 3, 7), offsetMinutes: 0),
      ZonedInstant(utc: DateTime.utc(2026, 8, 3, 7)),
    ]) {
      expect(ZonedInstant.tryParse(instant.toIso8601String()), instant);
    }
  });

  test('parse keeps the instant correct and rejects garbage', () {
    final parsed = ZonedInstant.tryParse('2026-07-28T23:15:30+01:00')!;
    expect(parsed.utc, DateTime.utc(2026, 7, 28, 22, 15, 30));
    expect(parsed.offsetMinutes, 60);
    expect(parsed.local, DateTime.utc(2026, 7, 28, 23, 15, 30));

    expect(ZonedInstant.tryParse('nonsense'), isNull);
    expect(ZonedInstant.tryParse(null), isNull);
    expect(ZonedInstant.tryParse(''), isNull);
    expect(ZonedInstant.tryParse(42), isNull);
  });
}
