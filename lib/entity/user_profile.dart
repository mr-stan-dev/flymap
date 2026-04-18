import 'package:equatable/equatable.dart';

enum FlyingFrequency { firstFlight, fewPerYear, monthly, frequent }

enum UsersInterests {
  mountains,
  cities,
  coastlines,
  landmarks,
  aviationHistory,
  engineering,
}

class UserProfile extends Equatable {
  const UserProfile({
    required this.displayName,
    required this.flyingFrequency,
    required this.homeAirportCode,
    required this.interests,
  });

  const UserProfile.empty()
    : displayName = '',
      flyingFrequency = null,
      homeAirportCode = null,
      interests = const [];

  final String displayName;
  final FlyingFrequency? flyingFrequency;
  final String? homeAirportCode;
  final List<UsersInterests> interests;

  bool get hasInterests => interests.isNotEmpty;
  bool get hasProfileDetails =>
      displayName.trim().isNotEmpty ||
      flyingFrequency != null ||
      homeAirportCode != null ||
      interests.isNotEmpty;

  UserProfile copyWith({
    String? displayName,
    FlyingFrequency? flyingFrequency,
    bool clearFlyingFrequency = false,
    String? homeAirportCode,
    bool clearHomeAirportCode = false,
    List<UsersInterests>? interests,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      flyingFrequency: clearFlyingFrequency
          ? null
          : flyingFrequency ?? this.flyingFrequency,
      homeAirportCode: clearHomeAirportCode
          ? null
          : homeAirportCode ?? this.homeAirportCode,
      interests: interests ?? this.interests,
    );
  }

  @override
  List<Object?> get props => [
    displayName,
    flyingFrequency,
    homeAirportCode,
    interests,
  ];
}
