import 'rasi.dart';

/// Divisional (varga) charts.
///
/// Each varga subdivides every sign into a number of parts and maps each part onto
/// a sign, producing a derived chart used to examine a specific area of life.
enum Varga {
  /// Rasi. The birth chart itself.
  d1(1, 'Rasi'),

  /// Hora. Wealth.
  d2(2, 'Hora'),

  /// Drekkana. Siblings, courage.
  d3(3, 'Drekkana'),

  /// Saptamsha. Children.
  d7(7, 'Saptamsha'),

  /// Navamsa. Marriage, and the underlying strength of the whole chart.
  d9(9, 'Navamsa'),

  /// Dashamsha. Career and professional life.
  d10(10, 'Dashamsha'),

  /// Dwadashamsha. Parents, ancestry.
  d12(12, 'Dwadashamsha');

  const Varga(this.divisions, this.sanskritName);

  final int divisions;
  final String sanskritName;

  /// Width of one division in degrees.
  double get divisionSpan => 30 / divisions;
}

/// Sign a longitude falls into within [varga].
///
/// Sources: Brihat Parashara Hora Shastra, chs. 6-7. The per-varga starting rules
/// are the standard Parashari ones:
///
/// - **D2** odd signs give the Sun's hora (Simha) then the Moon's (Karka); even
///   signs reverse that order.
/// - **D3** the three parts fall in the sign itself, the 5th from it, and the 9th.
/// - **D7** odd signs start from the sign itself, even signs from the 7th.
/// - **D9** movable signs start from themselves, fixed from the 9th, dual from the
///   5th — expressed here as the equivalent closed form `(sign * 9 + part) % 12`.
/// - **D10** odd signs start from the sign itself, even signs from the 9th.
/// - **D12** every sign starts from itself.
Rasi vargaSign(double siderealLongitude, Varga varga) {
  final longitude = normaliseDegrees(siderealLongitude);
  final sign = Rasi.fromLongitude(longitude);
  final part = _divisionIndex(longitude, varga);

  return switch (varga) {
    Varga.d1 => sign,
    Varga.d2 => sign.isOdd
        ? (part == 0 ? Rasi.simha : Rasi.karka)
        : (part == 0 ? Rasi.karka : Rasi.simha),
    Varga.d3 => Rasi.fromIndex(sign.index + part * 4),
    Varga.d7 =>
      Rasi.fromIndex(sign.isOdd ? sign.index + part : sign.index + 6 + part),
    Varga.d9 => Rasi.fromIndex(sign.index * 9 + part),
    Varga.d10 =>
      Rasi.fromIndex(sign.isOdd ? sign.index + part : sign.index + 8 + part),
    Varga.d12 => Rasi.fromIndex(sign.index + part),
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
