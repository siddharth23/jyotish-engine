import 'rasi.dart';

/// Divisional (varga) charts.
///
/// Each varga subdivides every sign into a number of parts and maps each part onto
/// a sign, producing a derived chart used to examine a specific area of life.
///
/// The sixteen members below are the Shodashavarga of Brihat Parashara Hora
/// Shastra ch. 6. The classical subsets are drawn from them: Shadvarga is D1, D2,
/// D3, D9, D12 and D30; Saptavarga adds D7; Dashavarga adds D10, D16 and D60.
enum Varga {
  /// Rasi. The birth chart itself.
  d1(1, 'Rasi'),

  /// Hora. Wealth.
  d2(2, 'Hora'),

  /// Drekkana. Siblings, courage.
  d3(3, 'Drekkana'),

  /// Chaturthamsa. Fortune, property, the home.
  d4(4, 'Chaturthamsa'),

  /// Saptamsha. Children.
  d7(7, 'Saptamsha'),

  /// Navamsa. Marriage, and the underlying strength of the whole chart.
  d9(9, 'Navamsa'),

  /// Dashamsha. Career and professional life.
  d10(10, 'Dashamsha'),

  /// Dwadashamsha. Parents, ancestry.
  d12(12, 'Dwadashamsha'),

  /// Shodashamsa (Kalamsa). Vehicles, comforts, general happiness.
  d16(16, 'Shodashamsa'),

  /// Vimshamsa. Spiritual practice and its results.
  d20(20, 'Vimshamsa'),

  /// Siddhamsa (Chaturvimshamsa). Education and learning.
  d24(24, 'Siddhamsa'),

  /// Bhamsa (Nakshatramsa). Overall strengths and weaknesses.
  d27(27, 'Bhamsa'),

  /// Trimshamsa. Misfortune and affliction. Its parts are **unequal** — see
  /// [vargaSign].
  d30(30, 'Trimshamsa'),

  /// Khavedamsa. Auspicious and inauspicious effects; maternal legacy.
  d40(40, 'Khavedamsa'),

  /// Akshavedamsa. General indications; paternal legacy.
  d45(45, 'Akshavedamsa'),

  /// Shashtiamsa. All matters; the finest division, read for past karma.
  d60(60, 'Shashtiamsa');

  const Varga(this.divisions, this.sanskritName);

  final int divisions;
  final String sanskritName;

  /// Width of one division in degrees.
  ///
  /// Meaningless for [Varga.d30], whose five parts are 5, 5, 8, 7 and 5 degrees
  /// wide. Callers that lay out division boundaries must special-case it.
  double get divisionSpan => 30 / divisions;

  /// Whether every part of this varga has the same width. False only for D30.
  bool get hasEqualDivisions => this != Varga.d30;
}

/// Upper bound of each trimshamsa part in an odd sign, with the sign it maps to.
///
/// Brihat Parashara Hora Shastra ch. 6: Mars 5 degrees, Saturn 5, Jupiter 8,
/// Mercury 7, Venus 5, each mapping to that graha's odd-sign rulership.
const List<(double, Rasi)> _trimshamsaOdd = [
  (5, Rasi.mesha), // Mars
  (10, Rasi.kumbha), // Saturn
  (18, Rasi.dhanu), // Jupiter
  (25, Rasi.mithuna), // Mercury
  (30, Rasi.tula), // Venus
];

/// The same five rulers in reverse for an even sign, mapping to their even-sign
/// rulerships. The widths mirror: 5, 7, 8, 5, 5.
const List<(double, Rasi)> _trimshamsaEven = [
  (5, Rasi.vrishabha), // Venus
  (12, Rasi.kanya), // Mercury
  (20, Rasi.meena), // Jupiter
  (25, Rasi.makara), // Saturn
  (30, Rasi.vrishchika), // Mars
];

/// The trimshamsa part containing [degreeInSign], with the part's own bounds.
///
/// The bounds come back because the part widths differ, so a caller scaling a
/// position to fill a sign cannot assume [Varga.divisionSpan].
({Rasi sign, double start, double end}) _trimshamsaPart(
  double degreeInSign,
  bool isOdd,
) {
  final parts = isOdd ? _trimshamsaOdd : _trimshamsaEven;
  var lower = 0.0;
  for (final (upper, sign) in parts) {
    if (degreeInSign < upper) return (sign: sign, start: lower, end: upper);
    lower = upper;
  }
  // Unreachable: normaliseDegrees keeps the degree under 30 and the last part
  // ends there. The final part is the only consistent answer regardless.
  final (_, sign) = parts.last;
  return (sign: sign, start: parts[parts.length - 2].$1, end: 30);
}

/// Starting sign for the vargas whose rule keys off modality.
int _byModality(
  Rasi sign, {
  required Rasi movable,
  required Rasi fixed,
  required Rasi dual,
}) =>
    switch (sign.modality) {
      Modality.movable => movable.index,
      Modality.fixed => fixed.index,
      Modality.dual => dual.index,
    };

