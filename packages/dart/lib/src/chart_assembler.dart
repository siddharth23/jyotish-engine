import 'chart.dart';
import 'dignity.dart';
import 'divisional.dart';
import 'house_system.dart';
import 'houses.dart';
import 'nakshatra.dart';
import 'planet.dart';
import 'rasi.dart';
import 'raw_ephemeris.dart';
import 'version.dart';

/// Builds a complete [Chart] from raw ephemeris output.
///
/// This is the whole derivation half of the engine. Given longitudes and an
/// ascendant, everything else — signs, nakshatras, padas, houses, dignity,
/// combustion — is arithmetic, and identical on every platform.
///
/// Ketu is derived from Rahu when the ephemeris supplies only the one node.
///
/// Retrograde motion is reported from the sign of the body's speed rather than by
/// convention. The mean lunar node always moves backwards and so always reports
/// retrograde; the true node oscillates and will occasionally report direct motion,
/// which is astronomically correct rather than a defect.
Chart assembleChart(BirthData birthData, RawEphemeris rawEphemeris) {
  final raw = rawEphemeris.withDerivedKetu();

  final cusps = switch (birthData.houseSystem) {
    HouseSystem.wholeSign ||
    HouseSystem.equal =>
      cuspsFor(birthData.houseSystem, raw.ascendant),
    HouseSystem.placidus || HouseSystem.koch => raw.houseCusps ??
        (throw ArgumentError(
          '${birthData.houseSystem.name} requires ephemeris-derived cusps, but '
          'RawEphemeris.houseCusps was null.',
        )),
  };

  final sun = raw[Graha.sun];
  if (sun == null) {
    throw ArgumentError(
        'The ephemeris did not supply the Sun, which combustion needs.');
  }

  final positions = <Graha, GrahaPosition>{};
  for (final body in raw.bodies) {
    final longitude = normaliseDegrees(body.siderealLongitude);
    final sign = Rasi.fromLongitude(longitude);
    final isRetrograde = body.speed < 0;

    positions[body.graha] = GrahaPosition(
      graha: body.graha,
      siderealLongitude: longitude,
      latitude: body.latitude,
      speed: body.speed,
      sign: sign.index,
      degreeInSign: longitude % 30,
      nakshatra: Nakshatra.fromLongitude(longitude).index,
      pada: padaOfLongitude(longitude),
      house: houseOfLongitude(longitude, cusps),
      dignity: dignityOf(body.graha, sign),
      isRetrograde: isRetrograde,
      isCombust: isCombust(
        body.graha,
        longitude,
        sun.siderealLongitude,
        isRetrograde: isRetrograde,
      ),
    );
  }

  return Chart(
    input: birthData,
    ascendant: normaliseDegrees(raw.ascendant),
    ascendantSign: Rasi.fromLongitude(raw.ascendant).index,
    houseCusps: cusps,
    positions: positions,
    ayanamsaValue: raw.ayanamsaValue,
    engineVersion: engineVersion,
  );
}

/// Derives a divisional chart from an already computed rasi chart.
///
/// Varga charts are cast in whole sign from the varga ascendant, which is the
/// standard treatment: a varga is a mapping of signs, and quadrant cusps have no
/// meaning once positions have been remapped.
///
/// Two fields are carried across from the rasi chart rather than recomputed:
///
/// - **Combustion** is proximity to the physical Sun. It is a fact about the sky at
///   birth, not about the varga, so recomputing it from remapped longitudes would be
///   meaningless.
/// - **Latitude and speed** are likewise physical quantities of the body itself.
///
/// Nakshatra and pada *are* recomputed, from the scaled varga longitude described in
/// [vargaLongitude]. They are engine artefacts in a varga chart, not classical
/// quantities — see that function's note before relying on them.
Chart computeDivisionalChart(Chart rasi, Varga varga) {
  if (varga == Varga.d1) return rasi;
  if (rasi.varga != Varga.d1) {
    throw ArgumentError(
      'Divisional charts must be derived from a rasi chart, but the input is '
      '${rasi.varga.name}.',
    );
  }

  final ascendantLongitude = vargaLongitude(rasi.ascendant, varga);
  final ascendantSign = Rasi.fromLongitude(ascendantLongitude);
  final cusps = wholeSignCusps(ascendantSign);

  final positions = <Graha, GrahaPosition>{};
  for (final entry in rasi.positions.entries) {
    final source = entry.value;
    final longitude = vargaLongitude(source.siderealLongitude, varga);
    final sign = Rasi.fromLongitude(longitude);

    positions[entry.key] = GrahaPosition(
      graha: source.graha,
      siderealLongitude: longitude,
      latitude: source.latitude,
      speed: source.speed,
      sign: sign.index,
      degreeInSign: longitude % 30,
      nakshatra: Nakshatra.fromLongitude(longitude).index,
      pada: padaOfLongitude(longitude),
      house: houseOfLongitude(longitude, cusps),
      dignity: dignityOf(source.graha, sign),
      isRetrograde: source.isRetrograde,
      isCombust: source.isCombust,
    );
  }

  return Chart(
    input: rasi.input,
    varga: varga,
    ascendant: ascendantLongitude,
    ascendantSign: ascendantSign.index,
    houseCusps: cusps,
    positions: positions,
    ayanamsaValue: rasi.ayanamsaValue,
    engineVersion: rasi.engineVersion,
  );
}
