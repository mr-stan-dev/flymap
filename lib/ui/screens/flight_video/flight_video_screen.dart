import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight_video/viewmodel/flight_video_cubit.dart';
import 'package:flymap/ui/screens/flight_video/viewmodel/flight_video_state.dart';
import 'package:flymap/ui/screens/flight_video/widgets/flight_video_preview.dart';
import 'package:flymap/ui/screens/flight_video/widgets/flight_video_progress_overlay.dart';
import 'package:flymap/ui/screens/flight_video/widgets/flight_video_settings_sheet.dart';

class FlightVideoScreen extends StatelessWidget {
  const FlightVideoScreen({required this.flightId, super.key});

  final String flightId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FlightVideoCubit(flightId: flightId),
      child: const _FlightVideoView(),
    );
  }
}

class _FlightVideoView extends StatefulWidget {
  const _FlightVideoView();

  @override
  State<_FlightVideoView> createState() => _FlightVideoViewState();
}

class _FlightVideoViewState extends State<_FlightVideoView> {
  final GlobalKey _actionButtonKey = GlobalKey();

  /// The preview paints at 60fps on the UI thread; pause it while the settings
  /// sheet is open so toggling and applying stays smooth (no paint contention).
  bool _settingsOpen = false;

  Future<void> _openSettings(FlightVideoCubit cubit) async {
    setState(() => _settingsOpen = true);
    FlightVideoSettingsDraft? draft;
    try {
      draft = await showFlightVideoSettingsSheet(context, cubit);
    } finally {
      if (mounted) setState(() => _settingsOpen = false);
    }
    // Apply only after the sheet has fully closed, so the work (a style change
    // downloads tiles) never blocks the dismissal and the loading state shows
    // on the screen itself.
    if (!mounted || draft == null) return;
    await cubit.applySettings(
      style: draft.style,
      mysteryDestination: draft.mysteryDestination,
      showPins: draft.showPins,
      showEndCard: draft.showEndCard,
      watermarkRemoved: draft.watermarkRemoved,
      avatarEnabled: draft.avatarEnabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.flightVideo.title),
        actions: [
          BlocBuilder<FlightVideoCubit, FlightVideoState>(
            builder: (context, state) {
              if (!state.hasPreview) return const SizedBox.shrink();
              final cubit = context.read<FlightVideoCubit>();
              return IconButton(
                tooltip: t.flightVideo.videoSettings,
                icon: const Icon(Icons.tune),
                onPressed: () => _openSettings(cubit),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<FlightVideoCubit, FlightVideoState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status &&
            curr.status == FlightVideoStatus.exported,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.savedToGallery
                    ? t.flightVideo.savedToGallery
                    : t.flightVideo.saveSkipped,
              ),
            ),
          );
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(child: _buildContent(context, state)),
              if (!state.isPreparing && !state.isApplyingSettings)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(DsSpacing.md),
                    child: _buildBottomAction(context, state),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, FlightVideoState state) {
    final t = context.t;
    if (state.isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DsSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: DsSpacing.md),
              Text(
                state.errorKind == FlightVideoErrorKind.network
                    ? t.flightVideo.errorNetwork
                    : t.flightVideo.errorGeneric,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Preparing the first preview, or applying a style change (which
    // re-downloads tiles): both read best as a clear full-screen loading state
    // rather than a frozen preview or a sheet held open.
    if (state.isPreparing || state.isApplyingSettings) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DsSpacing.xxl),
          child: FlightVideoProgressOverlay(
            label: state.isApplyingSettings
                ? t.flightVideo.applying
                : t.flightVideo.preparing,
            progress: state.isApplyingSettings
                ? state.applyProgress
                : state.prepareProgress,
          ),
        ),
      );
    }

    final session = context.read<FlightVideoCubit>().session;
    if (session == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(DsSpacing.md),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: FlightVideoPreview(
                  session: session,
                  playing: !state.isExporting && !_settingsOpen,
                ),
              ),
            ),
          ),
          if (state.isExporting) ...[
            const SizedBox(height: DsSpacing.lg),
            FlightVideoProgressOverlay(
              label: t.flightVideo.rendering,
              progress: state.exportProgress,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, FlightVideoState state) {
    final t = context.t;
    final cubit = context.read<FlightVideoCubit>();

    if (state.isError) {
      return PrimaryButton(
        label: t.flightVideo.retry,
        onPressed: cubit.retry,
        leadingIcon: Icons.refresh,
      );
    }

    if (state.isExported) {
      return PrimaryButton(
        key: _actionButtonKey,
        label: state.isSharing ? t.flightVideo.sharing : t.flightVideo.share,
        onPressed: state.isSharing
            ? null
            : () => cubit.shareVideo(sharePositionOrigin: _shareOrigin()),
        leadingIcon: state.isSharing ? null : Icons.share,
        isLoading: state.isSharing,
      );
    }

    return PrimaryButton(
      key: _actionButtonKey,
      label: t.flightVideo.export,
      onPressed: state.status == FlightVideoStatus.previewReady
          ? cubit.exportAndSave
          : null,
      leadingIcon: state.isExporting ? null : Icons.download,
      isLoading: state.isExporting,
    );
  }

  Rect _shareOrigin() {
    final box =
        _actionButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    return const Rect.fromLTWH(1, 1, 1, 1);
  }
}
