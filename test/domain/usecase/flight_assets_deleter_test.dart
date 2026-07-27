import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_article.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_map.dart';
import 'package:flymap/domain/entity/flight_offline_content.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';
import 'package:flymap/domain/entity/flight_timestamp.dart';
import 'package:flymap/domain/entity/flight_waypoint.dart';
import 'package:flymap/domain/usecase/flight_assets_deleter.dart';
import 'package:flymap/map_download_config.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory cacheDir;
  late Directory docsDir;
  late Directory mbtilesDir;
  late List<Flight> allFlights;
  late FlightAssetsDeleter deleter;

  setUp(() async {
    cacheDir = await Directory.systemTemp.createTemp('deleter_cache');
    docsDir = await Directory.systemTemp.createTemp('deleter_docs');
    mbtilesDir = Directory(
      p.join(cacheDir.path, MapDownloadConfig.mbtilesDirectoryName),
    )..createSync(recursive: true);
    allFlights = [];
    deleter = FlightAssetsDeleter(
      getAllFlights: () async => allFlights,
      cacheDirectoryProvider: () async => cacheDir,
      documentsDirectoryProvider: () async => docsDir,
    );
  });

  tearDown(() {
    cacheDir.deleteSync(recursive: true);
    docsDir.deleteSync(recursive: true);
  });

  File mbtilesFile(String name) => File(p.join(mbtilesDir.path, name));

  File articleImage(String relativePath) {
    final file = File(p.join(docsDir.path, relativePath));
    file.createSync(recursive: true);
    return file;
  }

  group('FlightAssetsDeleter', () {
    test('keeps a map file still referenced by another flight', () async {
      // Two flights on the same route share one physical MBTiles file.
      final file = mbtilesFile('EGLL_EDDM_base.mbtiles')..createSync();
      final flightA = _flight(id: 'a', mapFile: 'EGLL_EDDM_base.mbtiles');
      final flightB = _flight(id: 'b', mapFile: 'EGLL_EDDM_base.mbtiles');
      allFlights = [flightA, flightB];

      await deleter.deleteAssets(flightA);

      expect(
        file.existsSync(),
        isTrue,
        reason:
            "flight B still needs this map — deleting flight A must not remove it",
      );
    });

    test(
      'deletes the map file and sidecars when it is the last reference',
      () async {
        final file = mbtilesFile('EGLL_EDDM_base.mbtiles')..createSync();
        final wal = mbtilesFile('EGLL_EDDM_base.mbtiles-wal')..createSync();
        final flightA = _flight(id: 'a', mapFile: 'EGLL_EDDM_base.mbtiles');
        allFlights = [flightA];

        await deleter.deleteAssets(flightA);

        expect(file.existsSync(), isFalse);
        expect(wal.existsSync(), isFalse);
      },
    );

    test('a different route\'s file is never touched', () async {
      final other = mbtilesFile('KJFK_KLAX_base.mbtiles')..createSync();
      final flightA = _flight(id: 'a', mapFile: 'EGLL_EDDM_base.mbtiles');
      allFlights = [flightA];

      await deleter.deleteAssets(flightA);

      expect(other.existsSync(), isTrue);
    });

    test(
      'keeps shared article images, deletes unshared ones and prunes dirs',
      () async {
        const sharedPath = 'article_media/EGLL_EDDM/munich_1/lead.jpg';
        const soloPath = 'article_media/EGLL_EDDM/london_2/inline_0.jpg';
        final shared = articleImage(sharedPath);
        final solo = articleImage(soloPath);

        final flightA = _flight(
          id: 'a',
          articleImages: const [sharedPath, soloPath],
        );
        final flightB = _flight(id: 'b', articleImages: const [sharedPath]);
        allFlights = [flightA, flightB];

        await deleter.deleteAssets(flightA);

        expect(
          shared.existsSync(),
          isTrue,
          reason: 'flight B still references the shared image',
        );
        expect(solo.existsSync(), isFalse);
        expect(
          solo.parent.existsSync(),
          isFalse,
          reason: 'emptied article dir should be pruned',
        );
        expect(
          Directory(p.join(docsDir.path, 'article_media')).existsSync(),
          isTrue,
          reason: 'the article_media root itself must survive',
        );
      },
    );

    test('deleting both flights in sequence removes the shared file', () async {
      final file = mbtilesFile('EGLL_EDDM_base.mbtiles')..createSync();
      final flightA = _flight(id: 'a', mapFile: 'EGLL_EDDM_base.mbtiles');
      final flightB = _flight(id: 'b', mapFile: 'EGLL_EDDM_base.mbtiles');

      allFlights = [flightA, flightB];
      await deleter.deleteAssets(flightA);
      expect(file.existsSync(), isTrue);

      // Flight A's record is gone by the time B is deleted.
      allFlights = [flightB];
      await deleter.deleteAssets(flightB);
      expect(file.existsSync(), isFalse);
    });
  });
}

Flight _flight({
  required String id,
  String? mapFile,
  List<String> articleImages = const [],
}) {
  const departure = Airport(
    name: 'London Heathrow',
    city: 'London',
    countryCode: 'GB',
    latLon: LatLng(51.47, -0.45),
    iataCode: 'LHR',
    icaoCode: 'EGLL',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'Munich Airport',
    city: 'Munich',
    countryCode: 'DE',
    latLon: LatLng(48.35, 11.79),
    iataCode: 'MUC',
    icaoCode: 'EDDM',
    wikipediaUrl: '',
  );
  const route = FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [
      FlightWaypoint(latLon: LatLng(51.47, -0.45)),
      FlightWaypoint(latLon: LatLng(48.35, 11.79)),
    ],
    corridor: [
      LatLng(51.47, -0.45),
      LatLng(48.35, -0.45),
      LatLng(48.35, 11.79),
    ],
    metrics: FlightRouteMetrics(
      greatCircleDistanceKm: 1487.5,
      cruiseMinutes: 105,
    ),
  );

  return Flight(
    id: id,
    route: route,
    routeInsights: FlightInfo.empty.routeInsights,
    offlineContent: FlightOfflineContent(
      articles: [
        for (var i = 0; i < articleImages.length; i++)
          FlightArticle(
            sourceUrl: 'https://en.wikipedia.org/wiki/Article_$i',
            title: 'Article $i',
            summary: '',
            contentPlainText: '',
            contentHtml: '',
            languageCode: 'en',
            leadImageRelativePath: articleImages[i],
            inlineImageRelativePaths: const [],
            attributionText: '',
            licenseText: '',
            downloadedAt: DateTime(2026, 1, 1),
            sizeBytes: 1,
          ),
      ],
    ),
    maps: [
      if (mapFile != null)
        FlightMap(
          layer: 'base',
          sizeBytes: 1024,
          downloadedAt: DateTime(2026, 1, 1),
          filePath: mapFile,
        ),
    ],
    timestamp: FlightTimestamp(createdAt: DateTime(2026, 1, 1)),
  );
}
