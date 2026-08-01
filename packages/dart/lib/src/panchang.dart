import 'package:meta/meta.dart';

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
