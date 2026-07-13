enum SkyCameraAltitudeUnit { meter, foot }

enum SkyCameraSpeedUnit { kmh, mph }

enum SkyCameraTemperatureUnit { celsius, fahrenheit }

enum SkyCameraDateDisplayFormat { monthDayYear, dayMonthYear }

class SkyCameraStrings {
  const SkyCameraStrings({
    required this.loadingCamera,
    required this.loadingGpsData,
    required this.retry,
    required this.close,
    required this.zoom,
    required this.flash,
    required this.captureFailed,
    required this.cameraUnavailable,
    required this.cameraPermissionDenied,
    required this.savedMessage,
    required this.share,
    required this.telemetrySpeed,
    required this.telemetryAltitude,
    required this.telemetryHeading,
    required this.telemetryTime,
    required this.contextCaption,
    required this.mapCaption,
    required this.coordinatesCaption,
    required this.noValuePlaceholder,
    required this.altitudeUnit,
    required this.speedUnit,
    required this.temperatureUnit,
    required this.dateDisplayFormat,
    this.settingsTitle = 'Camera settings',
    this.recordAudio = 'Record audio',
    this.recordAudioHint = 'Videos capture microphone sound.',
    this.microphonePermissionDenied =
        'Microphone access is off — videos record without sound.',
  });

  final String loadingCamera;
  final String loadingGpsData;
  final String retry;
  final String close;
  final String zoom;
  final String flash;
  final String captureFailed;
  final String cameraUnavailable;
  final String cameraPermissionDenied;
  final String savedMessage;
  final String share;
  final String telemetrySpeed;
  final String telemetryAltitude;
  final String telemetryHeading;
  final String telemetryTime;
  final String contextCaption;
  final String mapCaption;
  final String coordinatesCaption;
  final String noValuePlaceholder;
  final SkyCameraAltitudeUnit altitudeUnit;
  final SkyCameraSpeedUnit speedUnit;
  final SkyCameraTemperatureUnit temperatureUnit;
  final SkyCameraDateDisplayFormat dateDisplayFormat;
  final String settingsTitle;
  final String recordAudio;
  final String recordAudioHint;
  final String microphonePermissionDenied;
}
