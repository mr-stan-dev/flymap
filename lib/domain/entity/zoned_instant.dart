import 'package:equatable/equatable.dart';

/// An instant in time plus the UTC offset of the place it belongs to — the
/// in-memory form of an ISO-8601 string like `2026-07-28T23:15:30+01:00`.
///
/// Exists because Dart's [DateTime] cannot carry an arbitrary offset: parsing
/// that string with [DateTime.parse] keeps the instant but silently drops
/// the `+01:00`, and with it the wall-clock time at the airport.
class ZonedInstant extends Equatable {
  ZonedInstant({required DateTime utc, this.offsetMinutes})
    : utc = utc.toUtc();

  /// The instant, always UTC.
  final DateTime utc;

  /// UTC offset in minutes at that place and instant (e.g. +01:00 -> 60);
  /// null when unknown — [local] then falls back to UTC.
  final int? offsetMinutes;

  /// Wall-clock time at the place, as an offset-shifted [DateTime] meant for
  /// display/calendar math only (its own `isUtc` flag is meaningless).
  DateTime get local => utc.add(Duration(minutes: offsetMinutes ?? 0));

  /// ISO-8601 with the offset preserved: `2026-07-28T23:15:30.000+01:00`;
  /// plain UTC (`...Z`) when the offset is unknown.
  String toIso8601String() {
    final offset = offsetMinutes;
    if (offset == null) return utc.toIso8601String();
    // Local wall clock without the misleading Z suffix, plus +-HH:MM.
    final wallClock = local.toIso8601String().replaceFirst('Z', '');
    final sign = offset < 0 ? '-' : '+';
    final magnitude = offset.abs();
    final hh = (magnitude ~/ 60).toString().padLeft(2, '0');
    final mm = (magnitude % 60).toString().padLeft(2, '0');
    return '$wallClock$sign$hh:$mm';
  }

  /// Parses ISO-8601, keeping an explicit `+-HH:MM` offset; a `Z` (or
  /// offset-less) string yields an unknown offset. Null on garbage.
  static ZonedInstant? tryParse(dynamic raw) {
    if (raw is! String || raw.trim().isEmpty) return null;
    final text = raw.trim();
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    final match = RegExp(r'([+-])(\d{2}):?(\d{2})$').firstMatch(text);
    final offsetMinutes = match == null
        ? null
        : (match[1] == '-' ? -1 : 1) *
              (int.parse(match[2]!) * 60 + int.parse(match[3]!));
    return ZonedInstant(utc: parsed.toUtc(), offsetMinutes: offsetMinutes);
  }

  @override
  List<Object?> get props => [utc, offsetMinutes];
}
