import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flymap/data/motion/motion_sample.dart';
import 'package:flymap/data/motion/motion_sensor_service.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/domain/usecase/get_learn_article_content_use_case.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/metric_info.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/motion/cabin_pressure_enable_card.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/motion/cabin_pressure_instrument.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/motion/g_force_instrument.dart';
import 'package:permission_handler/permission_handler.dart';

/// Owns the motion sensor stream for the dashboard and lays out the motion
/// instruments. Independent of GPS, so it keeps working with no fix at all
/// (aisle seat, phone away from the window).
///
/// The accelerometer (g-force) starts with no permission prompt. The barometer
/// (cabin pressure) needs Motion & Fitness on iOS, so it is opt-in: we show an
/// "Enable" card and only request the permission when the user taps it.
class FlightMotionSection extends StatefulWidget {
  const FlightMotionSection({super.key});

  @override
  State<FlightMotionSection> createState() => _FlightMotionSectionState();
}

class _FlightMotionSectionState extends State<FlightMotionSection>
    with WidgetsBindingObserver {
  final MotionSensorService _service = MotionSensorService();
  StreamSubscription<MotionSample>? _subscription;

  MotionSample _display = MotionSample.zero;
  int _sampleCount = 0;
  String _altitudeUnit = 'm';

  // Barometer gating: `_needsPermission` drives the iOS opt-in card;
  // `_permissionResolved` avoids a first-frame flash while the status check is
  // in flight. No cached "authorized" flag — resume re-runs _initBarometer(),
  // and startBarometer() is idempotent.
  bool _needsPermission = false;
  bool _permissionResolved = false;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service.start();
    _subscription = _service.stream.listen(_onSample);
    _loadAltitudeUnit();
    _initBarometer();
  }

  void _onSample(MotionSample sample) {
    // Repaint the numeric tiles at ~10 Hz; peak-hold lives in the service.
    _sampleCount++;
    if (_sampleCount % 5 != 0) return;
    if (!mounted) return;
    setState(() => _display = sample);
  }

  Future<void> _loadAltitudeUnit() async {
    final unit = await MetricUnitsRepository().getAltitudeUnit();
    if (!mounted) return;
    setState(() => _altitudeUnit = unit == AltitudeUnit.foot ? 'ft' : 'm');
  }

  /// Android needs no permission for the barometer; iOS gates it behind Motion
  /// & Fitness, which we only check (never request) here.
  Future<void> _initBarometer() async {
    if (!_isIOS) {
      _service.startBarometer();
      _setNeedsPermission(false);
      return;
    }
    final status = await Permission.sensors.status;
    if (status.isGranted) {
      _service.startBarometer();
      _setNeedsPermission(false);
    } else {
      _setNeedsPermission(true);
    }
  }

  Future<void> _requestMotionPermission() async {
    final current = await Permission.sensors.status;
    if (current.isPermanentlyDenied || current.isRestricted) {
      await openAppSettings();
      return;
    }
    final status = await Permission.sensors.request();
    if (!mounted) return;
    if (status.isGranted) {
      _service.startBarometer();
      _setNeedsPermission(false);
    }
  }

  void _setNeedsPermission(bool needs) {
    if (!mounted) return;
    setState(() {
      _needsPermission = needs;
      _permissionResolved = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _service.start();
      // Re-check instead of trusting the cached flag: the user may have
      // granted (or revoked) Motion in Settings while we were backgrounded —
      // this dismisses the Enable card on return without another tap.
      _initBarometer();
    } else {
      _service.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.flight.dashboard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MetricInfoSection(
          title: t.gForce,
          body: t.gForceInfoBody,
          child: GForceInstrument(
            sample: _display,
            onResetPeak: _service.resetPeak,
          ),
        ),
        ..._buildPressureSection(context, t),
      ],
    );
  }

  List<Widget> _buildPressureSection(
    BuildContext context,
    TranslationsFlightDashboardEn t,
  ) {
    // Data is flowing → the real tile.
    if (_display.pressureAvailable) {
      return [
        const SizedBox(height: DsSpacing.sm),
        MetricInfoSection(
          title: t.cabinPressure,
          body: t.cabinPressureInfoBody,
          child: CabinPressureInstrument(
            sample: _display,
            altitudeUnit: _altitudeUnit,
            onEarPainArticleTap: () => _openEarPainArticle(context),
          ),
        ),
      ];
    }
    // iOS, permission not granted → the opt-in card.
    if (_permissionResolved && _needsPermission) {
      return [
        const SizedBox(height: DsSpacing.sm),
        CabinPressureEnableCard(
          onEnable: _requestMotionPermission,
          onEarPainArticleTap: () => _openEarPainArticle(context),
        ),
      ];
    }
    // Authorized but no barometer hardware, or still resolving → nothing.
    return const [];
  }

  Future<void> _openEarPainArticle(BuildContext context) async {
    try {
      final article = await GetIt.I<GetLearnArticleContentUseCase>()(
        articleId: 'how_to_stop_your_ears_hurting_on_a_plane',
      );
      if (!context.mounted) return;
      await AppRouter.goToLearnArticle(context, article: article);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.learn.failedToLoadArticle)),
      );
    }
  }
}
