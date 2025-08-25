import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ICAO codes are 4 uppercase alphanumeric when present', () async {
    final file = File('assets/data/airports.csv');
    expect(await file.exists(), isTrue, reason: 'airports.csv not found');

    final text = await file.readAsString();
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(text);
    expect(rows.isNotEmpty, isTrue, reason: 'CSV has no rows');

    final header = rows.first.map((e) => (e ?? '').toString()).toList();
    final iIcao = header.indexOf('icao_code');
    expect(iIcao >= 0, isTrue, reason: 'icao_code column missing');

    final regex = RegExp(r'^[A-Z0-9]{4}$');
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i].map((e) => (e ?? '').toString().trim()).toList();
      if (row.length <= iIcao) continue;
      final icao = row[iIcao];
      if (icao.isEmpty) continue; // allow missing ICAO
      expect(
        regex.hasMatch(icao),
        isTrue,
        reason: 'Row ${i + 1} invalid ICAO: "$icao"',
      );
    }
  });

  test('Log blanks and anomalies for ICAO and Wikipedia', () async {
    final file = File('assets/data/airports.csv');
    expect(await file.exists(), isTrue, reason: 'airports.csv not found');

    final text = await file.readAsString();
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(text);
    final header = rows.first.map((e) => (e ?? '').toString()).toList();

    int idx(String name) => header.indexOf(name);
    final iType = idx('type');
    final iName = idx('name');
    final iIdent = idx('ident');
    final iIata = idx('iata_code');
    final iIcao = idx('icao_code');
    final iWiki = idx('wikipedia_link');

    final blanks = <String>[];
    final invalidIcao = <String>[];
    final wikiMissing = <String>[];
    final wikiWeird = <String>[];

    final regex = RegExp(r'^[A-Z0-9]{4}$');

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i].map((e) => (e ?? '').toString().trim()).toList();
      String getF(int idx) => (idx >= 0 && idx < row.length) ? row[idx] : '';

      final type = getF(iType);
      final name = getF(iName);
      final ident = getF(iIdent);
      final iata = getF(iIata);
      final icao = getF(iIcao);
      final wiki = getF(iWiki);

      final isRelevant = type == 'large_airport' || type == 'medium_airport';

      if (isRelevant && icao.isEmpty) {
        blanks.add('No ICAO: name="$name" ident=$ident iata=$iata');
      }
      if (icao.isNotEmpty && !regex.hasMatch(icao)) {
        invalidIcao.add('Bad ICAO: "$icao" name="$name"');
      }
      if (isRelevant && wiki.isEmpty) {
        wikiMissing.add('No Wikipedia: name="$name"');
      }
      if (wiki.isNotEmpty && !wiki.contains('wikipedia.org')) {
        wikiWeird.add('Non-wikipedia wiki: "$wiki" name="$name"');
      }
    }

    // Log summaries
    // Using print so it shows in test output
    print('ICAO blanks (relevant types): ${blanks.length}');
    for (final s in blanks.take(20)) {
      print('  - $s');
    }
    if (blanks.length > 20) print('  ... ${blanks.length - 20} more');

    print('Invalid ICAO format: ${invalidIcao.length}');
    for (final s in invalidIcao.take(20)) {
      print('  - $s');
    }
    if (invalidIcao.length > 20) print('  ... ${invalidIcao.length - 20} more');

    print('Missing Wikipedia (relevant types): ${wikiMissing.length}');
    for (final s in wikiMissing.take(20)) {
      print('  - $s');
    }
    if (wikiMissing.length > 20) print('  ... ${wikiMissing.length - 20} more');

    print('Non-wikipedia wiki links: ${wikiWeird.length}');
    for (final s in wikiWeird.take(20)) {
      print('  - $s');
    }
    if (wikiWeird.length > 20) print('  ... ${wikiWeird.length - 20} more');

    // Do not fail the test; this is informational
    expect(true, isTrue);
  });
}
