import 'package:sky_camera/src/domain/services/sky_camera_driver.dart';

class SkyCameraZoomController {
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _currentZoomLevel = 1.0;
  double _baseZoomLevel = 1.0;
  DateTime? _ignoreTapUntil;

  double get minZoomLevel => _minZoomLevel;
  double get maxZoomLevel => _maxZoomLevel;
  double get currentZoomLevel => _currentZoomLevel;

  Future<void> loadBounds(SkyCameraDriver driver) async {
    final zoomBounds = await driver.getZoomBounds();
    _minZoomLevel = zoomBounds.min;
    _maxZoomLevel = zoomBounds.max < zoomBounds.min
        ? zoomBounds.min
        : zoomBounds.max;
    _currentZoomLevel = _minZoomLevel;
    _baseZoomLevel = _currentZoomLevel;
  }

  void handleScaleStart() {
    _baseZoomLevel = _currentZoomLevel;
  }

  Future<bool> handleScaleUpdate({
    required SkyCameraDriver driver,
    required int pointers,
    required double scale,
    required DateTime now,
  }) async {
    if (pointers < 2) return false;
    final nextZoomLevel = (_baseZoomLevel * scale).clamp(
      _minZoomLevel,
      _maxZoomLevel,
    );
    if ((nextZoomLevel - _currentZoomLevel).abs() < 0.01) {
      return false;
    }
    _ignoreTapUntil = now.add(const Duration(milliseconds: 250));
    _currentZoomLevel = nextZoomLevel;
    await driver.setZoomLevel(nextZoomLevel);
    return true;
  }

  Future<bool> setZoomLevel({
    required SkyCameraDriver driver,
    required double zoomLevel,
    required DateTime now,
  }) async {
    final clampedZoomLevel = zoomLevel.clamp(_minZoomLevel, _maxZoomLevel);
    if ((clampedZoomLevel - _currentZoomLevel).abs() < 0.01) {
      return false;
    }
    _ignoreTapUntil = now.add(const Duration(milliseconds: 250));
    _currentZoomLevel = clampedZoomLevel;
    _baseZoomLevel = clampedZoomLevel;
    await driver.setZoomLevel(clampedZoomLevel);
    return true;
  }

  bool shouldIgnoreTap(DateTime now) {
    final ignoreTapUntil = _ignoreTapUntil;
    return ignoreTapUntil != null && now.isBefore(ignoreTapUntil);
  }

  List<double> presets() {
    final presets = <double>{_minZoomLevel, 1.0, 2.0, 3.0, 4.0};
    final filtered =
        presets
            .where((value) => value >= _minZoomLevel && value <= _maxZoomLevel)
            .toList(growable: false)
          ..sort();
    return filtered;
  }

  String formatLabel(double zoomLevel) {
    final rounded = double.parse(zoomLevel.toStringAsFixed(1));
    final hasFraction = (rounded - rounded.roundToDouble()).abs() > 0.01;
    return hasFraction
        ? '${rounded.toStringAsFixed(1)}x'
        : '${rounded.round()}x';
  }
}
