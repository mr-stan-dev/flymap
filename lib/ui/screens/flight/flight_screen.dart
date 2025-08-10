import 'package:flymap/entity/flight.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/bottom_sheet/flight_bottom_sheet.dart';
import 'package:flymap/ui/screens/flight/widgets/flight_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';

class FlightScreen extends StatelessWidget {
  final Flight flight;

  const FlightScreen({super.key, required this.flight});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FlightScreenCubit(flight: flight),
      child: const _FlightScreenView(),
    );
  }
}

class _FlightScreenView extends StatefulWidget {
  const _FlightScreenView();

  @override
  State<_FlightScreenView> createState() => _FlightScreenViewState();
}

class _FlightScreenViewState extends State<_FlightScreenView> {
  final DraggableScrollableController _bottomSheetController =
      DraggableScrollableController();

  @override
  void dispose() {
    _bottomSheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      body: BlocConsumer<FlightScreenCubit, FlightScreenState>(
        listener: (context, state) {
          if (state is FlightScreenError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          if (state is FlightScreenDeleted) {
            homeRefreshNotifier.value = true;
            AppRouter.goHome(context);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Map view taking full screen
              FlightMapView(bottomSheetController: _bottomSheetController),

              if (state is FlightScreenLoaded)
                _buildTopAppBar(context, state, onSurface),

              // Draggable bottom sheet
              _buildBottomSheet(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopAppBar(
    BuildContext context,
    FlightScreenLoaded state,
    Color onSurface,
  ) {
    // Always use light content over dimming overlay
    const Color overlayTextColor = Colors.white;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${state.flight.departure.code}-${state.flight.arrival.code}',
                        style: const TextStyle(
                          color: overlayTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        state.flight.route,
                        style: TextStyle(
                          color: overlayTextColor.withOpacity(0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) async {
                      switch (value) {
                        case 'delete_flight':
                          await context
                              .read<FlightScreenCubit>()
                              .deleteFlight();
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete_flight',
                        child: Text('Delete flight'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _bottomSheetController,
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return FlightBottomSheet(scrollController: scrollController);
      },
    );
  }
}
