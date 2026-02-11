import 'package:flutter/material.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/info/flight_info_widget.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/bottom_sheet/tabs/tab_gps_data.dart';
import 'package:flymap/ui/screens/flight/widgets/bottom_sheet/tabs/tab_header.dart';

class BottomSheetLoaded extends StatefulWidget {
  const BottomSheetLoaded(this.scrollController, this.state, {super.key});

  final ScrollController scrollController;
  final FlightScreenLoaded state;

  @override
  State<BottomSheetLoaded> createState() => _BottomSheetLoadedState();
}

class _BottomSheetLoadedState extends State<BottomSheetLoaded> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return DefaultTabController(
      length: 2,
      initialIndex: _tabIndex,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: CustomScrollView(
                controller: widget.scrollController,
                slivers: [
                  SliverToBoxAdapter(child: _buildDragHandle(theme)),
                  SliverToBoxAdapter(
                    child: _buildGpsAccuracyRow(context, theme),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: PinnedTabBarHeader(
                      backgroundColor: theme.colorScheme.surface,
                      tabBar: TabBar(
                        labelColor: onSurface,
                        unselectedLabelColor: onSurface.withValues(alpha: 0.5),
                        indicatorColor: theme.colorScheme.primary,
                        onTap: (idx) => setState(() => _tabIndex = idx),
                        tabs: const [
                          Tab(text: 'Flight info'),
                          Tab(text: 'Compass'),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildTabContent(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tabIndex) {
      case 0:
        return FlightInfoWidget(
          route: widget.state.flight.route,
          info: widget.state.flight.info,
        );
      case 1:
        return TabGPSData(state: widget.state);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDragHandle(ThemeData theme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildGpsAccuracyRow(BuildContext context, ThemeData theme) {
    if (widget.state.gpsData == null) return const SizedBox.shrink();

    final accuracy = widget.state.gpsData?.accuracy;
    if (accuracy == null) return const SizedBox.shrink();

    Color color;
    String text;

    if (accuracy < 10) {
      color = Colors.green;
      text = 'Excellent';
    } else if (accuracy < 25) {
      color = Colors.orange;
      text = 'Good';
    } else {
      color = Colors.red;
      text = 'Poor';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gps_fixed, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            'GPS Accuracy: $text (±${accuracy.toStringAsFixed(0)}m)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
