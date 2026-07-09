import 'dart:async';
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/analytics/events/flight_video_generated_event.dart';
import 'package:flymap/analytics/events/flight_video_preview_ready_event.dart';
import 'package:flymap/analytics/events/flight_video_shared_event.dart';
import 'package:flymap/data/flight_video/media_gallery_saver.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_video_spec.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/domain/usecase/generate_flight_video_use_case.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/rating/rate_prompt_policy_service.dart';
import 'package:flymap/rating/rate_prompt_trigger.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/repository/video_avatar_repository.dart';
import 'package:flymap/ui/screens/share_flight/widgets/card/utils/share_image_card_formatters.dart';
import 'package:flymap/utils/route_utils.dart';
import 'package:flymap/utils/unit_format_utils.dart';
import 'package:get_it/get_it.dart';
import 'package:share_plus/share_plus.dart';

import 'flight_video_state.dart';

/// Outcome of [FlightVideoCubit.applySettings], so the screen can surface an
/// offline notice when a map-style change couldn't download its tiles.
enum FlightVideoApplyResult { done, styleOffline }

/// Drives the flight-video screen.
///
/// State flow: initial → preparing(tiles) → previewReady → exporting(frames)
/// → exported(videoPath) → sharing → exported, with error(kind) + retry.
class FlightVideoCubit extends Cubit<FlightVideoState> {
  FlightVideoCubit({required String flightId})
    : _useCase = GetIt.I.get<GenerateFlightVideoUseCase>(),
      _flightRepository = GetIt.I.get<FlightRepository>(),
      _unitsRepository = GetIt.I.get<MetricUnitsRepository>(),
      _gallerySaver = GetIt.I.get<MediaGallerySaver>(),
      _subscriptionRepository = GetIt.I.get<SubscriptionRepository>(),
      _ratePromptPolicyService = GetIt.I.get<RatePromptPolicyService>(),
      _avatarRepository = GetIt.I.get<VideoAvatarRepository>(),
      _connectivity = GetIt.I.get<ConnectivityChecker>(),
      _analytics = GetIt.I.get<AppAnalytics>(),
      super(FlightVideoState.initial(flightId: flightId)) {
    _prepare();
  }

  final GenerateFlightVideoUseCase _useCase;
  final FlightRepository _flightRepository;
  final MetricUnitsRepository _unitsRepository;
  final MediaGallerySaver _gallerySaver;
  final SubscriptionRepository _subscriptionRepository;
  final RatePromptPolicyService _ratePromptPolicyService;
  final VideoAvatarRepository _avatarRepository;
  final ConnectivityChecker _connectivity;
  final AppAnalytics _analytics;
  final Logger _logger = const Logger('FlightVideoCubit');

  FlightVideoSession? _session;
  FlightVideoCancelToken? _cancelToken;

  /// Rendering session for the live preview; available once `hasPreview`.
  FlightVideoSession? get session => _session;

