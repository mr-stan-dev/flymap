import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// DST-correct local-time math for any airport, fully offline and
/// provider-independent: the IANA zone id comes from the build-time-enriched
/// airports CSV ([AirportsDatabase.timezoneIdFor]), the offset rules from
/// the `timezone` package's bundled tzdata.
///
/// Schedule-provider offsets (AeroDataBox) stay authoritative when present;
/// this service is the universal fallback beneath them.
class AirportTimezoneService {
  AirportTimezoneService({AirportsDatabase? airportsDatabase})
    : _airports = airportsDatabase ?? AirportsDatabase.instance;

  final AirportsDatabase _airports;
  static bool _tzdataInitialized = false;

  /// Loads the airports CSV if it isn't yet — cheap when already done.
  Future<void> ensureReady() => _airports.initialize();

  /// The airport's UTC offset in minutes at [atUtc] (DST-aware), or null
  /// when the airport's timezone is unknown.
  int? utcOffsetMinutes(Airport airport, DateTime atUtc) {
    final location = _locationFor(airport);
    if (location == null) return null;
    return tz.TZDateTime.from(atUtc.toUtc(), location).timeZoneOffset.inMinutes;
  }

  /// The UTC instant of [hour] o'clock wall-clock time at the airport on
  /// [date] (e.g. true local noon for estimated departures), or null when
  /// the airport's timezone is unknown.
  DateTime? localTimeToUtc(Airport airport, DateTime date, {int hour = 12}) {
    final location = _locationFor(airport);
    if (location == null) return null;
    return tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      hour,
    ).toUtc();
  }

  tz.Location? _locationFor(Airport airport) {
    final id = _airports.timezoneIdFor(
      icaoCode: airport.icaoCode,
      iataCode: airport.iataCode,
    );
    if (id == null) return null;
    if (!_tzdataInitialized) {
      tzdata.initializeTimeZones();
      _tzdataInitialized = true;
    }
    try {
      return tz.getLocation(id);
    } on tz.LocationNotFoundException {
      return null;
    }
  }
}
