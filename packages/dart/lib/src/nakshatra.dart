import 'dasha.dart';
import 'planet.dart';
import 'rasi.dart';

/// Number of nakshatras in the zodiac.
const int nakshatraCount = 27;

/// Padas per nakshatra.
const int padasPerNakshatra = 4;

/// Width of one nakshatra in degrees: 360 / 27, or 13 degrees 20 minutes.
const double nakshatraSpan = 360 / nakshatraCount;

/// Width of one pada in degrees: 360 / 108, or 3 degrees 20 minutes.
const double padaSpan = nakshatraSpan / padasPerNakshatra;

/// Position along the nakshatra cycle: 0.0 at 0 Aries, rising to 27.0 after a full
/// circle. The integer part is the nakshatra index, the fraction is how far through
/// it the longitude sits.
///
/// Deliberately computed as `longitude * 27 / 360` rather than
/// `longitude / (360 / 27)`. The divisor 360/27 is not exactly representable in
/// binary floating point, so dividing by it can place an exact boundary longitude on
/// the wrong side. Multiplying first keeps every boundary that is a whole number of
/// degrees exact. A single index slip here changes the Vimshottari starting lord and
/// therefore every dasha date the engine produces.
double nakshatraPosition(double siderealLongitude) =>
    normaliseDegrees(siderealLongitude) * nakshatraCount / 360;

/// The 27 nakshatras, in zodiacal order from Ashwini at 0 degrees sidereal.
///
/// Each spans 13 degrees 20 minutes and is divided into four padas of 3 degrees
/// 20 minutes. The Moon's nakshatra at birth determines the Vimshottari starting
/// dasha, which is why this derivation sits on the critical path for accuracy.
enum Nakshatra {
  ashwini,
  bharani,
  krittika,
  rohini,
  mrigashira,
  ardra,
  punarvasu,
  pushya,
  ashlesha,
  magha,
  purvaPhalguni,
  uttaraPhalguni,
  hasta,
  chitra,
  swati,
  vishakha,
  anuradha,
  jyeshtha,
  mula,
  purvaAshadha,
  uttaraAshadha,
  shravana,
  dhanishta,
  shatabhisha,
  purvaBhadrapada,
  uttaraBhadrapada,
  revati;

  static Nakshatra fromIndex(int index) =>
      Nakshatra.values[index % nakshatraCount];

  /// Nakshatra occupied by [siderealLongitude], in degrees.
  static Nakshatra fromLongitude(double siderealLongitude) =>
      fromIndex(nakshatraPosition(siderealLongitude).floor());

  /// Vimshottari dasha lord. The nine lords repeat in fixed order across the 27
  /// nakshatras, so this is derived rather than tabulated.
  Graha get lord => vimshottariOrder[index % 9];
}

/// Pada (quarter) of the nakshatra occupied by [siderealLongitude], 1 to 4.
int padaOfLongitude(double siderealLongitude) {
  final withinNakshatra = nakshatraElapsedFraction(siderealLongitude);
  return (withinNakshatra * padasPerNakshatra).floor().clamp(0, 3) + 1;
}

/// Fraction of the current nakshatra already traversed at [siderealLongitude],
/// from 0.0 at its start to just under 1.0 at its end.
///
/// This is the balance-of-dasha input: the remaining fraction scales the first
/// mahadasha.
double nakshatraElapsedFraction(double siderealLongitude) {
  final position = nakshatraPosition(siderealLongitude);
  return position - position.floorToDouble();
}