  Future<void> _prepare() async {
    emit(
      state.copyWith(
        status: FlightVideoStatus.preparing,
        prepareProgress: 0,
        clearError: true,
      ),
    );

    final flight = await _flightRepository.getFlightById(state.flightId);
    if (isClosed) return;
    if (flight == null) {
      _analytics.log(
        const FlightVideoGeneratedEvent(
          success: false,
          error: 'flight_not_found',
        ),
      );
      emit(
        state.copyWith(
          status: FlightVideoStatus.error,
          errorKind: FlightVideoErrorKind.generic,
        ),
      );
      return;
    }

    // Pro perks (remove watermark, full resolution) apply to subscribers AND
    // to a flight that was unlocked with a one-time purchase.
    final isPro =
        _subscriptionRepository.currentStatus.isPro || flight.hasProAccess;
    if (isPro != state.isPro || (!isPro && state.watermarkRemoved)) {
      emit(
        state.copyWith(
          isPro: isPro,
          watermarkRemoved: isPro && state.watermarkRemoved,
        ),
      );
    }

    final avatar = await _avatarRepository.load();
    if (isClosed) return;

    // Video generation streams live map tiles, so it needs a connection. Bail
    // out early with a clear offline state instead of grinding through a doomed
    // tile prefetch — users often open this in Flight Mode.
    if (!await _connectivity.hasInternetConnectivity()) {
      if (isClosed) return;
      _analytics.log(
        const FlightVideoGeneratedEvent(success: false, error: 'offline'),
      );
      emit(
        state.copyWith(
          status: FlightVideoStatus.error,
          errorKind: FlightVideoErrorKind.offline,
        ),
      );
      return;
    }

    final cancel = FlightVideoCancelToken();
    _cancelToken = cancel;
    final session = await _useCase.prepare(
      flight,
      texts: await _buildTexts(flight),
      style: state.style,
      isPro: isPro,
      avatarEnabled: avatar.enabled,
      avatarPath: avatar.imagePath,
      cancel: cancel,
      onTileProgress: (done, total) {
        if (isClosed || cancel.isCancelled) return;
        emit(
          state.copyWith(
            status: FlightVideoStatus.preparing,
            prepareProgress: total == 0 ? 1 : done / total,
          ),
        );
      },
    );
    if (isClosed || cancel.isCancelled) {
      session?.dispose();
      return;
    }

    if (session == null) {
      // Tell "connection dropped mid-prefetch" apart from a server/other
      // failure, so the offline state can explain Flight Mode.
      final offline = !await _connectivity.hasInternetConnectivity();
      if (isClosed) return;
      _analytics.log(
        FlightVideoGeneratedEvent(
          success: false,
          error: offline ? 'offline' : 'prepare',
        ),
      );
      emit(
        state.copyWith(
          status: FlightVideoStatus.error,
          errorKind: offline
              ? FlightVideoErrorKind.offline
              : FlightVideoErrorKind.network,
        ),
      );
      return;
    }

    _session = session;
    session.renderer.watermarkEnabled = !state.watermarkRemoved;
    session.renderer.mysteryDestination = state.mysteryDestination;
    session.renderer.showPins = state.showPins;
    session.renderer.showEndCard = state.showEndCard;
    // The avatar (showAvatar/name/photo) was applied inside prepare from the
    // repo config; mirror the enabled flag into state.
    _analytics.log(
      FlightVideoPreviewReadyEvent(
        videoSeconds: session.spec.duration.inSeconds,
        tileCount: session.tileCount,
      ),
    );
    emit(
      state.copyWith(
        flight: flight,
        status: FlightVideoStatus.previewReady,
        avatarEnabled: avatar.enabled,
      ),
    );
  }

