import 'house_system.dart';
import 'rasi.dart';

/// The twelve whole-sign house cusps for an ascendant in [ascendantSign].
///
/// In whole sign the ascendant's entire sign is the first house, regardless of
/// where in that sign the ascendant degree falls. Cusps are therefore always exact
/// sign boundaries.
List<double> wholeSignCusps(Rasi ascendantSign) => [
      for (var i = 0; i < 12; i++)
        Rasi.fromIndex(ascendantSign.index + i).index * 30.0
    ];

/// The twelve equal house cusps for an [ascendant] longitude in degrees.
///
/// Each house is exactly 30 degrees measured from the ascendant degree itself.
List<double> equalCusps(double ascendant) =>
    [for (var i = 0; i < 12; i++) normaliseDegrees(ascendant + i * 30)];

/// Cusps for [system], where the system can be derived without an ephemeris.
///
/// Placidus and Koch depend on latitude, obliquity and sidereal time, so their
/// cusps must come from Swiss Ephemeris via [RawEphemeris.houseCusps]; requesting
/// them here throws rather than silently substituting a different system.
List<double> cuspsFor(HouseSystem system, double ascendant) => switch (system) {
      HouseSystem.wholeSign => wholeSignCusps(Rasi.fromLongitude(ascendant)),
      HouseSystem.equal => equalCusps(ascendant),
      HouseSystem.placidus || HouseSystem.koch => throw ArgumentError(
          '${system.name} cusps are ephemeris-derived and cannot be computed here. '
          'Supply them via RawEphemeris.houseCusps.',
        ),
    };

/// House number, 1 to 12, containing [longitude] given twelve [cusps].
///
/// Works for any system, including quadrant systems whose houses are unequal:
/// house `n` spans from `cusps[n - 1]` up to but excluding `cusps[n]`.
///
/// Throws if the cusps do not cover the full circle, which happens when a quadrant
/// system degenerates at extreme latitude. Failing loudly is deliberate: a body
/// silently assigned to the wrong house is a wrong chart.
int houseOfLongitude(double longitude, List<double> cusps) {
  if (cusps.length != 12) {
    throw ArgumentError('Expected 12 cusps, got ${cusps.length}.');
  }
  final lon = normaliseDegrees(longitude);

  for (var i = 0; i < 12; i++) {
    final start = normaliseDegrees(cusps[i]);
    final end = normaliseDegrees(cusps[(i + 1) % 12]);
    final withinInterval =
        start <= end ? lon >= start && lon < end : lon >= start || lon < end;
    if (withinInterval) return i + 1;
  }

  throw StateError(
    'Longitude $lon falls in no house. The cusps do not cover the circle, which '
    'indicates a degenerate quadrant house system at this latitude.',
  );
}
