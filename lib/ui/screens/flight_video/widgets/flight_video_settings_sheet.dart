import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight_video_spec.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/video_avatar_repository.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight_video/viewmodel/flight_video_cubit.dart';
import 'package:flymap/ui/screens/flight_video/viewmodel/flight_video_state.dart';
import 'package:flymap/ui/screens/flight_video/widgets/video_avatar_setup_sheet.dart';
import 'package:get_it/get_it.dart';

/// The settings the user chose in the sheet, returned when they tap Apply.
class FlightVideoSettingsDraft {
  const FlightVideoSettingsDraft({
    required this.style,
    required this.mysteryDestination,
    required this.showPins,
    required this.showEndCard,
    required this.watermarkRemoved,
    required this.avatarEnabled,
  });

  final FlightVideoMapStyle style;
  final bool mysteryDestination;
  final bool showPins;
  final bool showEndCard;
  final bool watermarkRemoved;
  final bool avatarEnabled;
}

/// Video settings sheet: map style (all users) and the watermark toggle
/// (Pro; free users get the paywall). Lives in a bottom sheet so the
/// preview keeps the whole screen.
///
/// Returns the chosen [FlightVideoSettingsDraft] when the user taps Apply, or
/// null if they dismiss it. The caller applies the draft *after* the sheet has
/// closed, so the (possibly heavy) apply never blocks the close animation.
Future<FlightVideoSettingsDraft?> showFlightVideoSettingsSheet(
  BuildContext context,
  FlightVideoCubit cubit,
) {
  return showModalBottomSheet<FlightVideoSettingsDraft>(
    context: context,
    showDragHandle: true,
    // Size to content and scroll if it exceeds the screen, instead of the
    // default half-height sheet that clipped the lower toggles.
    isScrollControlled: true,
    builder: (sheetContext) => BlocProvider.value(
      value: cubit,
      child: const _FlightVideoSettingsSheet(),
    ),
  );
}

class _FlightVideoSettingsSheet extends StatefulWidget {
  const _FlightVideoSettingsSheet();

  @override
  State<_FlightVideoSettingsSheet> createState() =>
      _FlightVideoSettingsSheetState();
}

class _FlightVideoSettingsSheetState extends State<_FlightVideoSettingsSheet> {
  // A local draft: controls edit these instantly (no preview churn) and the
  // whole set is committed at once when the user taps Apply.
  late FlightVideoMapStyle _style;
  late bool _mysteryDestination;
  late bool _showPins;
  late bool _showEndCard;
  late bool _watermarkRemoved;
  late bool _avatarEnabled;
  VideoAvatarConfig? _avatarConfig;

  @override
  void initState() {
    super.initState();
    final state = context.read<FlightVideoCubit>().state;
    _style = state.style;
    _mysteryDestination = state.mysteryDestination;
    _showPins = state.showPins;
    _showEndCard = state.showEndCard;
    _watermarkRemoved = state.watermarkRemoved;
    _avatarEnabled = state.avatarEnabled;
    _loadAvatarConfig();
  }

  Future<void> _loadAvatarConfig() async {
    final config = await GetIt.I.get<VideoAvatarRepository>().load();
    if (!mounted) return;
    setState(() => _avatarConfig = config);
  }

  /// Turning the avatar on prompts the lightweight pick flow when no photo is
  /// stored yet; turning it off just hides it (the photo is kept for later).
  Future<void> _onAvatarToggle(bool value) async {
    if (!value) {
      setState(() => _avatarEnabled = false);
      return;
    }
    if (_avatarConfig?.hasImage ?? false) {
      setState(() => _avatarEnabled = true);
      return;
    }
    final configured = await showVideoAvatarSetupSheet(context);
    if (!mounted || !configured) return;
    await _loadAvatarConfig();
    if (!mounted) return;
    setState(() => _avatarEnabled = true);
  }

  /// Change the photo via the setup sheet (from the avatar thumbnail).
  Future<void> _editAvatar() async {
    final configured = await showVideoAvatarSetupSheet(context);
    if (!mounted || !configured) return;
    await _loadAvatarConfig();
    if (!mounted) return;
    setState(() => _avatarEnabled = true);
  }

