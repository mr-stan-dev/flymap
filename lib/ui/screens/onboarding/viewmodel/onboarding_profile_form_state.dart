import 'package:equatable/equatable.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/onboarding_profile.dart';

class OnboardingProfileFormState extends Equatable {
  const OnboardingProfileFormState({
    required this.isLoading,
    required this.profile,
    required this.homeAirport,
    required this.airportQuery,
    required this.isAirportSearchLoading,
    required this.airportSearchResults,
    required this.favoriteAirports,
    required this.recentAirports,
    required this.popularAirports,
    required this.errorMessage,
  });

  const OnboardingProfileFormState.initial()
    : isLoading = true,
      profile = const OnboardingProfile.empty(),
      homeAirport = null,
      airportQuery = '',
      isAirportSearchLoading = false,
      airportSearchResults = const [],
      favoriteAirports = const [],
      recentAirports = const [],
      popularAirports = const [],
      errorMessage = null;

  static const int maxInterests = 3;

  final bool isLoading;
  final OnboardingProfile profile;
  final Airport? homeAirport;
  final String airportQuery;
  final bool isAirportSearchLoading;
  final List<Airport> airportSearchResults;
  final List<Airport> favoriteAirports;
  final List<Airport> recentAirports;
  final List<Airport> popularAirports;
  final String? errorMessage;

  bool get hasReachedInterestLimit => profile.interests.length >= maxInterests;

  OnboardingProfileFormState copyWith({
    bool? isLoading,
    OnboardingProfile? profile,
    Airport? homeAirport,
    bool clearHomeAirport = false,
    String? airportQuery,
    bool? isAirportSearchLoading,
    List<Airport>? airportSearchResults,
    List<Airport>? favoriteAirports,
    List<Airport>? recentAirports,
    List<Airport>? popularAirports,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return OnboardingProfileFormState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      homeAirport: clearHomeAirport ? null : homeAirport ?? this.homeAirport,
      airportQuery: airportQuery ?? this.airportQuery,
      isAirportSearchLoading:
          isAirportSearchLoading ?? this.isAirportSearchLoading,
      airportSearchResults: airportSearchResults ?? this.airportSearchResults,
      favoriteAirports: favoriteAirports ?? this.favoriteAirports,
      recentAirports: recentAirports ?? this.recentAirports,
      popularAirports: popularAirports ?? this.popularAirports,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    profile,
    homeAirport,
    airportQuery,
    isAirportSearchLoading,
    airportSearchResults,
    favoriteAirports,
    recentAirports,
    popularAirports,
    errorMessage,
  ];
}
