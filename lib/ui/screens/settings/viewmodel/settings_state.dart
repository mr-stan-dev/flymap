import 'package:equatable/equatable.dart';
import 'package:flymap/entity/onboarding_profile.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode; // System / Dark / Light
  final String altitudeUnit; // 'ft' | 'm'
  final String speedUnit; // 'km/h' | 'mph'
  final String timeFormat; // '24h' | '12h'
  final OnboardingProfile profile;
  final String? homeAirportDisplayCode;
  final bool isLoading;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.altitudeUnit = 'ft',
    this.speedUnit = 'km/h',
    this.timeFormat = '24h',
    this.profile = const OnboardingProfile.empty(),
    this.homeAirportDisplayCode,
    this.isLoading = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? altitudeUnit,
    String? speedUnit,
    String? timeFormat,
    OnboardingProfile? profile,
    String? homeAirportDisplayCode,
    bool clearHomeAirportDisplayCode = false,
    bool? isLoading,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      altitudeUnit: altitudeUnit ?? this.altitudeUnit,
      speedUnit: speedUnit ?? this.speedUnit,
      timeFormat: timeFormat ?? this.timeFormat,
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
    profile,
    homeAirportDisplayCode,
    isLoading,
  ];
}
