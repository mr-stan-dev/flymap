import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/bottom_sheet/flight_bottom_sheet.dart';
import 'package:flymap/ui/screens/flight/widgets/flight_app_bar.dart';
import 'package:flymap/ui/screens/flight/widgets/flight_map_view.dart';
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
  double _hideProgress = 0.0; // 0..1

  @override
  void dispose() {
    _bottomSheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: FlightAppBar(
                    route: state.flight.route,
                    hideProgress: _hideProgress,
                  ),
                ),

              // Draggable bottom sheet
              _buildBottomSheet(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return SafeArea(
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (n) {
          final min = n.minExtent;
          final max = n.maxExtent;
          final extent = n.extent;
          // Hide only when snapped to top (near max)
          const epsilon = 0.22; // tolerance for snap vicinity
          final hide = extent >= (max - epsilon);
          if (hide != (_hideProgress == 1.0)) {
            setState(() => _hideProgress = hide ? 1.0 : 0.0);
          }
          return false;
        },
        child: DraggableScrollableSheet(
          controller: _bottomSheetController,
          initialChildSize: 0.5,
          minChildSize: 0.1,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.1, 0.5, 0.95],
          builder: (context, scrollController) {
            return FlightBottomSheet(scrollController: scrollController);
          },
        ),
      ),
    );
  }
}
