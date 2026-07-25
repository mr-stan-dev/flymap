import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/home_area_summary.dart';
import 'package:flymap/domain/entity/poi_wiki_preview.dart';
import 'package:flymap/domain/entity/user_interests_poi_types.dart';
import 'package:flymap/domain/entity/user_profile.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/poi_preview_bottom_sheet.dart';
import 'package:flymap/ui/screens/onboarding/model/onboarding_profile_ui.dart';
import 'package:flymap/ui/screens/onboarding/viewmodel/onboarding_profile_form_state.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:flymap/ui/screens/shared/poi_type_marker_asset.dart';

/// Most-interesting-first order for the payoff rows: natural wonders sell the
/// window seat; cities and regions are deliberately left out.
const List<UsersInterests> kPayoffDisplayOrder = [
  UsersInterests.volcanoes,
  UsersInterests.mountains,
  UsersInterests.islands,
  UsersInterests.rivers,
  UsersInterests.nationalParks,
];

/// Payoff step: shows what Flymap has already mapped around the user's home
/// airport — the places they fly over (and miss) on every departure and
/// arrival. Natural wonders lead; cities and regions are not listed.
///
/// The summary is prefetched when the airport is selected. If it is still
/// loading when this step appears, a short scanning state is shown; after
/// [gracePeriod] (or on failure / skipped airport) the step falls back to
/// generic copy so onboarding is never blocked on the network.
class OnboardingAreaPayoffStep extends StatefulWidget {
  const OnboardingAreaPayoffStep({
    required this.airport,
    required this.status,
    required this.summary,
    this.gracePeriod = const Duration(seconds: 3),
    super.key,
  });

  final Airport? airport;
  final HomeAreaSummaryStatus status;
  final HomeAreaSummary? summary;
  final Duration gracePeriod;

  @override
  State<OnboardingAreaPayoffStep> createState() =>
      _OnboardingAreaPayoffStepState();
}

class _OnboardingAreaPayoffStepState extends State<OnboardingAreaPayoffStep> {
  Timer? _graceTimer;
  bool _graceExpired = false;

  @override
  void initState() {
    super.initState();
    _graceTimer = Timer(widget.gracePeriod, () {
      if (!mounted) return;
      setState(() => _graceExpired = true);
    });
  }

  @override
  void dispose() {
    _graceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.t.onboarding.payoff;
    final airport = widget.airport;
    final summary = widget.summary;
    final airportLabel = airport == null
        ? ''
        : (airport.city.trim().isNotEmpty ? airport.city : airport.displayCode);

    final isReady =
        widget.status == HomeAreaSummaryStatus.ready &&
        summary != null &&
        !summary.isEmpty &&
        airport != null;
    final isScanning =
        !isReady &&
        widget.status == HomeAreaSummaryStatus.loading &&
        !_graceExpired &&
        airport != null;

    final Widget child;
    if (isReady) {
      child = _PayoffContent(
        key: const ValueKey('payoff_ready'),
        airportLabel: airportLabel,
        summary: summary,
      );
    } else if (isScanning) {
      child = _ScanningContent(
        key: const ValueKey('payoff_scanning'),
        message: strings.scanning(airport: airportLabel),
      );
    } else {
      child = const _FallbackContent(key: ValueKey('payoff_fallback'));
    }

    return AnimatedSwitcher(
      duration: DsMotion.normal,
      switchInCurve: DsMotion.enter,
      switchOutCurve: DsMotion.exit,
      child: child,
    );
  }
}

class _PayoffContent extends StatelessWidget {
  const _PayoffContent({
    required this.airportLabel,
    required this.summary,
    super.key,
  });

  final String airportLabel;
  final HomeAreaSummary summary;

  List<(UsersInterests, int)> _rows() {
    int countFor(UsersInterests interest) {
      var total = 0;
      for (final type in interest.poiTypes) {
        total += summary.countsByType[type] ?? 0;
      }
      return total;
    }

    return [
      for (final interest in kPayoffDisplayOrder)
        if (countFor(interest) > 0) (interest, countFor(interest)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.t.onboarding.payoff;
    final rows = _rows();
    final moreCount = summary.totalPlaces - summary.topPlaces.length;

    return OnboardingStepScaffold(
      title: strings.title(airport: airportLabel),
      subtitle: strings.subtitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.topPlaces.isNotEmpty) ...[
            _TopPlacesCard(places: summary.topPlaces),
            const SizedBox(height: DsSpacing.lg),
            if (moreCount > 0 && rows.isNotEmpty) ...[
              Text(
                strings.moreNearby(count: moreCount),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: DsSpacing.sm),
            ],
          ],
          for (final (interest, count) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: DsSpacing.sm),
              child: _CategoryRow(interest: interest, count: count),
            ),
        ],
      ),
    );
  }
}

/// The proof: real, recognizable places by name, front and center.
class _TopPlacesCard extends StatelessWidget {
  const _TopPlacesCard({required this.places});

  final List<HomeAreaPlace> places;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DsRadii.lg),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Wrap(
        spacing: DsSpacing.xs,
        runSpacing: DsSpacing.xs,
        children: [for (final place in places) _PlaceChip(place: place)],
      ),
    );
  }
}

class _PlaceChip extends StatelessWidget {
  const _PlaceChip({required this.place});

  final HomeAreaPlace place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // The preview sheet renders only what we hand it — it does not fetch.
        // Chips without a payload description stay static rather than
        // opening an empty sheet.
        onTap: place.description.isEmpty ? null : () => _openPreview(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                PoiTypeMarkerAsset.iconPathFor(place.type),
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.place_rounded, size: 16, color: scheme.primary),
              ),
              const SizedBox(width: 6),
              Text(
                place.name,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPreview(BuildContext context) {
    return showPoiPreviewDialog(
      context: context,
      name: place.name,
      typeRaw: place.type.rawValue,
      qid: place.qid,
      // No wikipedia URL in the area payload, so no open action; the sheet
      // shows the offline description that came with the places response.
      actionMode: PoiPreviewActionMode.none,
      preloadedPreview: PoiWikiPreview(
        qid: place.qid,
        title: place.name,
        summary: place.description,
        htmlContent: '',
        sourceUrl: '',
        languageCode: '',
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.interest, required this.count});

  final UsersInterests interest;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(DsRadii.sm),
          ),
          child: Image.asset(
            interest.markerAssetPath,
            width: 22,
            height: 22,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                Icon(interest.icon, size: 20, color: scheme.primary),
          ),
        ),
        const SizedBox(width: DsSpacing.sm),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: count),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => SizedBox(
            width: 44,
            child: Text(
              '$value',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            interest.label(context),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanningContent extends StatelessWidget {
  const _ScanningContent({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DsSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: DsSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Copy-only degraded state for the rare case the area summary could not be
/// fetched (offline / backend failure). The home airport step is mandatory,
/// so this never shows for a missing airport in the normal flow.
class _FallbackContent extends StatelessWidget {
  const _FallbackContent({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.t.onboarding.payoff;
    return OnboardingStepScaffold(
      title: strings.fallbackTitle,
      subtitle: strings.fallbackSubtitle,
      body: const SizedBox.shrink(),
    );
  }
}
