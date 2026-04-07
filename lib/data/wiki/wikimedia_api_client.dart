import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

abstract interface class WikimediaUserAgentProvider {
  Future<String> getUserAgent();
}

class PackageInfoWikimediaUserAgentProvider
    implements WikimediaUserAgentProvider {
  PackageInfoWikimediaUserAgentProvider({
    this.appName = 'Flymap',
    this.contactUrl = 'https://www.apptractor.dev/projects/flymap',
  });

  final String appName;
  final String contactUrl;
  String? _cached;

  @override
  Future<String> getUserAgent() async {
    final cached = _cached;
    if (cached != null) return cached;

    var version = 'unknown';
    var buildNumber = '0';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      version = packageInfo.version.trim().isEmpty
          ? version
          : packageInfo.version.trim();
      buildNumber = packageInfo.buildNumber.trim().isEmpty
          ? buildNumber
          : packageInfo.buildNumber.trim();
    } catch (_) {
      // Keep request path non-blocking if package info is unavailable.
    }

    final value =
        '$appName/$version+$buildNumber ($contactUrl; wikimedia-client)';
    _cached = value;
    return value;
  }
}

class WikimediaApiClient {
  WikimediaApiClient({
    required http.Client httpClient,
    required WikimediaUserAgentProvider userAgentProvider,
  }) : _httpClient = httpClient,
       _userAgentProvider = userAgentProvider;

  final http.Client _httpClient;
  final WikimediaUserAgentProvider _userAgentProvider;

  Future<http.Response> get(
    Uri uri, {
    required Duration timeout,
    Map<String, String>? headers,
  }) async {
    final userAgent = await _userAgentProvider.getUserAgent();
    final requestHeaders = <String, String>{
      'User-Agent': userAgent,
      if (headers != null) ...headers,
    };

    return _httpClient.get(uri, headers: requestHeaders).timeout(timeout);
  }
}
