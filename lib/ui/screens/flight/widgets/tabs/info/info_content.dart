import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/articles/articles_section.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/airports_section.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/overview_section.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/route_facts_wrap.dart';

class FlightInfoContent extends StatelessWidget {
  const FlightInfoContent({
    required this.topPadding,
    required this.route,
    required this.info,
    super.key,
  });

  final double topPadding;
  final FlightRoute route;
  final FlightInfo info;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          DsSpacing.md,
          topPadding,
          DsSpacing.md,
          DsSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RouteFactsWrap(route: route),
            const SizedBox(height: DsSpacing.sm),
            AirportsSection(route: route),
            const SizedBox(height: DsSpacing.sm),
            OverviewSection(overview: info.overview),
            const SizedBox(height: DsSpacing.sm),
            ArticlesSection(articles: info.articles),
          ],
        ),
      ),
    );
  }
}
