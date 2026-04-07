import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_poi_type.dart';

class PoiStyleConfig {
  PoiStyleConfig._();

  static final List<FlightPoiType> legendOrder = () {
    final values = [...FlightPoiType.values];
    values.sort((a, b) => _legendOrderRank(a).compareTo(_legendOrderRank(b)));
    return values;
  }();

  static const Color textHaloColor = Color(0xFFFFFFFF);

  static int _legendOrderRank(FlightPoiType type) => switch (type) {
    FlightPoiType.city => 0,
    FlightPoiType.river => 1,
    FlightPoiType.island => 2,
    FlightPoiType.airport => 3,
    FlightPoiType.mountain => 4,
    FlightPoiType.lake => 5,
    FlightPoiType.volcano => 6,
    FlightPoiType.bay => 7,
    FlightPoiType.waterfall => 8,
    FlightPoiType.glacier => 9,
    FlightPoiType.pass => 10,
    FlightPoiType.desert => 11,
    FlightPoiType.sea => 12,
    FlightPoiType.region => 13,
    FlightPoiType.unknown => 14,
  };

  static Color colorFor(FlightPoiType type) => switch (type) {
    FlightPoiType.city => const Color(0xFF1F6FB2),
    FlightPoiType.river => const Color(0xFF2FA4D6),
    FlightPoiType.island => const Color(0xFF5FAF2F),
    FlightPoiType.airport => const Color(0xFF5E6F7A),
    FlightPoiType.mountain => const Color(0xFF1F8F86),
    FlightPoiType.lake => const Color(0xFF4FA9C6),
    FlightPoiType.volcano => const Color(0xFFE53935),
    FlightPoiType.bay => const Color(0xFF2FA7A0),
    FlightPoiType.waterfall => const Color(0xFF2D8FD6),
    FlightPoiType.glacier => const Color(0xFF3DB4C9),
    FlightPoiType.pass => const Color(0xFF7FAE3E),
    FlightPoiType.desert => const Color(0xFFF57C00),
    FlightPoiType.sea => const Color(0xFF2C6AA3),
    FlightPoiType.region => const Color(0xFF8E44AD),
    FlightPoiType.unknown => const Color(0xFF6E7C87),
  };
}
