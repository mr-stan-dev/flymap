import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_cubit.dart';
import 'package:flymap/ui/screens/share_flight/widgets/card/utils/share_image_card_formatters.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';

class ShareImageCardMetricsRow extends StatelessWidget {
  const ShareImageCardMetricsRow({required this.flight, super.key});

  final Flight flight;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final distanceUnitLabel = context.select(
      (SettingsCubit cubit) => cubit.state.distanceUnit,
    );
    final distanceUnit = distanceUnitLabel == 'mi'
        ? DistanceUnit.mile
        : DistanceUnit.km;
    final countryCount = shareCardCountryCount(flight);

    final metrics = [
      (
        Icons.route_rounded,
        shareCardFormatDistance(
          flight.route.displayDistanceKm.toDouble(),
          distanceUnit,
        ),
      ),
      (
        Icons.schedule_rounded,
        shareCardFormatDuration(t, flight.route.durations.displayBlockMinutes),
      ),
      (
        Icons.public_rounded,
        countryCount == 1
            ? t.shareImage.countrySingle
            : t.shareImage.countries(count: countryCount),
      ),
    ];

    final metricStyle = context.textTheme.body16Semibold.copyWith(
      color: Colors.white,
      fontSize: 14,
      height: 1.05,
      letterSpacing: 0,
    );

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.45),
            width: 0.7,
          ),
        ),
      ),
      child: Row(
        children: metrics
            .map((metric) {
              final index = metrics.indexOf(metric);
              return Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(metric.$1, size: 14, color: const Color(0xFF47EFFF)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        metric.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: metricStyle,
                      ),
                    ),
                    if (index < metrics.length - 1)
                      Container(
                        margin: const EdgeInsets.only(left: 14),
                        width: 1,
                        height: 18,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}
