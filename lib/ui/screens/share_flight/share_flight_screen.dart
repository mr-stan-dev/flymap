import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/shared/tab_state_placeholder.dart';
import 'package:flymap/ui/screens/share_flight/viewmodel/share_flight_cubit.dart';
import 'package:flymap/ui/screens/share_flight/viewmodel/share_flight_state.dart';
import 'package:flymap/ui/screens/share_flight/widgets/share_distance_chip.dart';
import 'package:flymap/ui/screens/share_flight/widgets/share_flight_map_preview.dart';
import 'package:flymap/ui/screens/share_flight/widgets/share_flymap_watermark.dart';
import 'package:flymap/ui/screens/share_flight/widgets/share_route_cities_chip.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ShareFlightScreen extends StatelessWidget {
  const ShareFlightScreen({required this.flight, super.key});

  final Flight flight;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShareFlightCubit(flight: flight),
      child: const _ShareFlightView(),
    );
  }
}

class _ShareFlightView extends StatefulWidget {
  const _ShareFlightView();

  @override
  State<_ShareFlightView> createState() => _ShareFlightViewState();
}

class _ShareFlightViewState extends State<_ShareFlightView> {
  final GlobalKey _mapCaptureKey = GlobalKey();
  static const double _overlayPadding = 12;
  Offset _distanceChipOffset = const Offset(16, 16);
  Offset? _routeCitiesChipOffset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share flight')),
      body: BlocConsumer<ShareFlightCubit, ShareFlightState>(
        listenWhen: (previous, current) {
          return previous.errorMessage != current.errorMessage &&
              current.errorMessage != null;
        },
        listener: (context, state) {
          final message = state.errorMessage;
          if (message == null) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (context, state) {
          final style = state.styleString;
          return Column(
            children: [
              Expanded(
                child: style == null
                    ? const FlightTabStatePlaceholder(
                        icon: Icons.map_outlined,
                        text: 'Preparing share preview map...',
                      )
                    : RepaintBoundary(
                        key: _mapCaptureKey,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final mapSize = constraints.biggest;
                            final distanceKm = state.flight.route.distanceInKm;
                            final maxLeft =
                                (mapSize.width -
                                        shareDistanceChipWidth -
                                        _overlayPadding)
                                    .clamp(_overlayPadding, double.infinity);
                            final maxTop =
                                (mapSize.height -
                                        shareDistanceChipHeight -
                                        _overlayPadding)
                                    .clamp(_overlayPadding, double.infinity);
                            final chipLeft = _distanceChipOffset.dx.clamp(
                              _overlayPadding,
                              maxLeft,
                            );
                            final chipTop = _distanceChipOffset.dy.clamp(
                              _overlayPadding,
                              maxTop,
                            );
                            final routeMaxLeft =
                                (mapSize.width -
                                        shareRouteCitiesChipWidth -
                                        _overlayPadding)
                                    .clamp(_overlayPadding, double.infinity);
                            final routeMaxTop =
                                (mapSize.height -
                                        shareRouteCitiesChipHeight -
                                        _overlayPadding)
                                    .clamp(_overlayPadding, double.infinity);
                            final routeBaseOffset =
                                _routeCitiesChipOffset ??
                                Offset(_overlayPadding, routeMaxTop);
                            final routeChipLeft = routeBaseOffset.dx.clamp(
                              _overlayPadding,
                              routeMaxLeft,
                            );
                            final routeChipTop = routeBaseOffset.dy.clamp(
                              _overlayPadding,
                              routeMaxTop,
                            );

                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: ShareFlightMapPreview(
                                    route: state.flight.route,
                                    styleString: style,
                                  ),
                                ),
                                Positioned(
                                  left: chipLeft,
                                  top: chipTop,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onPanUpdate: (details) {
                                      _updateDistanceChipOffset(
                                        delta: details.delta,
                                        mapSize: mapSize,
                                      );
                                    },
                                    child: ShareDistanceChip(
                                      distanceKm: distanceKm,
                                    ),
                                  ),
                                ),
                                const Positioned(
                                  right: _overlayPadding,
                                  top: _overlayPadding,
                                  child: ShareFlymapWatermark(),
                                ),
                                Positioned(
                                  left: routeChipLeft,
                                  top: routeChipTop,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onPanUpdate: (details) {
                                      _updateRouteCitiesChipOffset(
                                        delta: details.delta,
                                        mapSize: mapSize,
                                        currentLeft: routeChipLeft,
                                        currentTop: routeChipTop,
                                      );
                                    },
                                    child: ShareRouteCitiesChip(
                                      fromCity:
                                          state.flight.route.departure.city,
                                      toCity: state.flight.route.arrival.city,
                                      fromCode: state
                                          .flight
                                          .route
                                          .departure
                                          .displayCode,
                                      toCode: state
                                          .flight
                                          .route
                                          .arrival
                                          .displayCode,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: state.isLoading || state.isSharing
                          ? null
                          : () => _shareRoute(context),
                      icon: state.isSharing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.share),
                      label: Text(
                        state.isSharing ? 'Preparing screenshot...' : 'Share',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _shareRoute(BuildContext context) async {
    final cubit = context.read<ShareFlightCubit>();
    final pixelRatio = MediaQuery.of(context).devicePixelRatio.clamp(1.0, 3.0);
    final routeCode = cubit.state.flight.route.routeCode;

    await cubit.shareRouteScreenshot(
      captureScreenshot: () =>
          _captureMapScreenshot(pixelRatio: pixelRatio, routeCode: routeCode),
    );
  }

  void _updateDistanceChipOffset({
    required Offset delta,
    required Size mapSize,
  }) {
    final maxLeft = (mapSize.width - shareDistanceChipWidth - _overlayPadding)
        .clamp(_overlayPadding, double.infinity);
    final maxTop = (mapSize.height - shareDistanceChipHeight - _overlayPadding)
        .clamp(_overlayPadding, double.infinity);

    final nextLeft = (_distanceChipOffset.dx + delta.dx).clamp(
      _overlayPadding,
      maxLeft,
    );
    final nextTop = (_distanceChipOffset.dy + delta.dy).clamp(
      _overlayPadding,
      maxTop,
    );

    setState(() {
      _distanceChipOffset = Offset(nextLeft, nextTop);
    });
  }

  void _updateRouteCitiesChipOffset({
    required Offset delta,
    required Size mapSize,
    required double currentLeft,
    required double currentTop,
  }) {
    final maxLeft =
        (mapSize.width - shareRouteCitiesChipWidth - _overlayPadding).clamp(
          _overlayPadding,
          double.infinity,
        );
    final maxTop =
        (mapSize.height - shareRouteCitiesChipHeight - _overlayPadding).clamp(
          _overlayPadding,
          double.infinity,
        );

    final nextLeft = (currentLeft + delta.dx).clamp(_overlayPadding, maxLeft);
    final nextTop = (currentTop + delta.dy).clamp(_overlayPadding, maxTop);

    setState(() {
      _routeCitiesChipOffset = Offset(nextLeft, nextTop);
    });
  }

  Future<String?> _captureMapScreenshot({
    required double pixelRatio,
    required String routeCode,
  }) async {
    final boundary =
        _mapCaptureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;

    // Wait for current frame to settle before taking the snapshot.
    await Future<void>.delayed(const Duration(milliseconds: 16));

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final tempDir = await getTemporaryDirectory();
    final filePath = p.join(
      tempDir.path,
      'flight_route_${routeCode}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    final output = File(filePath);
    await output.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return output.path;
  }
}
