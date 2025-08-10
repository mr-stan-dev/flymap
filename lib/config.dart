class Config {
  // AirLabs API Configuration
  static const String airLabsApiKey =
      'YOUR_AIRLABS_API_KEY'; // Replace with your actual API key
  static const String airLabsBaseUrl = 'https://airlabs.co/api/v9';

  // OpenSky Network API Configuration
  static const String openSkyBaseUrl = 'https://opensky-network.org/api';
  static const String openSkyUsername =
      'YOUR_OPENSKY_USERNAME'; // Replace with your username
  static const String openSkyPassword =
      'YOUR_OPENSKY_PASSWORD'; // Replace with your password

  // Mapbox Configuration
  static const String mapboxAccessToken =
      'YOUR_MAPBOX_ACCESS_TOKEN'; // Replace with your Mapbox access token
  static const String mapboxStyleUrl = 'mapbox://styles/mapbox/streets-v12';

  // Tile Download Configuration
  static const int defaultZoomLevel = 12;
  static const int maxZoomLevel = 18;
  static const int minZoomLevel = 0;
  static const String tileDownloadPath =
      '/tiles'; // Directory for storing downloaded tiles

  // Map Configuration
  static const double defaultZoom = 2.0;
  static const double routeStrokeWidth = 3.0;
  static const int routeSegments = 20;

  // UI Configuration
  static const double markerSize = 30.0;
  static const double mapPadding = 50.0;

  // PMTiles Server Configuration
  static const String pmTilesServerUrl =
      'http://localhost:3000'; // Update with your server URL
}
