import 'planet.dart';

/// Modality (quality) of a rasi. Determines the starting point of several vargas.
enum Modality { movable, fixed, dual }

/// The twelve rasis (signs), in zodiacal order.
///
/// `index` 0 is Mesha (Aries). That integer is the wire format used throughout the
/// engine; this enum exists for readable table definitions and display.
enum Rasi {
  mesha,
  vrishabha,
  mithuna,
  karka,
  simha,
  kanya,
  tula,
  vrishchika,
  dhanu,
  makara,
  kumbha,
  meena;

  static Rasi fromIndex(int index) => Rasi.values[index % 12];

  /// Sign occupied by [siderealLongitude], in degrees.
  static Rasi fromLongitude(double siderealLongitude) =>
      fromIndex((normaliseDegrees(siderealLongitude) / 30).floor());

  /// Ruling graha. Rahu and Ketu are given no rulership: classical sources do not
  /// agree on one, and inventing it here would silently affect dignity.
  Graha get lord => switch (this) {
        Rasi.mesha || Rasi.vrishchika => Graha.mars,
        Rasi.vrishabha || Rasi.tula => Graha.venus,
        Rasi.mithuna || Rasi.kanya => Graha.mercury,
        Rasi.karka => Graha.moon,
        Rasi.simha => Graha.sun,
        Rasi.dhanu || Rasi.meena => Graha.jupiter,
        Rasi.makara || Rasi.kumbha => Graha.saturn,
      };

  Modality get modality => Modality.values[index % 3];

  /// Odd (vishama) signs are the 1st, 3rd, 5th and so on. Several vargas start
  /// from a different sign depending on this.
  bool get isOdd => index.isEven;

  String get displayName => switch (this) {
        Rasi.mesha => 'Mesha',
        Rasi.vrishabha => 'Vrishabha',
        Rasi.mithuna => 'Mithuna',
        Rasi.karka => 'Karka',
        Rasi.simha => 'Simha',
        Rasi.kanya => 'Kanya',
        Rasi.tula => 'Tula',
        Rasi.vrishchika => 'Vrishchika',
        Rasi.dhanu => 'Dhanu',
        Rasi.makara => 'Makara',
        Rasi.kumbha => 'Kumbha',
        Rasi.meena => 'Meena',
      };
}

/// Wraps [degrees] into the range 0 (inclusive) to 360 (exclusive).
///
/// Every longitude entering a derivation passes through here, so that a value
/// arriving as -0.0000001 or exactly 360.0 cannot produce an off-by-one sign.
double normaliseDegrees(double degrees) {
  final wrapped = degrees % 360;
  return wrapped < 0 ? wrapped + 360 : wrapped;
}

/// Shortest angular separation between two longitudes, 0 to 180 degrees.
double angularSeparation(double a, double b) {
  final diff = (normaliseDegrees(a) - normaliseDegrees(b)).abs();
  return diff > 180 ? 360 - diff : diff;
}
