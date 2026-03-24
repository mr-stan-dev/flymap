import 'package:equatable/equatable.dart';
import 'package:flymap/entity/flight.dart';

enum ShareFlightStatus { loading, ready, sharing }

class ShareFlightState extends Equatable {
  const ShareFlightState({
    required this.flight,
    required this.status,
    this.styleString,
    this.errorMessage,
  });

  factory ShareFlightState.initial({required Flight flight}) {
    return ShareFlightState(flight: flight, status: ShareFlightStatus.loading);
  }

  final Flight flight;
  final ShareFlightStatus status;
  final String? styleString;
  final String? errorMessage;

  bool get isLoading => status == ShareFlightStatus.loading;
  bool get isSharing => status == ShareFlightStatus.sharing;

  ShareFlightState copyWith({
    Flight? flight,
    ShareFlightStatus? status,
    String? styleString,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ShareFlightState(
      flight: flight ?? this.flight,
      status: status ?? this.status,
      styleString: styleString ?? this.styleString,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [flight, status, styleString, errorMessage];
}
