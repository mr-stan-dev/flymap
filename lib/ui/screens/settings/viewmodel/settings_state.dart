import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flymap/repository/settings_repository.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode; // System / Dark / Light
  final String altitudeUnit; // 'ft' | 'm'
  final String speedUnit; // 'km/h' | 'mph'
  final String timeFormat; // '24h' | '12h'
  final String distanceUnit; // 'km' | 'mi'
  final String dateDisplayFormat; // 'MM/DD/YYYY' | 'DD/MM/YYYY'
  final String temperatureUnit; // '°C' | '°F'
  final LocaleSetting localeSetting;
  final UserProfile profile;
  final String? homeAirportDisplayCode;
  final bool isLoading;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.altitudeUnit = 'm',
    this.speedUnit = 'km/h',
    this.timeFormat = '24h',
    this.distanceUnit = 'km',
    this.dateDisplayFormat = 'MM/DD/YYYY',
    this.temperatureUnit = '°C',
    this.localeSetting = LocaleSetting.system,
    this.profile = const UserProfile.empty(),
    this.homeAirportDisplayCode,
    this.isLoading = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? altitudeUnit,
    String? speedUnit,
    String? timeFormat,
    String? distanceUnit,
    String? dateDisplayFormat,
    String? temperatureUnit,
    LocaleSetting? localeSetting,
    UserProfile? profile,
    String? homeAirportDisplayCode,
    bool clearHomeAirportDisplayCode = false,
    bool? isLoading,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      altitudeUnit: altitudeUnit ?? this.altitudeUnit,
      speedUnit: speedUnit ?? this.speedUnit,
      timeFormat: timeFormat ?? this.timeFormat,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      dateDisplayFormat: dateDisplayFormat ?? this.dateDisplayFormat,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      localeSetting: localeSetting ?? this.localeSetting,
      profile: profile ?? this.profile,
      homeAirportDisplayCode: clearHomeAirportDisplayCode
          ? null
          : homeAirportDisplayCode ?? this.homeAirportDisplayCode,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    altitudeUnit,
    speedUnit,
    timeFormat,
    distanceUnit,
    dateDisplayFormat,
    temperatureUnit,
    localeSetting,
    profile,
    homeAirportDisplayCode,
    isLoading,
  ];
}
