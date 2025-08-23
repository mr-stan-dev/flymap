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
            _buildDragHandle(theme),
            Expanded(
              child: CustomScrollView(
                controller: widget.scrollController,
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: PinnedTabBarHeader(
                      backgroundColor: theme.colorScheme.surface,
                      tabBar: TabBar(
                        labelColor: onSurface,
                        unselectedLabelColor: onSurface.withOpacity(0.5),
                        indicatorColor: theme.colorScheme.primary,
                        onTap: (idx) => setState(() => _tabIndex = idx),
                        tabs: const [
                          Tab(text: 'Flight info'),
                          Tab(text: 'GPS data'),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _tabIndex == 0
                          ? FlightInfoWidget(
                              route: widget.state.flight.route,
                              info: widget.state.flight.info,
                            )
                          : TabGpsData(state: widget.state),
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

  Widget _buildDragHandle(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: theme.dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
