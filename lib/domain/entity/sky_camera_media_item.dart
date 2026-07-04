import 'package:equatable/equatable.dart';
import 'package:sky_camera/sky_camera.dart';

enum SkyCameraMediaType { photo, video }

class SkyCameraMediaRendition extends Equatable {
  const SkyCameraMediaRendition({
    required this.id,
    required this.skinId,
    required this.mediaType,
    required this.path,
    this.previewImagePath,
    this.createdAt,
  });

  final String id;
  final String skinId;
  final SkyCameraMediaType mediaType;
  final String path;
  final String? previewImagePath;
  final DateTime? createdAt;

  String get galleryImagePath {
    final preview = previewImagePath?.trim();
    if (preview != null && preview.isNotEmpty) return preview;
    if (mediaType == SkyCameraMediaType.photo) return path;
    return '';
  }

  Map<String, Object?> toRecord() {
    return <String, Object?>{
      'id': id,
      'skinId': skinId,
      'mediaType': mediaType.name,
      'path': path,
      'previewImagePath': previewImagePath,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static SkyCameraMediaRendition? fromRecord(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final skinId = json['skinId']?.toString().trim() ?? '';
    final path = json['path']?.toString().trim() ?? '';
    final mediaType = SkyCameraMediaTypeX.fromName(
      json['mediaType']?.toString(),
    );
    if (id.isEmpty || skinId.isEmpty || path.isEmpty || mediaType == null) {
      return null;
    }
    final createdAtRaw = json['createdAt']?.toString().trim();
    return SkyCameraMediaRendition(
      id: id,
      skinId: skinId,
      mediaType: mediaType,
      path: path,
      previewImagePath: json['previewImagePath']?.toString().trim(),
      createdAt: createdAtRaw == null || createdAtRaw.isEmpty
          ? null
          : DateTime.tryParse(createdAtRaw),
    );
  }

  @override
  List<Object?> get props => [
    id,
    skinId,
    mediaType,
    path,
    previewImagePath,
    createdAt,
  ];
}

class SkyCameraMediaTrackPoint extends Equatable {
  const SkyCameraMediaTrackPoint({
    required this.offsetMs,
    required this.latitude,
    required this.longitude,
    this.headingDegrees,
    this.altitudeMeters,
    this.speedMetersPerSecond,
  });

  final int offsetMs;
  final double latitude;
  final double longitude;
  final double? headingDegrees;
  final double? altitudeMeters;
  final double? speedMetersPerSecond;

  Map<String, Object?> toRecord() {
    return <String, Object?>{
      'offsetMs': offsetMs,
      'latitude': latitude,
      'longitude': longitude,
      'headingDegrees': headingDegrees,
      'altitudeMeters': altitudeMeters,
      'speedMetersPerSecond': speedMetersPerSecond,
    };
  }

  static SkyCameraMediaTrackPoint? fromRecord(Map<String, dynamic> json) {
    final offsetMs = _toInt(json['offsetMs']);
    final latitude = _toDouble(json['latitude']);
    final longitude = _toDouble(json['longitude']);
    if (offsetMs == null || latitude == null || longitude == null) {
      return null;
    }
    return SkyCameraMediaTrackPoint(
      offsetMs: offsetMs,
      latitude: latitude,
      longitude: longitude,
      headingDegrees: _toDouble(json['headingDegrees']),
      altitudeMeters: _toDouble(json['altitudeMeters']),
      speedMetersPerSecond: _toDouble(json['speedMetersPerSecond']),
    );
  }

  static int? _toInt(Object? value) {
    return switch (value) {
      int i => i,
      num n => n.toInt(),
      String s => int.tryParse(s),
      _ => null,
    };
  }

  static double? _toDouble(Object? value) {
    return switch (value) {
      double d => d,
      num n => n.toDouble(),
      String s => double.tryParse(s),
      _ => null,
    };
  }

  @override
  List<Object?> get props => [
    offsetMs,
    latitude,
    longitude,
    headingDegrees,
    altitudeMeters,
    speedMetersPerSecond,
  ];
}

class SkyCameraMediaItem extends Equatable {
  static const currentSchemaVersion = 1;

  const SkyCameraMediaItem({
    required this.id,
    required this.capturedAt,
    required this.mediaType,
    required this.sourcePath,
    required this.snapshot,
    required this.renditions,
    required this.trackPoints,
    this.flightId,
    this.latitude,
    this.longitude,
    this.gridKey,
    this.geohash,
    this.previewImagePath,
    this.selectedRenditionId,
    this.durationMs,
    this.outsideTemperatureCelsius,
  });

  final String id;
  final DateTime capturedAt;
  final SkyCameraMediaType mediaType;
  final String sourcePath;
  final SkyCameraOverlaySnapshot snapshot;
  final List<SkyCameraMediaRendition> renditions;
  final List<SkyCameraMediaTrackPoint> trackPoints;
  final String? flightId;
  final double? latitude;
  final double? longitude;
  final String? gridKey;
  final String? geohash;
  final String? previewImagePath;
  final String? selectedRenditionId;
  final int? durationMs;
  final double? outsideTemperatureCelsius;

  bool get isVideo => mediaType == SkyCameraMediaType.video;

  SkyCameraMediaRendition? get selectedRendition {
    final selectedId = selectedRenditionId?.trim();
    if (selectedId != null && selectedId.isNotEmpty) {
      for (final rendition in renditions) {
        if (rendition.id == selectedId) return rendition;
      }
    }
    if (renditions.isEmpty) return null;
    return renditions.first;
  }

  String? get routeLabel {
    final origin = snapshot.originCode.trim();
    final destination = snapshot.destinationCode.trim();
    if (origin.isNotEmpty && destination.isNotEmpty) {
      return '$origin - $destination';
    }
    final routeLabel = snapshot.routeLabel.trim();
    return routeLabel.isEmpty ? null : routeLabel;
  }

  String get galleryImagePath {
    final rendition = selectedRendition;
    final renditionPath = rendition == null
        ? ''
        : rendition.galleryImagePath.trim();
    if (renditionPath.isNotEmpty) return renditionPath;
    final preview = previewImagePath?.trim() ?? '';
    if (preview.isNotEmpty) return preview;
    if (mediaType == SkyCameraMediaType.photo) return sourcePath;
    return '';
  }

  String get sharePath {
    final rendition = selectedRendition;
    final renditionPath = rendition == null ? '' : rendition.path.trim();
    if (renditionPath.isNotEmpty) return renditionPath;
    return sourcePath;
  }

  Set<String> get storedPaths {
    final paths = <String>{sourcePath};
    final preview = previewImagePath?.trim();
    if (preview != null && preview.isNotEmpty) {
      paths.add(preview);
    }
    for (final rendition in renditions) {
      final path = rendition.path.trim();
      if (path.isNotEmpty) {
        paths.add(path);
      }
      final renditionPreview = rendition.previewImagePath?.trim();
      if (renditionPreview != null && renditionPreview.isNotEmpty) {
        paths.add(renditionPreview);
      }
    }
    return paths;
  }

  String get originalPath => sourcePath;

  String get capturedOverlayPath => sharePath;

  SkyCameraMediaItem copyWith({
    String? id,
    DateTime? capturedAt,
    SkyCameraMediaType? mediaType,
    String? sourcePath,
    SkyCameraOverlaySnapshot? snapshot,
    List<SkyCameraMediaRendition>? renditions,
    List<SkyCameraMediaTrackPoint>? trackPoints,
    String? flightId,
    double? latitude,
    double? longitude,
    String? gridKey,
    String? geohash,
    String? previewImagePath,
    String? selectedRenditionId,
    int? durationMs,
    double? outsideTemperatureCelsius,
  }) {
    return SkyCameraMediaItem(
      id: id ?? this.id,
      capturedAt: capturedAt ?? this.capturedAt,
      mediaType: mediaType ?? this.mediaType,
      sourcePath: sourcePath ?? this.sourcePath,
      snapshot: snapshot ?? this.snapshot,
      renditions: renditions ?? this.renditions,
      trackPoints: trackPoints ?? this.trackPoints,
      flightId: flightId ?? this.flightId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gridKey: gridKey ?? this.gridKey,
      geohash: geohash ?? this.geohash,
      previewImagePath: previewImagePath ?? this.previewImagePath,
      selectedRenditionId: selectedRenditionId ?? this.selectedRenditionId,
      durationMs: durationMs ?? this.durationMs,
      outsideTemperatureCelsius:
          outsideTemperatureCelsius ?? this.outsideTemperatureCelsius,
    );
  }

  Map<String, Object?> toRecord() {
    return <String, Object?>{
      'schemaVersion': currentSchemaVersion,
      'id': id,
      'capturedAt': capturedAt.toIso8601String(),
      'mediaType': mediaType.name,
      'sourcePath': sourcePath,
      'snapshot': snapshot.toJson(),
      'renditions': [for (final rendition in renditions) rendition.toRecord()],
      'trackPoints': [
        for (final trackPoint in trackPoints) trackPoint.toRecord(),
      ],
      'flightId': flightId,
      'latitude': latitude,
      'longitude': longitude,
      'gridKey': gridKey,
      'geohash': geohash,
      'previewImagePath': previewImagePath,
      'selectedRenditionId': selectedRenditionId,
      'durationMs': durationMs,
      'outsideTemperatureCelsius': outsideTemperatureCelsius,
    };
  }

  static SkyCameraMediaItem? fromRecord(Map<String, dynamic> json) {
    final schemaVersion = _toInt(json['schemaVersion']) ?? 0;
    if (schemaVersion > currentSchemaVersion) return null;
    final id = json['id']?.toString().trim() ?? '';
    final capturedAtRaw = json['capturedAt']?.toString().trim() ?? '';
    final sourcePath =
        json['sourcePath']?.toString().trim() ??
        json['originalPath']?.toString().trim() ??
        '';
    final snapshotRaw = json['snapshot'];
    if (id.isEmpty ||
        capturedAtRaw.isEmpty ||
        sourcePath.isEmpty ||
        snapshotRaw is! Map) {
      return null;
    }
    final capturedAt = DateTime.tryParse(capturedAtRaw);
    final snapshot = SkyCameraOverlaySnapshot.fromJson(
      Map<String, dynamic>.from(snapshotRaw.cast<String, dynamic>()),
    );
    if (capturedAt == null || snapshot == null) return null;

    final mediaType =
        SkyCameraMediaTypeX.fromName(json['mediaType']?.toString()) ??
        SkyCameraMediaType.photo;
    final renditions = _renditionsFromRecord(json);
    final selectedRenditionId =
        json['selectedRenditionId']?.toString().trim().isNotEmpty == true
        ? json['selectedRenditionId']?.toString().trim()
        : renditions.isNotEmpty
        ? renditions.first.id
        : null;

    return SkyCameraMediaItem(
      id: id,
      capturedAt: capturedAt,
      mediaType: mediaType,
      sourcePath: sourcePath,
      snapshot: snapshot,
      renditions: renditions,
      trackPoints: _trackPointsFromRecord(json),
      flightId: json['flightId']?.toString().trim(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      gridKey: json['gridKey']?.toString().trim(),
      geohash: json['geohash']?.toString().trim(),
      previewImagePath: json['previewImagePath']?.toString().trim(),
      selectedRenditionId: selectedRenditionId,
      durationMs: _toInt(json['durationMs']),
      outsideTemperatureCelsius:
          _toDouble(json['outsideTemperatureCelsius']) ??
          snapshot.outsideTemperatureCelsius,
    );
  }

  static List<SkyCameraMediaRendition> _renditionsFromRecord(
    Map<String, dynamic> json,
  ) {
    final rawRenditions = json['renditions'];
    if (rawRenditions is List) {
      return [
        for (final raw in rawRenditions)
          if (raw is Map)
            ...() {
              final rendition = SkyCameraMediaRendition.fromRecord(
                Map<String, dynamic>.from(raw.cast<String, dynamic>()),
              );
              return rendition == null
                  ? const <SkyCameraMediaRendition>[]
                  : <SkyCameraMediaRendition>[rendition];
            }(),
      ];
    }

    final legacyOverlayPath =
        json['capturedOverlayPath']?.toString().trim() ?? '';
    if (legacyOverlayPath.isEmpty) return const <SkyCameraMediaRendition>[];
    return <SkyCameraMediaRendition>[
      SkyCameraMediaRendition(
        id: 'default',
        skinId: 'legacy_overlay',
        mediaType: SkyCameraMediaType.photo,
        path: legacyOverlayPath,
        previewImagePath: legacyOverlayPath,
      ),
    ];
  }

  static List<SkyCameraMediaTrackPoint> _trackPointsFromRecord(
    Map<String, dynamic> json,
  ) {
    final rawTrackPoints = json['trackPoints'];
    if (rawTrackPoints is! List) {
      return const <SkyCameraMediaTrackPoint>[];
    }
    return [
      for (final raw in rawTrackPoints)
        if (raw is Map)
          ...() {
            final trackPoint = SkyCameraMediaTrackPoint.fromRecord(
              Map<String, dynamic>.from(raw.cast<String, dynamic>()),
            );
            return trackPoint == null
                ? const <SkyCameraMediaTrackPoint>[]
                : <SkyCameraMediaTrackPoint>[trackPoint];
          }(),
    ];
  }

  static double? _toDouble(Object? value) {
    return switch (value) {
      double d => d,
      num n => n.toDouble(),
      String s => double.tryParse(s),
      _ => null,
    };
  }

  static int? _toInt(Object? value) {
    return switch (value) {
      int i => i,
      num n => n.toInt(),
      String s => int.tryParse(s),
      _ => null,
    };
  }

  @override
  List<Object?> get props => [
    id,
    capturedAt,
    mediaType,
    sourcePath,
    snapshot,
    renditions,
    trackPoints,
    flightId,
    latitude,
    longitude,
    gridKey,
    geohash,
    previewImagePath,
    selectedRenditionId,
    durationMs,
    outsideTemperatureCelsius,
  ];
}

extension SkyCameraMediaTypeX on SkyCameraMediaType {
  static SkyCameraMediaType? fromName(String? value) {
    return switch (value?.trim()) {
      'photo' => SkyCameraMediaType.photo,
      'video' => SkyCameraMediaType.video,
      _ => null,
    };
  }
}
