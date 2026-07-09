import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_video_spec.dart';

enum FlightVideoStatus {
  initial,
  preparing,
  previewReady,
  exporting,
  exported,
  sharing,
  error,
}

enum FlightVideoErrorKind { network, encoder, generic }

class FlightVideoState extends Equatable {
  const FlightVideoState({
    required this.flightId,
    required this.flight,
    required this.status,
    this.style = FlightVideoMapStyle.outdoors,
    this.isPro = false,
    this.watermarkRemoved = false,
    this.mysteryDestination = false,
    this.showPins = false,
    this.showEndCard = true,
    this.avatarEnabled = false,
    this.prepareProgress = 0,
    this.exportProgress = 0,
    this.isApplyingSettings = false,
    this.applyProgress = 0,
    this.videoPath,
    this.savedToGallery = false,
    this.errorKind,
  });

  factory FlightVideoState.initial({required String flightId}) {
    return FlightVideoState(
      flightId: flightId,
      flight: null,
      status: FlightVideoStatus.initial,
    );
  }

  final String flightId;
  final Flight? flight;
  final FlightVideoStatus status;
  final FlightVideoMapStyle style;
  final bool isPro;

  /// Pro-only: brand watermark switched off for this video.
  final bool watermarkRemoved;

  /// "Open final" mode: the header hides the destination behind "?" until
  /// the plane lands. Available to everyone.
  final bool mysteryDestination;

  /// Show country pins on the map. Off by default.
  final bool showPins;

  /// Show the outro info card. On by default.
  final bool showEndCard;

  /// Show the user's avatar (photo on the plane + summary card). Off by
  /// default; the photo/name live in [VideoAvatarRepository].
  final bool avatarEnabled;

  /// Tile prefetch progress 0..1 while [FlightVideoStatus.preparing].
  final double prepareProgress;

  /// Frame render/encode progress 0..1 while [FlightVideoStatus.exporting].
  final double exportProgress;

  /// A settings apply (batch) is in flight from the settings sheet. The status
  /// stays [FlightVideoStatus.previewReady] so the current preview keeps
  /// showing while a style change downloads its tiles in the background.
  final bool isApplyingSettings;

  /// Progress 0..1 of the in-flight settings apply (tile download on a style
  /// change); 0 for instant, non-style changes.
  final double applyProgress;

  final String? videoPath;
  final bool savedToGallery;
  final FlightVideoErrorKind? errorKind;

  bool get isPreparing =>
      status == FlightVideoStatus.initial ||
      status == FlightVideoStatus.preparing;
  bool get isExporting => status == FlightVideoStatus.exporting;
  bool get isExported =>
      status == FlightVideoStatus.exported ||
      status == FlightVideoStatus.sharing;
  bool get isSharing => status == FlightVideoStatus.sharing;
  bool get isError => status == FlightVideoStatus.error;
  bool get hasPreview =>
      status == FlightVideoStatus.previewReady ||
      status == FlightVideoStatus.exporting ||
      isExported;

  FlightVideoState copyWith({
    Flight? flight,
    FlightVideoStatus? status,
    FlightVideoMapStyle? style,
    bool? isPro,
    bool? watermarkRemoved,
    bool? mysteryDestination,
    bool? showPins,
    bool? showEndCard,
    bool? avatarEnabled,
    double? prepareProgress,
    double? exportProgress,
    bool? isApplyingSettings,
    double? applyProgress,
    String? videoPath,
    bool? savedToGallery,
    FlightVideoErrorKind? errorKind,
    bool clearError = false,
  }) {
    return FlightVideoState(
      flightId: flightId,
      flight: flight ?? this.flight,
      status: status ?? this.status,
      style: style ?? this.style,
      isPro: isPro ?? this.isPro,
      watermarkRemoved: watermarkRemoved ?? this.watermarkRemoved,
      mysteryDestination: mysteryDestination ?? this.mysteryDestination,
      showPins: showPins ?? this.showPins,
      showEndCard: showEndCard ?? this.showEndCard,
      avatarEnabled: avatarEnabled ?? this.avatarEnabled,
      prepareProgress: prepareProgress ?? this.prepareProgress,
      exportProgress: exportProgress ?? this.exportProgress,
      isApplyingSettings: isApplyingSettings ?? this.isApplyingSettings,
      applyProgress: applyProgress ?? this.applyProgress,
      videoPath: videoPath ?? this.videoPath,
      savedToGallery: savedToGallery ?? this.savedToGallery,
      errorKind: clearError ? null : (errorKind ?? this.errorKind),
    );
  }

  // Deliberately concise: the default Equatable stringify dumps the whole
  // Flight (every waypoint) on each emit, and the BlocObserver logs it — which
  // froze the UI thread during high-frequency progress emits (tile prefetch,
  // frame export). Keep it cheap to build.
  @override
  String toString() =>
      'FlightVideoState(${status.name}, style: ${style.name}, isPro: $isPro, '
      'watermarkRemoved: $watermarkRemoved, mystery: $mysteryDestination, '
      'pins: $showPins, endCard: $showEndCard, avatar: $avatarEnabled, '
      'prepare: ${prepareProgress.toStringAsFixed(2)}, '
      'export: ${exportProgress.toStringAsFixed(2)}, '
      'applying: $isApplyingSettings ${applyProgress.toStringAsFixed(2)}, '
      'flightId: $flightId, error: $errorKind)';

  @override
  List<Object?> get props => [
    flightId,
    flight,
    status,
    style,
    isPro,
    watermarkRemoved,
    mysteryDestination,
    showPins,
    showEndCard,
    avatarEnabled,
    prepareProgress,
    exportProgress,
    isApplyingSettings,
    applyProgress,
    videoPath,
    savedToGallery,
    errorKind,
  ];
}