  /// Applies a whole batch of settings at once (from the sheet's Apply
  /// button) instead of live per-toggle. The preview re-renders a single time
  /// rather than churning on every switch — which also keeps the 60fps preview
  /// paint from competing with a per-toggle rebuild on the UI thread.
  ///
  /// Cheap renderer flags (mystery/pins/end card/watermark) apply to the
  /// cached renderer instantly; the session is only rebuilt when the map style
  /// changes or a fresh Pro upgrade needs full-resolution tiles.
  Future<FlightVideoApplyResult> applySettings({
    required FlightVideoMapStyle style,
    required bool mysteryDestination,
    required bool showPins,
    required bool showEndCard,
    required bool watermarkRemoved,
    required bool avatarEnabled,
  }) async {
    if (state.isExporting || state.isSharing || state.isPreparing) {
      return FlightVideoApplyResult.done;
    }

    // The avatar isn't Pro-gated: persist the toggle and read the stored photo
    // (the setup sheet already saved the picked file to the repo).
    await _avatarRepository.setEnabled(avatarEnabled);
    final avatar = await _avatarRepository.load();
    if (isClosed) return FlightVideoApplyResult.done;

    // Resolve the watermark request against Pro access / the paywall.
    var effectiveWatermarkRemoved = state.watermarkRemoved;
    var isPro = state.isPro;
    if (watermarkRemoved != state.watermarkRemoved) {
      if (!watermarkRemoved) {
        effectiveWatermarkRemoved = false;
      } else if (state.isPro) {
        effectiveWatermarkRemoved = true;
      } else {
        try {
          await _subscriptionRepository.presentPaywallIfNeeded();
        } catch (e) {
          _logger.error('Paywall failed: $e');
        }
        if (isClosed) return FlightVideoApplyResult.done;
        if (_subscriptionRepository.currentStatus.isPro) {
          isPro = true;
          effectiveWatermarkRemoved = true;
        }
      }
    }

    final styleChanged = style != state.style;
    // A fresh Pro upgrade must re-prepare for full-resolution tiles.
    final becamePro = isPro && !state.isPro;
    _logger.log(
      'applySettings: styleChanged=$styleChanged (${state.style.name}'
      '->${style.name}), becamePro=$becamePro',
    );

    // Cheap flags apply to the cached renderer immediately (it's reused across
    // a restyle, so these stick).
    _session?.renderer
      ?..mysteryDestination = mysteryDestination
      ..showPins = showPins
      ..showEndCard = showEndCard
      ..watermarkEnabled = !effectiveWatermarkRemoved;

    // The avatar may need a photo decode (first enable / changed photo), so it
    // goes through the use case rather than the cheap cascade. A Pro rebuild
    // re-prepares below and reloads the avatar from the repo, so skip it there.
    final avatarSession = _session;
    if (!becamePro && avatarSession != null) {
      await _useCase.applyAvatar(
        avatarSession,
        enabled: avatarEnabled,
        path: avatar.imagePath,
      );
      if (isClosed) return FlightVideoApplyResult.done;
    }

    emit(
      state.copyWith(
        // Style is committed only once its tiles are ready (below); the cheap
        // flags apply now.
        style: styleChanged && !becamePro ? state.style : style,
        isPro: isPro,
        watermarkRemoved: effectiveWatermarkRemoved,
        mysteryDestination: mysteryDestination,
        showPins: showPins,
        showEndCard: showEndCard,
        avatarEnabled: avatarEnabled,
      ),
    );

    // A style change and a Pro re-prepare both download tiles — guard them
    // behind a connectivity check so an offline change fails fast with a hint
    // instead of spinning on doomed downloads. (The cheap flags already applied
    // above; only the tile download is blocked.)
    if ((styleChanged || becamePro) &&
        !await _connectivity.hasInternetConnectivity()) {
      return isClosed
          ? FlightVideoApplyResult.done
          : FlightVideoApplyResult.styleOffline;
    }

    // A Pro upgrade changes resolution → full rebuild (tears down to prepare).
    if (becamePro) {
      _cancelToken?.cancel();
      _session?.dispose();
      _session = null;
      await _prepare();
      return FlightVideoApplyResult.done;
    }

    // A pure style change reuses the renderer: download the new style's tiles
    // in the background while the current preview stays up, then swap.
    final current = _session;
    if (styleChanged && current != null) {
      final cancel = FlightVideoCancelToken();
      _cancelToken = cancel;
      emit(state.copyWith(isApplyingSettings: true, applyProgress: 0));
      final next = await _useCase.restyle(
        current,
        style: style,
        cancel: cancel,
        onProgress: (done, total) {
          if (isClosed || cancel.isCancelled) return;
          emit(state.copyWith(applyProgress: total == 0 ? 1 : done / total));
        },
      );
      // restyle only returns non-null on full success (it has already freed
      // the old tiles and retiled the shared renderer). It shares that
      // renderer with `current`, so we must never dispose it here — always
      // adopt it as the live session; close() disposes it once.
      if (next == null) {
        // Cancelled or failed with the old session left intact.
        if (!isClosed) emit(state.copyWith(isApplyingSettings: false));
        return FlightVideoApplyResult.done;
      }
      _session = next;
      if (isClosed) return FlightVideoApplyResult.done;
      emit(state.copyWith(style: style, isApplyingSettings: false));
    }
    return FlightVideoApplyResult.done;
  }

