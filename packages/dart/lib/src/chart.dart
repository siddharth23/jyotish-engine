import 'package:meta/meta.dart';

import 'ayanamsa.dart';
import 'divisional.dart';
import 'house_system.dart';
import 'planet.dart';

/// Input specification for a chart computation.
///
/// [utcDateTime] must already be UTC. Converting local birth time to UTC is the
/// caller's responsibility and is the most common source of error in astrology
/// software: the offset must be resolved from the IANA database using both the
/// coordinates and the historical date. See `docs/ARCHITECTURE.md`.
@immutable
class BirthData {
  const BirthData({
    required this.utcDateTime,
    required this.latitude,
    required this.longitude,
    this.ayanamsa = Ayanamsa.lahiri,
    this.houseSystem = HouseSystem.wholeSign,
    this.useTrueNode = false,
  });

  final DateTime utcDateTime;
  final double latitude;
  final double longitude;
  final Ayanamsa ayanamsa;
  final HouseSystem houseSystem;

  /// True node uses the osculating lunar node; mean node uses the averaged value.
  /// Classical practice generally assumes the mean node.
  final bool useTrueNode;

  Map<String, Object?> toJson() => {
        'utcDateTime': utcDateTime.toUtc().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'ayanamsa': ayanamsa.name,
        'houseSystem': houseSystem.name,
        'useTrueNode': useTrueNode,
      };
}

/// A computed rasi (D1) chart.
@immutable
class Chart {
  const Chart({
    required this.input,
    required this.ascendant,
    required this.ascendantSign,
    required this.houseCusps,
    required this.positions,
    required this.ayanamsaValue,
    required this.engineVersion,
    this.varga = Varga.d1,
  });

  final BirthData input;

  /// Which divisional chart this is. D1 is the rasi chart itself.
  final Varga varga;

  /// Sidereal longitude of the ascendant in degrees.
  final double ascendant;

  /// Rasi index of the ascendant, 0 to 11.
  final int ascendantSign;

  /// Twelve house cusps in sidereal degrees.
  final List<double> houseCusps;

  final Map<Graha, GrahaPosition> positions;

  /// The ayanamsa value applied, in degrees. Surfaced for transparency.
  final double ayanamsaValue;

  /// Engine version that produced this chart. Required for reproducibility.
  final String engineVersion;

  Map<String, Object?> toJson() => {
        'input': input.toJson(),
        'varga': varga.name,
        'ascendant': ascendant,
        'ascendantSign': ascendantSign,
        'houseCusps': houseCusps,
        'positions': {
          for (final graha in Graha.values)
            if (positions[graha] case final position?)
              graha.name: position.toJson(),
        },
        'ayanamsaValue': ayanamsaValue,
        'engineVersion': engineVersion,
      };
}
