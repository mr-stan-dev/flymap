import 'package:flutter/material.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';
import 'package:go_router/go_router.dart';

class HomeFlightsList extends StatelessWidget {
  const HomeFlightsList(this.flights, {super.key});

  final List<Flight> flights;

  @override
  Widget build(BuildContext context) {
    return _buildRecentActivity(context);
  }

  Widget _buildRecentActivity(BuildContext context) {
    if (flights.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flight, color: Colors.grey, size: 32),
              const SizedBox(height: 8),
              Text('No flights yet', style: TextStyle(color: Colors.grey)),
              Text(
                'Start by adding a new flight',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: flights.length,
      itemBuilder: (context, index) {
        final flight = flights[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index < flights.length - 1 ? 12 : 0),
          child: _buildFlightCard(
            context,
            flight: flight,
            title: flight.routeName,
            subtitle:
                '${flight.departure.cityWithCountryCode} - ${flight.arrival.cityWithCountryCode}',
          ),
        );
      },
    );
  }

  Widget _buildFlightCard(
    BuildContext context, {
    required Flight flight,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        context.push(AppRouter.flightRoute, extra: {'flight': flight});
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Flight icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.flight,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Flight details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.body18Regular.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: context.textTheme.caption14Regular),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