/// Sign a longitude falls into within [varga].
///
/// Sources: Brihat Parashara Hora Shastra, chs. 6-7. The per-varga starting rules
/// are the standard Parashari ones:
///
/// - **D2** odd signs give the Sun's hora (Simha) then the Moon's (Karka); even
///   signs reverse that order.
/// - **D3** the three parts fall in the sign itself, the 5th from it, and the 9th.
/// - **D4** the four parts fall in the sign and the three kendras from it.
/// - **D7** odd signs start from the sign itself, even signs from the 7th.
/// - **D9** movable signs start from themselves, fixed from the 9th, dual from the
///   5th — expressed here as the equivalent closed form `(sign * 9 + part) % 12`.
/// - **D10** odd signs start from the sign itself, even signs from the 9th.
/// - **D12** every sign starts from itself.
/// - **D16** movable from Mesha, fixed from Simha, dual from Dhanu.
/// - **D20** movable from Mesha, fixed from Dhanu, dual from Simha.
/// - **D24** odd signs from Simha, even signs from Karka.
/// - **D27** fiery signs from Mesha, earthy from Karka, airy from Tula, watery
///   from Makara — the element cycles every four signs, hence `(sign % 4) * 3`.
/// - **D30** five unequal parts by planetary rulership; see [_trimshamsaOdd].
/// - **D40** odd signs from Mesha, even signs from Tula.
/// - **D45** movable from Mesha, fixed from Simha, dual from Dhanu.
/// - **D60** every sign starts from itself.
Rasi vargaSign(double siderealLongitude, Varga varga) {
  final longitude = normaliseDegrees(siderealLongitude);
  final sign = Rasi.fromLongitude(longitude);

  // D30 is the one varga without equal parts, so the shared part index that
  // every other rule below depends on does not apply to it.
  if (varga == Varga.d30) {
    return _trimshamsaPart(longitude % 30, sign.isOdd).sign;
  }

  final part = _divisionIndex(longitude, varga);

  return switch (varga) {
    Varga.d1 => sign,
    Varga.d2 => sign.isOdd
        ? (part == 0 ? Rasi.simha : Rasi.karka)
        : (part == 0 ? Rasi.karka : Rasi.simha),
    Varga.d3 => Rasi.fromIndex(sign.index + part * 4),
    Varga.d4 => Rasi.fromIndex(sign.index + part * 3),
    Varga.d7 =>
      Rasi.fromIndex(sign.isOdd ? sign.index + part : sign.index + 6 + part),
    Varga.d9 => Rasi.fromIndex(sign.index * 9 + part),
    Varga.d10 =>
      Rasi.fromIndex(sign.isOdd ? sign.index + part : sign.index + 8 + part),
    Varga.d12 => Rasi.fromIndex(sign.index + part),
    Varga.d16 => Rasi.fromIndex(
        _byModality(sign,
                movable: Rasi.mesha, fixed: Rasi.simha, dual: Rasi.dhanu) +
            part,
      ),
    Varga.d20 => Rasi.fromIndex(
        _byModality(sign,
                movable: Rasi.mesha, fixed: Rasi.dhanu, dual: Rasi.simha) +
            part,
      ),
    Varga.d24 =>
      Rasi.fromIndex((sign.isOdd ? Rasi.simha.index : Rasi.karka.index) + part),
    Varga.d27 => Rasi.fromIndex((sign.index % 4) * 3 + part),
    Varga.d30 => sign, // handled above; the analyser needs the arm
    Varga.d40 =>
      Rasi.fromIndex((sign.isOdd ? Rasi.mesha.index : Rasi.tula.index) + part),
    Varga.d45 => Rasi.fromIndex(
        _byModality(sign,
                movable: Rasi.mesha, fixed: Rasi.simha, dual: Rasi.dhanu) +
            part,
      ),
    Varga.d60 => Rasi.fromIndex(sign.index + part),
  };
}

/// Longitude of a body within its varga sign, as a full 0-360 degree value.
///
/// **Convention.** Only the varga *sign* is classically meaningful; a varga has no
/// canonical longitude. The position within the division is scaled up to fill a
/// whole sign, which preserves ordering and lets the same derivations (nakshatra,
/// pada, house) run over a varga chart. Treat the degree as an engine artefact,
/// not a classical quantity.
double vargaLongitude(double siderealLongitude, Varga varga) {
  final longitude = normaliseDegrees(siderealLongitude);

  // D30 scales against its own part, which may be 5, 7 or 8 degrees wide.
  if (varga == Varga.d30) {
    final degreeInSign = longitude % 30;
    final part =
        _trimshamsaPart(degreeInSign, Rasi.fromLongitude(longitude).isOdd);
    final within = (degreeInSign - part.start) / (part.end - part.start);
    return normaliseDegrees(part.sign.index * 30 + within * 30);
  }

  final position = _divisionPosition(longitude, varga);
  final withinDivision = position - position.floorToDouble();
  return normaliseDegrees(
    vargaSign(longitude, varga).index * 30 + withinDivision * 30,
  );
}

/// Position along the varga's division cycle within the current sign: 0.0 at the
/// sign's start, rising to [Varga.divisions] at its end.
///
/// Multiplication precedes division for the same reason as [nakshatraPosition]:
/// `30 / 7` for the saptamsha is not exactly representable, so dividing by it can
/// place an exact division boundary in the wrong amsha.
double _divisionPosition(double longitude, Varga varga) =>
    (longitude % 30) * varga.divisions / 30;

int _divisionIndex(double longitude, Varga varga) =>
    _divisionPosition(longitude, varga).floor().clamp(0, varga.divisions - 1);
