import 'package:flymap/logger.dart';
import 'package:gal/gal.dart';

/// Saves generated videos to the device gallery.
///
/// Permission denial is not fatal: the caller keeps the temp file and the
/// share sheet still works without gallery access.
class MediaGallerySaver {
  const MediaGallerySaver();

  static const Logger _logger = Logger('MediaGallerySaver');

  /// Returns true when the video landed in the gallery.
  Future<bool> saveVideo(String filePath) async {
    try {
      if (!await Gal.hasAccess()) {
        final granted = await Gal.requestAccess();
        if (!granted) return false;
      }
      await Gal.putVideo(filePath);
      return true;
    } on GalException catch (e) {
      _logger.error('Gallery save failed: ${e.type.name}');
      return false;
    } catch (e) {
      _logger.error('Gallery save failed: $e');
      return false;
    }
  }
}
