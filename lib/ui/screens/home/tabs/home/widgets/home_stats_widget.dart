import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_state.dart';

class HomeStatsWidget extends StatelessWidget {
  const HomeStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeTabCubit, HomeTabState>(
      builder: (context, state) {
        if (state is HomeTabLoading) {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.flight,
                  title: 'Flights',
                  value: '...',
                  subtitle: 'Loading',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.map,
                  title: 'Maps',
                  value: '...',
                  subtitle: 'Loading',
                ),
              ),
            ],
          );
        }

        final statistics = state is HomeTabSuccess
            ? state.statistics
            : state is HomeTabError
            ? state.statistics ?? FlightStatistics.zero()
            : FlightStatistics.zero();

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.flight,
                title: 'Flights',
                value: statistics.totalFlights.toString(),
                subtitle: 'Total flights',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.map,
                title: 'Maps',
                value: statistics.totalDownloadedMaps.toString(),
                subtitle: '${statistics.formattedTotalMapSize} downloaded',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
            maxLines: 1,
          ),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.7)),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
