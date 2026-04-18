import 'package:equatable/equatable.dart';
import 'package:flymap/entity/user_profile.dart';

class UserFlightPrefs extends Equatable {
  const UserFlightPrefs({
    required this.flyingFrequency,
    required this.homeAirportCode,
    required this.interests,
  });

  const UserFlightPrefs.empty()
    : flyingFrequency = null,
      homeAirportCode = null,
      interests = const [];

  final FlyingFrequency? flyingFrequency;
  final String? homeAirportCode;
  final List<UsersInterests> interests;

  @override
  List<Object?> get props => [flyingFrequency, homeAirportCode, interests];
}
