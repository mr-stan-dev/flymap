import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/zoned_instant.dart';

class FlightSummary extends Equatable {
  const FlightSummary({
    required this.flightNumber,
    this.fr24Id,
    required this.origIcao,
    required this.destIcao,
    this.airlineCode,
    this.airlineName,
    this.historicalFlightDate,
    this.actualDistanceKm,
    this.actualDurationMinutes,
    this.aircraftType,
    this.departure,
    this.arrival,
    this.travelDateLocal,
    this.scheduledDeparture,
    this.scheduledArrival,
  });

  final String? flightNumber;
  final String? fr24Id;
  final String? origIcao;
  final String? destIcao;
  final String? airlineCode;
  final String? airlineName;
  final DateTime? historicalFlightDate;
  final double? actualDistanceKm;
  final int? actualDurationMinutes;

  /// ICAO aircraft type from the recorded flight (e.g. "A320", "B738").
  final String? aircraftType;
  final Airport? departure;
  final Airport? arrival;

  /// Upcoming-schedule fields — set only by the upcoming-flights search,
  /// null for historical candidates.
  final DateTime? travelDateLocal;
  final ZonedInstant? scheduledDeparture;
  final ZonedInstant? scheduledArrival;

  bool get isUpcoming => travelDateLocal != null;

  /// Scheduled departure as wall-clock time at the departure airport.
  DateTime? get scheduledDepartureLocal => scheduledDeparture?.local;

  /// The persisted schedule for this candidate, or null when dateless.
  FlightSchedule? get schedule {
    final travelDate = travelDateLocal;
    if (travelDate == null) return null;
    return FlightSchedule(
      travelDate: DateTime(travelDate.year, travelDate.month, travelDate.day),
      departure: scheduledDeparture,
      arrival: scheduledArrival,
    );
  }

  int? get displayActualDistanceKm {
    final distanceKm = _toFiniteDouble(actualDistanceKm);
    if (distanceKm == null || distanceKm <= 0) return null;
    return FlightRouteMetrics.roundDistanceKmForDisplay(
      distanceKm,
      isActual: true,
    );
  }

  int? get displayActualDurationMinutes {
    final durationMinutes = _toInt(actualDurationMinutes);
    if (durationMinutes == null || durationMinutes <= 0) return null;
    return FlightRouteMetrics.roundDurationMinutesForDisplay(
      durationMinutes,
      isActual: true,
    );
  }

  factory FlightSummary.fromApi(
    Map<String, dynamic> map,
    String fallbackFlightNumber,
  ) {
    return FlightSummary(
      flightNumber:
          _toNonEmptyString(map['flightNumber']) ?? fallbackFlightNumber,
      fr24Id: _toNonEmptyString(map['fr24Id']),
      origIcao: _toNonEmptyString(map['origIcao']),
      destIcao: _toNonEmptyString(map['destIcao']),
      airlineCode: _toNonEmptyString(map['airlineCode']),
      airlineName: _toNonEmptyString(map['airlineName']),
      historicalFlightDate: _toDate(map['historicalFlightDate']),
      actualDistanceKm: _toFiniteDouble(map['actualDistanceKm']),
      actualDurationMinutes: _toInt(map['actualDurationMinutes']),
      aircraftType: _toNonEmptyString(map['aircraftType']),
      // Present only in search_upcoming_flights_by_number payloads.
      travelDateLocal: _toLocalDate(map['dateLocal']),
      scheduledDeparture: _toZonedInstant(
        map['stdUtc'],
        map['utcOffsetMinutes'],
      ),
      scheduledArrival: _toZonedInstant(
        map['staUtc'],
        map['arrivalUtcOffsetMinutes'],
      ),
    );
  }

  static ZonedInstant? _toZonedInstant(dynamic utcRaw, dynamic offsetRaw) {
    final utc = _toUtcInstant(utcRaw);
    if (utc == null) return null;
    return ZonedInstant(utc: utc, offsetMinutes: _toInt(offsetRaw));
  }

  FlightSummary copyWith({
    String? flightNumber,
    String? fr24Id,
    String? origIcao,
    String? destIcao,
    String? airlineCode,
    String? airlineName,
    DateTime? historicalFlightDate,
    double? actualDistanceKm,
    int? actualDurationMinutes,
    String? aircraftType,
    Airport? departure,
    Airport? arrival,
    DateTime? travelDateLocal,
    ZonedInstant? scheduledDeparture,
    ZonedInstant? scheduledArrival,
  }) {
    return FlightSummary(
      flightNumber: flightNumber ?? this.flightNumber,
      fr24Id: fr24Id ?? this.fr24Id,
      origIcao: origIcao ?? this.origIcao,
      destIcao: destIcao ?? this.destIcao,
      airlineCode: airlineCode ?? this.airlineCode,
      airlineName: airlineName ?? this.airlineName,
      historicalFlightDate: historicalFlightDate ?? this.historicalFlightDate,
      actualDistanceKm: actualDistanceKm ?? this.actualDistanceKm,
      actualDurationMinutes:
          actualDurationMinutes ?? this.actualDurationMinutes,
      aircraftType: aircraftType ?? this.aircraftType,
      departure: departure ?? this.departure,
      arrival: arrival ?? this.arrival,
      travelDateLocal: travelDateLocal ?? this.travelDateLocal,
      scheduledDeparture: scheduledDeparture ?? this.scheduledDeparture,
      scheduledArrival: scheduledArrival ?? this.scheduledArrival,
    );
  }

  static String? _toNonEmptyString(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  static double? _toFiniteDouble(dynamic raw) {
    if (raw is num) {
      final value = raw.toDouble();
      return value.isFinite ? value : null;
    }
    if (raw is String) {
      final parsed = double.tryParse(raw);
      if (parsed == null || !parsed.isFinite) return null;
      return parsed;
    }
    return null;
  }

  static int? _toInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static DateTime? _toDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) {
      return DateTime.utc(raw.year, raw.month, raw.day);
    }
    if (raw is int) {
      final dt = DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true);
      return DateTime.utc(dt.year, dt.month, dt.day);
    }
    if (raw is num) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        raw.toInt() * 1000,
        isUtc: true,
      );
      return DateTime.utc(dt.year, dt.month, dt.day);
    }
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) return null;
      return DateTime.utc(parsed.year, parsed.month, parsed.day);
    }
    return null;
  }

  /// "2026-08-03" -> local-zone date-only DateTime (calendar day at the
  /// departure airport; no instant semantics).
  static DateTime? _toLocalDate(dynamic raw) {
    final value = _toNonEmptyString(raw);
    if (value == null) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static DateTime? _toUtcInstant(dynamic raw) {
    final value = _toNonEmptyString(raw);
    if (value == null) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  @override
  List<Object?> get props => [
    flightNumber,
    fr24Id,
    origIcao,
    destIcao,
    airlineCode,
    airlineName,
    historicalFlightDate,
    actualDistanceKm,
    actualDurationMinutes,
    aircraftType,
    departure,
    arrival,
    travelDateLocal,
    scheduledDeparture,
    scheduledArrival,
  ];
}
