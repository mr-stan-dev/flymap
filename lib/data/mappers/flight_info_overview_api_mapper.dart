import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/logger.dart';

class FlightInfoOverviewApiMapper {
  FlightInfoOverviewApiMapper();
  final _logger = const Logger('FlightInfoOverviewApiMapper');

  FlightInfo toFlightInfo(Map<String, dynamic> map) {
    final overview = _extractOverview(map);
    final keys = map.keys.take(10).join(', ');
    _logger.log(
      'toFlightInfo keys=[$keys] overviewLen=${overview.length} '
      '(overview-only mapping)',
    );

    return FlightInfo(overview, const []);
  }

  String _extractOverview(Map<String, dynamic> map) {
    final direct = (map['overview'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;

    final nestedMap = _extractNestedMap(map);
    if (nestedMap != null) {
      return (nestedMap['overview'] ?? nestedMap['summary'] ?? '')
          .toString()
          .trim();
    }
    return '';
  }

  Map<String, dynamic>? _extractNestedMap(Map<String, dynamic> map) {
    for (final key in const ['results', 'data', 'response']) {
      final value = map[key];
      if (value is Map) return value.cast<String, dynamic>();
    }
    return null;
  }
}
