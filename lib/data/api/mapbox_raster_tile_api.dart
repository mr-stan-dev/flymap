import 'dart:typed_data';

import 'package:flymap/logger.dart';
import 'package:flymap/ui/screens/flight_video/rendering/tile_resolver.dart';
import 'package:http/http.dart' as http;

/// Fetches raster tiles from the Mapbox Static Tiles API.
///
/// Same satellite-streets style the share image uses, but as individual
/// 512px tiles so the flight-video renderer can stitch and reuse them
/// across frames.
class MapboxRasterTileApi {
  MapboxRasterTileApi({
    required http.Client httpClient,
    required String accessToken,
  }) : _httpClient = httpClient,
       _accessToken = accessToken;

  final http.Client _httpClient;
  final String _accessToken;
  final Logger _logger = const Logger('MapboxRasterTileApi');

  static const String _baseUrl = 'https://api.mapbox.com/styles/v1';
  static const Duration _timeout = Duration(seconds: 20);

  /// Returns raw image bytes for [coord] in [styleId], or null on failure.
  Future<Uint8List?> fetchTile(
    TileCoord coord, {
    required String styleId,
    bool retina = false,
  }) async {
    final retinaSuffix = retina ? '@2x' : '';
    final url =
        '$_baseUrl/$styleId/tiles/512/${coord.z}/${coord.x}/${coord.y}'
        '$retinaSuffix?access_token=$_accessToken';

    try {
      final response = await _httpClient.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      _logger.error(
        'Tile $coord failed: ${response.statusCode} ${response.reasonPhrase}',
      );
      return null;
    } catch (e) {
      _logger.error('Tile $coord failed: $e');
      return null;
    }
  }
}
