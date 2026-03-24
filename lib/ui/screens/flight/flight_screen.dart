import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/flight_app_bar.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/dashboard_tab_view.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/info_tab_view.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_tab.dart';
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
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.speed_outlined),
            activeIcon: Icon(Icons.speed),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            activeIcon: Icon(Icons.info),
            label: 'Info',
          ),
        ],
      ),
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
          final flight = _extractFlight(state);

          return Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    const FlightMapTabView(),
                    FlightDashboardTabView(
                      state: state,
                      topPadding: _tabTopPadding(context),
                    ),
                    FlightInfoTabView(
                      state: state,
                      topPadding: _tabTopPadding(context),
                    ),
                  ],
                ),
              ),
              if (flight != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: FlightAppBar(flight: flight, hideProgress: 0.0),
                ),
            ],
          );
        },
      ),
    );
  }

  Flight? _extractFlight(FlightScreenState state) {
    if (state is FlightScreenLoaded) {
      return state.flight;
    }
    if (state is FlightScreenError) {
      return state.flight;
    }
    return null;
  }

  double _tabTopPadding(BuildContext context) {
    return FlightAppBar.totalOverlayHeight(context) + 8;
  }
}
