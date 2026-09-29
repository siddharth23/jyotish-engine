// Runs the Dart derivation over test/parity/cases.json and prints the results.
//
// The committed output, test/parity/dart_output.json, is what the TypeScript port in
// packages/wasm is checked against. CI regenerates it and fails if it changes without
// being committed, so the two implementations cannot drift apart silently.
//
//   dart run tool/derive.dart > ../../test/parity/dart_output.json
import 'dart:convert';
import 'dart:io';

import 'package:jyotish_engine/jyotish_engine.dart';

void main() {
  final input = jsonDecode(
    File('../../test/parity/cases.json').readAsStringSync(),
  ) as Map<String, Object?>;

  final results = <Map<String, Object?>>[];
  for (final c in (input['cases'] as List).cast<Map<String, Object?>>()) {
    final b = c['birth'] as Map<String, Object?>;
    final r = c['raw'] as Map<String, Object?>;
    final birth = BirthData(
      utcDateTime: DateTime.parse(b['utcDateTime'] as String),
      latitude: (b['latitude'] as num).toDouble(),
      longitude: (b['longitude'] as num).toDouble(),
      ayanamsa: Ayanamsa.values.byName(b['ayanamsa'] as String),
      houseSystem: HouseSystem.values.byName(b['houseSystem'] as String),
      useTrueNode: b['useTrueNode'] as bool,
    );
    final raw = RawEphemeris(
      ascendant: (r['ascendant'] as num).toDouble(),
      ayanamsaValue: (r['ayanamsaValue'] as num).toDouble(),
      houseCusps: (r['houseCusps'] as List?)
          ?.map((v) => (v as num).toDouble())
          .toList(),
      bodies: [
        for (final body in (r['bodies'] as List).cast<Map<String, Object?>>())
          RawBodyPosition(
            graha: Graha.values.byName(body['graha'] as String),
            siderealLongitude: (body['siderealLongitude'] as num).toDouble(),
            latitude: (body['latitude'] as num).toDouble(),
            speed: (body['speed'] as num).toDouble(),
          ),
      ],
    );

    final chart = assembleChart(birth, raw);
    results.add({
      'id': c['id'],
      'd1': chart.toJson(),
      'd9': computeDivisionalChart(chart, Varga.d9).toJson(),
      'd10': computeDivisionalChart(chart, Varga.d10).toJson(),
      'dashas': [
        for (final p in computeVimshottariDashas(
          moonSiderealLongitude: chart.positions[Graha.moon]!.siderealLongitude,
          birthUtc: birth.utcDateTime,
          depth: 2,
        ).take(3))
          p.toJson(),
      ],
    });
  }
  stdout
      .writeln(const JsonEncoder.withIndent(' ').convert({'results': results}));
}
