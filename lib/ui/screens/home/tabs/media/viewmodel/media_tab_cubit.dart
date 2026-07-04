import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:flymap/repository/sky_camera_media_repository.dart';
import 'package:flymap/ui/screens/home/tabs/media/viewmodel/media_tab_state.dart';

class MediaTabCubit extends Cubit<MediaTabState> {
  MediaTabCubit({
    required SkyCameraMediaRepository repository,
    required FlightRepository flightRepository,
    required MetricUnitsRepository metricUnitsRepository,
  }) : _repository = repository,
       _flightRepository = flightRepository,
       _metricUnitsRepository = metricUnitsRepository,
       super(const MediaTabLoading()) {
    _changesSubscription = _repository.watch().listen((_) => unawaited(load()));
  }

  final SkyCameraMediaRepository _repository;
  final FlightRepository _flightRepository;
  final MetricUnitsRepository _metricUnitsRepository;
  StreamSubscription<void>? _changesSubscription;

  Future<void> load() async {
    emit(const MediaTabLoading());
    try {
      final captures = await _repository.getCaptures();
      final flights = await _flightRepository.getAllFlights();
      final dateDisplayFormat = await _loadDateDisplayFormat();
      emit(
        MediaTabLoaded(
          folders: _buildFolders(
            captures: captures,
            flightsById: {for (final flight in flights) flight.id: flight},
          ),
          dateDisplayFormat: dateDisplayFormat,
        ),
      );
    } catch (_) {
      emit(MediaTabError(message: t.media.failedToLoad));
    }
  }

  Future<void> deleteCaptureIds(Iterable<String> captureIds) async {
    await _repository.deleteCaptureIds(captureIds);
  }

  List<MediaCaptureFolder> _buildFolders({
    required List<SkyCameraMediaItem> captures,
    required Map<String, Flight> flightsById,
  }) {
    final capturesByFolder = <String, List<SkyCameraMediaItem>>{};
    for (final capture in captures) {
      final folderId = capture.flightId?.trim().isNotEmpty == true
          ? 'flight:${capture.flightId}'
          : MediaCaptureFolder.noFlightFolderId;
      capturesByFolder
          .putIfAbsent(folderId, () => <SkyCameraMediaItem>[])
          .add(capture);
    }

    final folders = <MediaCaptureFolder>[];
    for (final entry in capturesByFolder.entries) {
      final items = entry.value
        ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
      final first = items.first;
      if (entry.key == MediaCaptureFolder.noFlightFolderId) {
        folders.add(
          MediaCaptureFolder(
            id: entry.key,
            title: t.media.groupNoFlight,
            subtitle: t.media.groupNoFlightSubtitle,
            captures: items,
          ),
        );
        continue;
      }
      final flight = first.flightId == null
          ? null
          : flightsById[first.flightId!.trim()];
      folders.add(
        MediaCaptureFolder(
          id: entry.key,
          title: _folderTitle(first, flight),
          subtitle: _folderSubtitle(first, flight),
          captures: items,
        ),
      );
    }

    folders.sort((a, b) {
      final aLatest = a.coverCapture.capturedAt;
      final bLatest = b.coverCapture.capturedAt;
      return bLatest.compareTo(aLatest);
    });
    return folders;
  }

  String _folderTitle(SkyCameraMediaItem capture, Flight? flight) {
    if (flight != null) {
      return '${flight.departure.displayCode} - ${flight.arrival.displayCode}';
    }
    return capture.routeLabel ?? t.media.groupUnknownFlight;
  }

  String? _folderSubtitle(SkyCameraMediaItem capture, Flight? flight) {
    if (flight != null) {
      final departure = flight.departure.city.trim().isNotEmpty
          ? flight.departure.city.trim()
          : flight.departure.nameShort;
      final arrival = flight.arrival.city.trim().isNotEmpty
          ? flight.arrival.city.trim()
          : flight.arrival.nameShort;
      return '$departure - $arrival';
    }
    final flightId = capture.flightId?.trim();
    return flightId == null || flightId.isEmpty ? null : flightId;
  }

  Future<DateDisplayFormat> _loadDateDisplayFormat() async {
    try {
      return await _metricUnitsRepository.getDateDisplayFormat();
    } catch (_) {
      return DateDisplayFormat.us;
    }
  }

  @override
  Future<void> close() async {
    await _changesSubscription?.cancel();
    return super.close();
  }
}
