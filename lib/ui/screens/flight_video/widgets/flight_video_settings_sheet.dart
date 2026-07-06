import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight_video_spec.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight_video/viewmodel/flight_video_cubit.dart';
import 'package:flymap/ui/screens/flight_video/viewmodel/flight_video_state.dart';

/// The settings the user chose in the sheet, returned when they tap Apply.
class FlightVideoSettingsDraft {
  const FlightVideoSettingsDraft({
    required this.style,
    required this.mysteryDestination,
    required this.showPins,
    required this.showEndCard,
    required this.watermarkRemoved,
  });

  final FlightVideoMapStyle style;
  final bool mysteryDestination;
  final bool showPins;
  final bool showEndCard;
  final bool watermarkRemoved;
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

  @override
  void initState() {
    super.initState();
    final state = context.read<FlightVideoCubit>().state;
    _style = state.style;
    _mysteryDestination = state.mysteryDestination;
    _showPins = state.showPins;
    _showEndCard = state.showEndCard;
    _watermarkRemoved = state.watermarkRemoved;
  }

  bool _isDirty(FlightVideoState state) =>
      _style != state.style ||
      _mysteryDestination != state.mysteryDestination ||
      _showPins != state.showPins ||
      _showEndCard != state.showEndCard ||
      _watermarkRemoved != state.watermarkRemoved;

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
                            color: DsBrandColors.proAmber.withValues(
                              alpha: 0.18,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t.common.pro,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: DsBrandColors.proAmber,
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
