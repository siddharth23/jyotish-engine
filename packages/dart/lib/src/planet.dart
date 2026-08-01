import 'package:meta/meta.dart';

/// The nine grahas of Jyotish.
///
/// Rahu and Ketu are the lunar nodes, not physical bodies; they are always exactly
/// 180 degrees apart and are conventionally treated as permanently retrograde.
enum Graha {
  sun,
  moon,
  mars,
  mercury,
  jupiter,
  venus,
  saturn,
  rahu,
  ketu;

  bool get isLuminary => this == Graha.sun || this == Graha.moon;
  bool get isShadow => this == Graha.rahu || this == Graha.ketu;
}

/// Dignity of a graha by sign placement.
enum Dignity { exalted, ownSign, friendly, neutral, inimical, debilitated }

/// A computed position for a single graha.
@immutable
class GrahaPosition {
  const GrahaPosition({
    required this.graha,
    required this.siderealLongitude,
    required this.latitude,
    required this.speed,
    required this.sign,
    required this.degreeInSign,
    required this.nakshatra,
    required this.pada,
    required this.house,
    required this.dignity,
    required this.isRetrograde,
    required this.isCombust,
  });

  final Graha graha;

  /// Sidereal ecliptic longitude in degrees, 0 to 360.
  final double siderealLongitude;

  /// Ecliptic latitude in degrees.
  final double latitude;

  /// Longitudinal speed in degrees per day. Negative indicates retrograde motion.
  final double speed;

  /// Rasi index, 0 = Mesha (Aries) through 11 = Meena (Pisces).
  final int sign;

  /// Degrees within the sign, 0 to 30.
  final double degreeInSign;

  /// Nakshatra index, 0 = Ashwini through 26 = Revati.
  final int nakshatra;

  /// Pada within the nakshatra, 1 to 4.
  final int pada;

  /// House number, 1 to 12.
  final int house;

  final Dignity dignity;
  final bool isRetrograde;

  /// Too close to the Sun to be visible; traditionally weakens the graha.
  final bool isCombust;

  Map<String, Object?> toJson() => {
        'graha': graha.name,
        'siderealLongitude': siderealLongitude,
        'latitude': latitude,
        'speed': speed,
        'sign': sign,
        'degreeInSign': degreeInSign,
        'nakshatra': nakshatra,
        'pada': pada,
        'house': house,
        'dignity': dignity.name,
        'isRetrograde': isRetrograde,
        'isCombust': isCombust,
      };
}