  Future<void> exportAndSave() async {
    final session = _session;
    if (session == null || state.status != FlightVideoStatus.previewReady) {
      return;
    }

    emit(state.copyWith(status: FlightVideoStatus.exporting, exportProgress: 0));
    final cancel = FlightVideoCancelToken();
    _cancelToken = cancel;
    final stopwatch = Stopwatch()..start();

    final path = await _useCase.export(
      session,
      cancel: cancel,
      onProgress: (fraction) {
        if (isClosed || cancel.isCancelled) return;
        emit(
          state.copyWith(
            status: FlightVideoStatus.exporting,
            exportProgress: fraction,
          ),
        );
      },
    );
    if (isClosed || cancel.isCancelled) return;

    if (path == null) {
      _analytics.log(
        FlightVideoGeneratedEvent(
          success: false,
          error: 'export',
          videoSeconds: session.spec.duration.inSeconds,
          tileCount: session.tileCount,
        ),
      );
      emit(
        state.copyWith(
          status: FlightVideoStatus.error,
          errorKind: FlightVideoErrorKind.encoder,
        ),
      );
      return;
    }

    final saved = await _gallerySaver.saveVideo(path);
    if (isClosed) return;

    _analytics.log(
      FlightVideoGeneratedEvent(
        success: true,
        error: '',
        videoSeconds: session.spec.duration.inSeconds,
        tileCount: session.tileCount,
        exportMs: stopwatch.elapsedMilliseconds,
      ),
    );
    unawaited(
      _ratePromptPolicyService.registerTrigger(
        RatePromptTrigger.shareCardShared,
      ),
    );
    emit(
      state.copyWith(
        status: FlightVideoStatus.exported,
        videoPath: path,
        savedToGallery: saved,
      ),
    );
  }

  /// Share the exported video via the native share sheet.
  Future<void> shareVideo({required Rect sharePositionOrigin}) async {
    final path = state.videoPath;
    final flight = state.flight;
    if (path == null || flight == null || state.isSharing) return;

    _analytics.log(const FlightVideoSharedEvent());
    emit(state.copyWith(status: FlightVideoStatus.sharing));
    try {
      final route = flight.route;
      await Share.shareXFiles(
        [XFile(path, mimeType: 'video/mp4')],
        text: t.flightVideo.shareText(
          fromCity: RouteUtils.cityLabel(route.departure.city),
          fromCode: route.departure.displayCode,
          toCity: RouteUtils.cityLabel(route.arrival.city),
          toCode: route.arrival.displayCode,
        ),
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      _logger.error('Failed to share flight video: $e');
    } finally {
      if (!isClosed) {
        emit(state.copyWith(status: FlightVideoStatus.exported));
      }
    }
  }

  Future<void> retry() async {
    _session?.dispose();
    _session = null;
    await _prepare();
  }

  Future<FlightVideoTexts> _buildTexts(Flight flight) async {
    DistanceUnit unit;
    try {
      unit = await _unitsRepository.getDistanceUnit();
    } catch (_) {
      unit = DistanceUnit.km;
    }
    return FlightVideoTexts(
      distance: shareCardFormatDistance(
        flight.route.metrics.effectiveDistanceKm,
        unit,
      ),
      duration: shareCardFormatDuration(
        t,
        flight.route.effectiveDurationMinutes,
      ),
      brand: t.shareImage.brand,
      madeWith: t.flightVideo.madeWith,
      mysteryTitle: t.flightVideo.mysteryTitle,
      distanceUnitLabel: UnitFormatUtils.formatDistanceUnit(unit),
      distanceUnitFactor: unit == DistanceUnit.mile ? 0.621371 : 1.0,
      languageCode: LocaleSettings.currentLocale.languageCode,
    );
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel();
    _session?.dispose();
    _session = null;
    return super.close();
  }
}
