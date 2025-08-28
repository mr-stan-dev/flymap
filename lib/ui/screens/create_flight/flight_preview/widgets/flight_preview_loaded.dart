import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/info/flight_info_widget.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/map/flight_map_preview_widget.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_cubit.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_preview_app_bar.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';

class FlightPreviewLoadedWidget extends StatefulWidget {
  final FlightMapPreviewLoaded state;

  const FlightPreviewLoadedWidget({super.key, required this.state});

  @override
  State<FlightPreviewLoadedWidget> createState() => _FlightPreviewLoadedWidgetState();
}

class _FlightPreviewLoadedWidgetState extends State<FlightPreviewLoadedWidget> {
  double _hideProgress = 0.0; // 0..1

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // Fullscreen map preview
              Positioned.fill(
                child: FlightMapPreviewWidget(
                  flightRoute: widget.state.flightRoute,
                  flightInfo: widget.state.flightInfo,
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: FlightPreviewAppBar(
                  route: widget.state.flightRoute,
                  hideProgress: _hideProgress,
                ),
              ),

              // Draggable bottom sheet with flight info
              NotificationListener<DraggableScrollableNotification>(
                onNotification: (n) {
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
                  initialChildSize: 0.5,
                  minChildSize: 0.1,
                  maxChildSize: 0.95,
                  snap: true,
                  snapSizes: const [0.1, 0.5, 0.95],
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              child: FlightInfoWidget(
                                route: widget.state.flightRoute,
                                info: widget.state.flightInfo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: widget.state.isTooLongFlight
                  ? null
                  : () {
                context.read<FlightPreviewCubit>().startDownload();
              },
              child: Text(
                widget.state.isTooLongFlight ? 'Too long flight (> 5000km)' : 'Download',
                style: context.textTheme.button18Bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

}
