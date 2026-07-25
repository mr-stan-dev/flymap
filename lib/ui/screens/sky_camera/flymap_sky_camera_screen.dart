import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/app/feature_flags.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:flymap/repository/settings_repository.dart';
import 'package:flymap/repository/sky_camera_media_repository.dart';
import 'package:flymap/ui/screens/home/tabs/media/media_capture_preview_screen.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_session_factory.dart';
import 'package:get_it/get_it.dart';
import 'package:sky_camera/sky_camera.dart';

class FlymapSkyCameraScreen extends StatefulWidget {
  const FlymapSkyCameraScreen({super.key}) : flightId = null;

  const FlymapSkyCameraScreen.forFlight({
    required String this.flightId,
    super.key,
  });

  final String? flightId;

  @override
  State<FlymapSkyCameraScreen> createState() => _FlymapSkyCameraScreenState();
}

class _FlymapSkyCameraScreenState extends State<FlymapSkyCameraScreen> {
  FlymapSkyCameraSession? _session;
  bool _isLoadingSession = false;
  bool _didShowNoFlightContextDialog = false;
  // Transient value shown until the saved unit loads from the repo (which
  // now defaults to meters); avoids a feet flash on open.
  SkyCameraAltitudeUnit _altitudeUnit = SkyCameraAltitudeUnit.meter;
  SkyCameraSpeedUnit _speedUnit = SkyCameraSpeedUnit.kmh;
  SkyCameraTemperatureUnit _temperatureUnit = SkyCameraTemperatureUnit.celsius;
  SkyCameraDateDisplayFormat _dateDisplayFormat =
      SkyCameraDateDisplayFormat.monthDayYear;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_session != null || _isLoadingSession) return;
    _isLoadingSession = true;
    unawaited(_loadSession());
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return SkyCameraScreen(
      driver: session.driver,
      snapshotSource: session.snapshotSource,
      exportService: session.exportService,
      observer: session.observer,
      videoCaptureEnabled: FeatureFlags.skyCameraVideoCapture,
      overlayComposer: const SkyCameraOverlayComposer(),
      photoCropper: const SkyCameraPhotoCropper(),
      openCapturePreview: _openCapturePreview,
      onRecordAudioChanged: (enabled) => unawaited(
        GetIt.I<SettingsRepository>().setSkyCameraRecordAudio(enabled),
      ),
      strings: SkyCameraStrings(
        loadingCamera: context.t.skyCamera.loading,
        loadingGpsData: context.t.skyCamera.loadingGpsData,
        retry: context.t.common.retry,
        close: context.t.common.cancel,
        zoom: context.t.skyCamera.zoom,
        flash: context.t.skyCamera.flash,
        captureFailed: context.t.skyCamera.captureFailed,
        cameraUnavailable: context.t.skyCamera.cameraUnavailable,
        cameraPermissionDenied: context.t.skyCamera.cameraPermissionDenied,
        savedMessage: context.t.skyCamera.savedMessage,
        share: context.t.skyCamera.share,
        telemetrySpeed: context.t.skyCamera.telemetrySpeed,
        telemetryAltitude: context.t.skyCamera.telemetryAltitude,
        telemetryHeading: context.t.skyCamera.telemetryHeading,
        telemetryTime: context.t.skyCamera.telemetryTime,
        contextCaption: context.t.skyCamera.contextCaption,
        mapCaption: context.t.skyCamera.mapCaption,
        coordinatesCaption: context.t.skyCamera.coordinatesCaption,
        noValuePlaceholder: context.t.skyCamera.noValuePlaceholder,
        altitudeUnit: _altitudeUnit,
        speedUnit: _speedUnit,
        temperatureUnit: _temperatureUnit,
        dateDisplayFormat: _dateDisplayFormat,
        settingsTitle: context.t.skyCamera.settingsTitle,
        recordAudio: context.t.skyCamera.recordAudio,
        recordAudioHint: context.t.skyCamera.recordAudioHint,
        microphonePermissionDenied:
            context.t.skyCamera.microphonePermissionDenied,
      ),
    );
  }

  Future<Set<String>> _openCapturePreview(
    BuildContext context,
    List<SkyCameraSavedCapture> savedCaptures,
    String initialCaptureId,
  ) async {
    final repository = GetIt.I<SkyCameraMediaRepository>();
    final captures = await repository.getCapturesByIds(
      savedCaptures.map((capture) => capture.id),
    );
    if (captures.isEmpty || !context.mounted) return const <String>{};
    final deletedCaptureIds = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute<Set<String>>(
        builder: (_) => MediaCapturePreviewScreen(
          captures: captures,
          initialCaptureId: initialCaptureId,
          onDelete: (captureId) => repository.deleteCaptureIds([captureId]),
        ),
      ),
    );
    return deletedCaptureIds ?? const <String>{};
  }

  Future<void> _loadSession() async {
    final factory = GetIt.I<FlymapSkyCameraSessionFactory>();
    final metricUnitsRepository = GetIt.I<MetricUnitsRepository>();
    final skyCameraT = context.t.skyCamera;
    final placeholderContext = skyCameraT.placeholderContext;
    final placeholderMap = skyCameraT.placeholderMap;
    final altitudeUnit = await metricUnitsRepository.getAltitudeUnit();
    final speedUnit = await metricUnitsRepository.getSpeedUnit();
    final temperatureUnit = await metricUnitsRepository.getTemperatureUnit();
    final dateDisplayFormat = await metricUnitsRepository
        .getDateDisplayFormat();
    final recordAudioEnabled = await GetIt.I<SettingsRepository>()
        .getSkyCameraRecordAudio();
    final currentFlight = await _currentFlight(factory);
    if (!mounted) return;
    final placeholderCopy = _buildPlaceholderCopy(
      currentFlight,
      placeholderContext: placeholderContext,
      placeholderMap: placeholderMap,
    );
    setState(() {
      _altitudeUnit = _mapAltitudeUnit(altitudeUnit);
      _speedUnit = _mapSpeedUnit(speedUnit);
      _temperatureUnit = _mapTemperatureUnit(temperatureUnit);
      _dateDisplayFormat = _mapDateDisplayFormat(dateDisplayFormat);
      _session = currentFlight == null
          ? factory.create(
              placeholderCopy: placeholderCopy,
              recordAudioEnabled: recordAudioEnabled,
            )
          : factory.createForFlight(
              placeholderCopy: placeholderCopy,
              flightId: currentFlight.id,
              recordAudioEnabled: recordAudioEnabled,
            );
      _isLoadingSession = false;
    });
    if (currentFlight == null) {
      _showNoFlightContextDialog();
    }
  }

  FlymapSkyCameraPlaceholderCopy _buildPlaceholderCopy(
    Flight? flight, {
    required String placeholderContext,
    required String placeholderMap,
  }) {
    if (flight != null) {
      final departure = flight.departure;
      final arrival = flight.arrival;
      final departureCity = departure.city.trim().isNotEmpty
          ? departure.city.trim()
          : departure.nameShort;
      final arrivalCity = arrival.city.trim().isNotEmpty
          ? arrival.city.trim()
          : arrival.nameShort;
      return FlymapSkyCameraPlaceholderCopy(
        routeLabel: flight.route.isDomestic
            ? '$departureCity → $arrivalCity'
            : '$departureCity, ${departure.countryCode} → '
                  '$arrivalCity, ${arrival.countryCode}',
        originCode: departure.displayCode,
        destinationCode: arrival.displayCode,
        originCountryCode: departure.countryCode,
        destinationCountryCode: arrival.countryCode,
        contextLabel: placeholderContext,
        mapPlaceholder: placeholderMap,
      );
    }
    return FlymapSkyCameraPlaceholderCopy(
      routeLabel: '',
      originCode: '',
      destinationCode: '',
      originCountryCode: '',
      destinationCountryCode: '',
      contextLabel: placeholderContext,
      mapPlaceholder: placeholderMap,
    );
  }

  Future<Flight?> _currentFlight(FlymapSkyCameraSessionFactory factory) async {
    final requestedFlightId = widget.flightId;
    if (requestedFlightId != null) {
      return factory.flightRepository.getFlightById(requestedFlightId);
    }
    final flights = await factory.flightRepository.getAllFlights();
    final inProgressFlights = flights
        .where((flight) => flight.status == FlightStatus.inProgress)
        .toList(growable: false);
    if (inProgressFlights.isEmpty) return null;
    inProgressFlights.sort((a, b) {
      final aDate = a.inProgressAt ?? a.createdAt;
      final bDate = b.inProgressAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    return inProgressFlights.first;
  }

  SkyCameraAltitudeUnit _mapAltitudeUnit(AltitudeUnit unit) {
    return unit == AltitudeUnit.meter
        ? SkyCameraAltitudeUnit.meter
        : SkyCameraAltitudeUnit.foot;
  }

  SkyCameraSpeedUnit _mapSpeedUnit(SpeedUnit unit) {
    return unit == SpeedUnit.mph
        ? SkyCameraSpeedUnit.mph
        : SkyCameraSpeedUnit.kmh;
  }

  SkyCameraTemperatureUnit _mapTemperatureUnit(TemperatureUnit unit) {
    return unit == TemperatureUnit.fahrenheit
        ? SkyCameraTemperatureUnit.fahrenheit
        : SkyCameraTemperatureUnit.celsius;
  }

  SkyCameraDateDisplayFormat _mapDateDisplayFormat(DateDisplayFormat format) {
    return format == DateDisplayFormat.international
        ? SkyCameraDateDisplayFormat.dayMonthYear
        : SkyCameraDateDisplayFormat.monthDayYear;
  }

  void _showNoFlightContextDialog() {
    if (_didShowNoFlightContextDialog || !mounted) return;
    _didShowNoFlightContextDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final t = dialogContext.t;
          return AlertDialog(
            title: Text(t.skyCamera.noActiveFlightTitle),
            content: Text(t.skyCamera.noActiveFlightMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(t.common.ok),
              ),
            ],
          );
        },
      );
    });
  }
}
