import 'dart:convert';

import 'package:equatable/equatable.dart';

enum RouteRegionType {
  country('country'),
  region('region'),
  state('state'),
  province('province'),
  sea('sea'),
  ocean('ocean'),
  strait('strait'),
  channel('channel'),
  gulf('gulf'),
  bay('bay'),
  lake('lake'),
  alkalineLake('alkaline_lake'),
  island('island'),
  archipelago('archipelago'),
  peninsula('peninsula'),
  coast('coast'),
  mountainRange('mountain_range'),
  valley('valley'),
  plateau('plateau'),
  plain('plain'),
  basin('basin'),
  lowland('lowland'),
  tundra('tundra'),
  wetlands('wetlands'),
  desert('desert'),
  delta('delta'),
  reservoir('reservoir'),
  continent('continent'),
  geoarea('geoarea'),
  isthmus('isthmus'),
  unknown('unknown');

  const RouteRegionType(this.apiValue);

  final String apiValue;

  static RouteRegionType fromApiValue(String raw) {
    final normalized = raw.trim().toLowerCase();
    for (final value in RouteRegionType.values) {
      if (value.apiValue == normalized) return value;
    }
    return RouteRegionType.unknown;
  }
}

extension RouteRegionTypeAssetX on RouteRegionType {
  String? get assetImagePath {
    const base = 'assets/images/regions';
    switch (this) {
      case RouteRegionType.country:
      case RouteRegionType.region:
      case RouteRegionType.state:
      case RouteRegionType.province:
      case RouteRegionType.geoarea:
      case RouteRegionType.unknown:
        return '$base/generic.webp';
      case RouteRegionType.sea:
        return '$base/sea.webp';
      case RouteRegionType.ocean:
        return '$base/ocean.webp';
      case RouteRegionType.strait:
        return '$base/strait.webp';
      case RouteRegionType.channel:
        return '$base/channel.webp';
      case RouteRegionType.gulf:
        return '$base/gulf.webp';
      case RouteRegionType.bay:
        return '$base/bay.webp';
      case RouteRegionType.lake:
      case RouteRegionType.alkalineLake:
        return '$base/lake.webp';
      case RouteRegionType.island:
        return '$base/island.webp';
      case RouteRegionType.archipelago:
        return '$base/archipelago.webp';
      case RouteRegionType.peninsula:
        return '$base/peninsula.webp';
      case RouteRegionType.coast:
        return '$base/coast.webp';
      case RouteRegionType.mountainRange:
        return '$base/mountains.webp';
      case RouteRegionType.valley:
        return '$base/valley.webp';
      case RouteRegionType.plateau:
        return '$base/plateau.webp';
      case RouteRegionType.plain:
        return '$base/plain.webp';
      case RouteRegionType.basin:
        return '$base/basin.webp';
      case RouteRegionType.lowland:
        return '$base/lowland.webp';
      case RouteRegionType.tundra:
        return '$base/tundra.webp';
      case RouteRegionType.wetlands:
        return '$base/wetland.webp';
      case RouteRegionType.desert:
        return '$base/desert.webp';
      case RouteRegionType.delta:
        return '$base/delta.webp';
      case RouteRegionType.reservoir:
        return '$base/reservoir.webp';
      case RouteRegionType.continent:
        return '$base/continent.webp';
      case RouteRegionType.isthmus:
        return '$base/isthmus.webp';
    }
  }
}

class RouteRegionGeometry extends Equatable {
  const RouteRegionGeometry({required this.type, required this.geoJson});

  final String type;
  final Map<String, dynamic> geoJson;

  @override
  List<Object?> get props => [type, jsonEncode(geoJson)];
}
