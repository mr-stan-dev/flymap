import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_params.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_cubit.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_download_completion.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_downloading.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_preview_map.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_preview_loading.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_preview_error.dart';
import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';
import 'package:get_it/get_it.dart';

class FlightPreviewScreen extends StatelessWidget {
  final FlightPreviewAirports airports;

  const FlightPreviewScreen({super.key, required this.airports});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FlightPreviewCubit(
        params: airports,
        routeProvider: GetIt.I.get(),
        downloadMapUseCase: GetIt.I.get(),
        getFlightInfoUseCase: GetIt.I.get(),
        connectivity: GetIt.I.get(),
      ),
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: BlocConsumer<FlightPreviewCubit, FlightPreviewState>(
            listener: (context, state) {
              // Check if database save is complete
              if (state is MapDownloadingState && state.done == true) {
                // Trigger home refresh and navigate to home
                homeRefreshNotifier.value = true;
                AppRouter.goHome(context);
              }
            },
            builder: (context, state) {
              switch (state) {
                case FlightMapPreviewLoading():
                  return FlightPreviewLoadingWidget(airports: airports);
                case FlightMapPreviewMapState():
                  return FlightPreviewMapWidget(state: state);
                case MapDownloadingState():
                  return state.isDownloaded
                      ? FlightDownloadCompletion()
                      : FlightDownloading(
                          airports: airports,
                          downloadingState: state,
                        );
                case FlightMapPreviewError():
                  return FlightPreviewErrorWidget(
                    message: state.message,
                    onRetry: () => context.read<FlightPreviewCubit>().retry(),
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}
