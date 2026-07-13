import 'package:flutter/widgets.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:sky_camera/sky_camera.dart';

/// Builds the localized [SkyCameraStrings] outside the camera screen —
/// playback overlays and share-time burn-in need the exact same strings
/// and units the capture overlay used.
class FlymapSkyCameraStringsBuilder {
  const FlymapSkyCameraStringsBuilder._();

  static Future<SkyCameraStrings> build(BuildContext context) async {
    // Capture every localized string before the first await: the context
    // must not be touched across async gaps.
    final skyCameraT = context.t.skyCamera;
    final commonT = context.t.common;
    final loadingCamera = skyCameraT.loading;
    final loadingGpsData = skyCameraT.loadingGpsData;
    final retry = commonT.retry;
    final close = commonT.cancel;
    final zoom = skyCameraT.zoom;
    final flash = skyCameraT.flash;
    final captureFailed = skyCameraT.captureFailed;
    final cameraUnavailable = skyCameraT.cameraUnavailable;
    final cameraPermissionDenied = skyCameraT.cameraPermissionDenied;
    final savedMessage = skyCameraT.savedMessage;
    final share = skyCameraT.share;
    final telemetrySpeed = skyCameraT.telemetrySpeed;
    final telemetryAltitude = skyCameraT.telemetryAltitude;
    final telemetryHeading = skyCameraT.telemetryHeading;
    final telemetryTime = skyCameraT.telemetryTime;
    final contextCaption = skyCameraT.contextCaption;
    final mapCaption = skyCameraT.mapCaption;
    final coordinatesCaption = skyCameraT.coordinatesCaption;
    final noValuePlaceholder = skyCameraT.noValuePlaceholder;
    final settingsTitle = skyCameraT.settingsTitle;
    final recordAudio = skyCameraT.recordAudio;
    final recordAudioHint = skyCameraT.recordAudioHint;
    final microphonePermissionDenied = skyCameraT.microphonePermissionDenied;

    final metricUnits = GetIt.I<MetricUnitsRepository>();
    final altitudeUnit = await metricUnits.getAltitudeUnit();
    final speedUnit = await metricUnits.getSpeedUnit();
    final temperatureUnit = await metricUnits.getTemperatureUnit();
    final dateDisplayFormat = await metricUnits.getDateDisplayFormat();

    return SkyCameraStrings(
      loadingCamera: loadingCamera,
      loadingGpsData: loadingGpsData,
      retry: retry,
      close: close,
      zoom: zoom,
      flash: flash,
      captureFailed: captureFailed,
      cameraUnavailable: cameraUnavailable,
      cameraPermissionDenied: cameraPermissionDenied,
      savedMessage: savedMessage,
      share: share,
      telemetrySpeed: telemetrySpeed,
      telemetryAltitude: telemetryAltitude,
      telemetryHeading: telemetryHeading,
      telemetryTime: telemetryTime,
      contextCaption: contextCaption,
      mapCaption: mapCaption,
      coordinatesCaption: coordinatesCaption,
      noValuePlaceholder: noValuePlaceholder,
      altitudeUnit: altitudeUnit == AltitudeUnit.meter
          ? SkyCameraAltitudeUnit.meter
          : SkyCameraAltitudeUnit.foot,
      speedUnit: speedUnit == SpeedUnit.mph
          ? SkyCameraSpeedUnit.mph
          : SkyCameraSpeedUnit.kmh,
      temperatureUnit: temperatureUnit == TemperatureUnit.fahrenheit
          ? SkyCameraTemperatureUnit.fahrenheit
          : SkyCameraTemperatureUnit.celsius,
      dateDisplayFormat: dateDisplayFormat == DateDisplayFormat.international
          ? SkyCameraDateDisplayFormat.dayMonthYear
          : SkyCameraDateDisplayFormat.monthDayYear,
      settingsTitle: settingsTitle,
      recordAudio: recordAudio,
      recordAudioHint: recordAudioHint,
      microphonePermissionDenied: microphonePermissionDenied,
    );
  }
}