  bool _isDirty(FlightVideoState state) =>
      _style != state.style ||
      _mysteryDestination != state.mysteryDestination ||
      _showPins != state.showPins ||
      _showEndCard != state.showEndCard ||
      _watermarkRemoved != state.watermarkRemoved ||
      _avatarEnabled != state.avatarEnabled;

  /// Close the sheet, returning the chosen draft. The screen applies it once
  /// the sheet has fully closed and shows the loading state there — so the
  /// (possibly ~20s) style download never blocks the close animation.
  void _apply() {
    Navigator.of(context).pop(
      FlightVideoSettingsDraft(
        style: _style,
        mysteryDestination: _mysteryDestination,
        showPins: _showPins,
        showEndCard: _showEndCard,
        watermarkRemoved: _watermarkRemoved,
        avatarEnabled: _avatarEnabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    return BlocBuilder<FlightVideoCubit, FlightVideoState>(
      builder: (context, state) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              DsSpacing.lg,
              0,
              DsSpacing.lg,
              DsSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.flightVideo.videoSettings,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DsSpacing.md),
                Text(
                  t.flightVideo.mapStyle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DsSpacing.sm),
                Row(
                  children: [
                    for (final style in FlightVideoMapStyle.values) ...[
                      _StyleTile(
                        style: style,
                        selected: _style == style,
                        enabled: true,
                        onTap: () => setState(() => _style = style),
                      ),
                      if (style != FlightVideoMapStyle.values.last)
                        const SizedBox(width: DsSpacing.md),
                    ],
                  ],
                ),
                const SizedBox(height: DsSpacing.md),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _mysteryDestination,
                  onChanged: (v) => setState(() => _mysteryDestination = v),
                  title: Text(t.flightVideo.mysteryDestination),
                  subtitle: Text(
                    t.flightVideo.mysteryDestinationHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _showPins,
                  onChanged: (v) => setState(() => _showPins = v),
                  title: Text(t.flightVideo.showPins),
                  subtitle: Text(
                    t.flightVideo.showPinsHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _showEndCard,
                  onChanged: (v) => setState(() => _showEndCard = v),
                  title: Text(t.flightVideo.showEndCard),
                  subtitle: Text(
                    t.flightVideo.showEndCardHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _avatarEnabled,
                  onChanged: _onAvatarToggle,
                  secondary: _AvatarToggleThumb(
                    config: _avatarConfig,
                    onTap: _editAvatar,
                  ),
                  title: Text(t.flightVideo.avatarTitle),
                  subtitle: Text(
                    t.flightVideo.avatarHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _watermarkRemoved,
                  onChanged: (v) => setState(() => _watermarkRemoved = v),
                  title: Row(
                    children: [
                      Text(t.flightVideo.removeWatermark),
                      if (!state.isPro) ...[
                        const SizedBox(width: DsSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DsPremiumColors.iconSurface(context),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t.common.pro,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: DsPremiumColors.accent(context),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: DsSpacing.lg),
                PrimaryButton(
                  label: t.flightVideo.applySettings,
                  onPressed: _isDirty(state) ? _apply : null,
                  leadingIcon: Icons.check_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Small circular avatar in the settings toggle's leading slot; tapping it
/// opens the setup sheet to change the photo/name.
class _AvatarToggleThumb extends StatelessWidget {
  const _AvatarToggleThumb({required this.config, required this.onTap});

  final VideoAvatarConfig? config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = config?.hasImage ?? false;
    const size = 40.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          image: hasImage
              ? DecorationImage(
                  image: FileImage(File(config!.imagePath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: hasImage
            ? null
            : Icon(
                Icons.person_outline,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.style,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final FlightVideoMapStyle style;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  String _label(BuildContext context) => switch (style) {
    FlightVideoMapStyle.outdoors => context.t.flightVideo.styleDefault,
    FlightVideoMapStyle.satellite => context.t.flightVideo.styleSatellite,
    FlightVideoMapStyle.shine => context.t.flightVideo.styleShine,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget thumbnail = Image.asset(
      style.thumbnailAsset,
      width: 64,
      height: 64,
      fit: BoxFit.cover,
    );

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: thumbnail,
              ),
            ),
            const SizedBox(height: DsSpacing.xs),
            Text(
              _label(context),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
