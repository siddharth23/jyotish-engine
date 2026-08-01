import 'package:meta/meta.dart';

import 'nakshatra.dart';
import 'rasi.dart';

/// Width of one tithi in degrees of elongation: 360 / 30.
const double tithiSpan = 12;

/// Width of one karana in degrees of elongation: half a tithi.
const double karanaSpan = tithiSpan / 2;

/// The two halves of the lunar month.
enum Paksha { shukla, krishna }

/// The 27 yogas, formed from the sum of the Sun's and Moon's longitudes.
enum Yoga {
  vishkambha,
  priti,
  ayushman,
  saubhagya,
  shobhana,
  atiganda,
  sukarman,
  dhriti,
  shula,
  ganda,
  vriddhi,
  dhruva,
  vyaghata,
  harshana,
  vajra,
  siddhi,
  vyatipata,
  variyana,
  parigha,
  shiva,
  siddha,
  sadhya,
  shubha,
  shukla,
  brahma,
  indra,
  vaidhriti;

  static Yoga fromIndex(int index) => Yoga.values[index % 27];
}

/// The 11 karanas: seven that repeat through the month and four that occur once.
enum Karana {
  bava,
  balava,
  kaulava,
  taitila,
  gara,
  vanija,
  vishti,
  shakuni,
  chatushpada,
  naga,
  kimstughna;

  /// Whether this karana repeats through the month (chara) or occurs once (sthira).
  bool get isMovable => index < 7;
}

/// The seven repeating karanas, in order.
const List<Karana> movableKaranas = [
  Karana.bava,
  Karana.balava,
  Karana.kaulava,
  Karana.taitila,
  Karana.gara,
  Karana.vanija,
  Karana.vishti,
];

/// Elongation of the Moon from the Sun, 0 to 360 degrees.
///
/// This single quantity determines the tithi and the karana, and is 0 at the new
/// moon and 180 at the full moon.
double elongation(double sunLongitude, double moonLongitude) =>
    normaliseDegrees(moonLongitude - sunLongitude);

/// Tithi (lunar day) number, 1 to 30.
///
/// Each tithi spans 12 degrees of elongation. Tithi 15 ends at the full moon and
/// tithi 30 at the new moon.
int tithiOf(double sunLongitude, double moonLongitude) =>
    (elongation(sunLongitude, moonLongitude) * 30 / 360).floor() + 1;

/// Fraction of the current tithi already elapsed, 0.0 to just under 1.0.
double tithiElapsedFraction(double sunLongitude, double moonLongitude) {
  final position = elongation(sunLongitude, moonLongitude) * 30 / 360;
  return position - position.floorToDouble();
}

/// Which half of the lunar month a tithi falls in.
///
/// Tithis 1 to 15 are the waxing (shukla) half, 16 to 30 the waning (krishna) half.
Paksha pakshaOf(int tithi) => tithi <= 15 ? Paksha.shukla : Paksha.krishna;

/// Yoga formed by the Sun and Moon.
///
/// Computed from the *sum* of the two longitudes, unlike the tithi which uses the
/// difference. Each yoga spans the same 13 degrees 20 minutes as a nakshatra.
Yoga yogaOf(double sunLongitude, double moonLongitude) {
  final sum = normaliseDegrees(sunLongitude + moonLongitude);
  return Yoga.fromIndex((sum * nakshatraCount / 360).floor());
}

/// Karana, the half-tithi.
///
/// There are 60 karana positions in a lunar month filled by 11 named karanas: the
/// first position is Kimstughna, the next 56 are the seven movable karanas repeating
/// eight times, and the last three are Shakuni, Chatushpada and Naga.
Karana karanaOf(double sunLongitude, double moonLongitude) {
  final position = karanaPosition(sunLongitude, moonLongitude);
  if (position == 0) return Karana.kimstughna;
  if (position <= 56) return movableKaranas[(position - 1) % 7];
  return switch (position) {
    57 => Karana.shakuni,
    58 => Karana.chatushpada,
    _ => Karana.naga,
  };
}

/// Index of the current karana within the lunar month, 0 to 59.
int karanaPosition(double sunLongitude, double moonLongitude) =>
    (elongation(sunLongitude, moonLongitude) * 60 / 360).floor().clamp(0, 59);

/// Weekday (vara) at [instant], where the day begins at [sunrise] rather than at
/// midnight.
///
/// Hindu reckoning starts the day at sunrise, so an instant before sunrise belongs
/// to the previous weekday. Sunrise itself is ephemeris-derived, which is why it is
/// a parameter rather than something computed here.
///
/// Returns 0 for Sunday through 6 for Saturday.
int varaOf(DateTime instant, DateTime sunrise) {
  final utc = instant.toUtc();
  final reference = utc.isBefore(sunrise.toUtc())
      ? utc.subtract(const Duration(days: 1))
      : utc;
  // DateTime.weekday is 1 for Monday through 7 for Sunday.
  return reference.weekday % 7;
}

/// The five limbs of the Hindu calendar for a given date and place.
@immutable
class Panchang {
  const Panchang({
    required this.tithi,
    required this.nakshatra,
    required this.yoga,
    required this.karana,
    required this.vara,
    required this.sunrise,
    required this.sunset,
  });

  /// Assembles a panchang from Sun and Moon longitudes.
  ///
  /// The four limbs derived from the two longitudes — tithi, nakshatra, yoga and
  /// karana — are computed here. The weekday depends on sunrise and sunrise itself
  /// is ephemeris-derived, so both are supplied by the caller.
  ///
  /// [sunrise] and [sunset] are null above the polar circles when the Sun does not
  /// cross the horizon; [vara] then falls back to the UTC weekday, which is the only
  /// answer available when there is no sunrise to reckon from.
  factory Panchang.fromLongitudes({
    required DateTime instant,
    required double sunLongitude,
    required double moonLongitude,
    DateTime? sunrise,
    DateTime? sunset,
  }) {
    return Panchang(
      tithi: tithiOf(sunLongitude, moonLongitude),
      nakshatra: Nakshatra.fromLongitude(moonLongitude).index,
      yoga: yogaOf(sunLongitude, moonLongitude).index,
      karana: karanaOf(sunLongitude, moonLongitude).index,
      vara: sunrise == null
          ? instant.toUtc().weekday % 7
          : varaOf(instant, sunrise),
      sunrise: sunrise,
      sunset: sunset,
    );
  }

  /// Lunar day, 1 to 30.
  final int tithi;

  /// Nakshatra index, 0 to 26.
  final int nakshatra;

  /// Yoga index, 0 to 26.
  final int yoga;

  /// Karana index, 0 to 10.
  final int karana;

  /// Weekday, 0 = Sunday.
  final int vara;

  /// Null above the polar circles when the Sun does not cross the horizon.
  final DateTime? sunrise;
  final DateTime? sunset;

  /// Which half of the lunar month this tithi falls in.
  Paksha get paksha => pakshaOf(tithi);

  Map<String, Object?> toJson() => {
        'tithi': tithi,
        'nakshatra': nakshatra,
        'yoga': yoga,
        'karana': karana,
        'vara': vara,
        'sunrise': sunrise?.toUtc().toIso8601String(),
        'sunset': sunset?.toUtc().toIso8601String(),
      };
}
