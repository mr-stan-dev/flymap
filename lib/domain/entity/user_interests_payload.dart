import 'package:flymap/domain/entity/user_profile.dart';

extension UsersInterestsPayload on UsersInterests {
  String get payloadValue {
    return switch (this) {
      UsersInterests.mountains => 'Mountains & ridges',
      UsersInterests.volcanoes => 'Volcanoes & geology',
      UsersInterests.regions => 'Cities & regions',
      UsersInterests.islands => 'Islands & coastlines',
      UsersInterests.nationalParks => 'National parks & reserves',
      UsersInterests.rivers => 'Rivers & lakes',
    };
  }

  static UsersInterests? fromStorageValue(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final normalized = value.toLowerCase();
    final compact = normalized.replaceAll(RegExp(r'[^a-z]'), '');

    return switch (normalized) {
          'mountains' || 'mountains & ridges' => UsersInterests.mountains,
          'volcanoes' || 'volcanoes & geology' => UsersInterests.volcanoes,
          'regions' || 'cities' || 'cities & regions' => UsersInterests.regions,
          'islands' ||
          'coastlines' ||
          'islands & coastlines' => UsersInterests.islands,
          'national_parks' ||
          'nationalparks' ||
          'landmarks' ||
          'national parks' ||
          'national parks & reserves' => UsersInterests.nationalParks,
          'rivers' ||
          'rivers_lakes' ||
          'riverslakes' ||
          'rivers & lakes' => UsersInterests.rivers,
          'volcanoesgeology' ||
          'volcanoes_geology' => UsersInterests.volcanoes,
          _ => null,
        } ??
        switch (compact) {
          'nationalparksandreserves' => UsersInterests.nationalParks,
          'riversandlakes' => UsersInterests.rivers,
          _ => null,
        };
  }
}
