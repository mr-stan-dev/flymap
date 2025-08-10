import 'package:flymap/entity/flight.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        final cubit = context.read<HomeTabCubit>();
        return Padding(
          padding: EdgeInsets.only(bottom: index < flights.length - 1 ? 12 : 0),
          child: _buildActivityCard(
            context,
            flight: flight,
            title: flight.route,
            subtitle: '${flight.departure.code}-${flight.arrival.code}',
            date: cubit.formatFlightDate(flight),
          ),
        );
      },
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required Flight flight,
    required String title,
    required String subtitle,
    required String date,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return GestureDetector(
      onTap: () {
        context.push(AppRouter.flightRoute, extra: {'flight': flight});
      },
      child: Card(
        child: Container(
          width: double.infinity,
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
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurface.withOpacity(0.6),
                      ),
                    ),
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
