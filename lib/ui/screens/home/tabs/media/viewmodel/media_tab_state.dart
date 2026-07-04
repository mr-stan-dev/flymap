import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';

sealed class MediaTabState extends Equatable {
  const MediaTabState();

  @override
  List<Object?> get props => const [];
}

class MediaTabLoading extends MediaTabState {
  const MediaTabLoading();
}

class MediaTabError extends MediaTabState {
  const MediaTabError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

class MediaTabLoaded extends MediaTabState {
  const MediaTabLoaded({
    required this.folders,
    required this.dateDisplayFormat,
  });

  final List<MediaCaptureFolder> folders;
  final DateDisplayFormat dateDisplayFormat;

  bool get isEmpty => folders.isEmpty;

  @override
  List<Object?> get props => [folders, dateDisplayFormat];
}

class MediaCaptureFolder extends Equatable {
  static const noFlightFolderId = 'no-flight';

  const MediaCaptureFolder({
    required this.id,
    required this.title,
    required this.captures,
    this.subtitle,
  });

  final String id;
  final String title;
  final String? subtitle;
  final List<SkyCameraMediaItem> captures;

  bool get hasFlightContext => id != noFlightFolderId;

  SkyCameraMediaItem get coverCapture => captures.first;

  int get additionalCaptureCount =>
      captures.length > 1 ? captures.length - 1 : 0;

  @override
  List<Object?> get props => [id, title, subtitle, captures];
}
