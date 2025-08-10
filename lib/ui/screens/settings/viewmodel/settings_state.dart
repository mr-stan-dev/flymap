import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode; // Dark / Light
  final String altitudeUnit; // 'ft' | 'm'
  final String speedUnit; // 'km/h' | 'mph'
  final String timeFormat; // '24h' | '12h'
  final bool isLoading;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.altitudeUnit = 'ft',
    this.speedUnit = 'km/h',
    this.timeFormat = '24h',
    this.isLoading = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? altitudeUnit,
    String? speedUnit,
    String? timeFormat,
    bool? isLoading,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      altitudeUnit: altitudeUnit ?? this.altitudeUnit,
      speedUnit: speedUnit ?? this.speedUnit,
      timeFormat: timeFormat ?? this.timeFormat,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    altitudeUnit,
    speedUnit,
    timeFormat,
    isLoading,
  ];
}
