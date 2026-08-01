import 'package:meta/meta.dart';

import 'planet.dart';
import 'rasi.dart';

/// A single body's raw astronomical position, exactly as Swiss Ephemeris reports it.
///
/// Nothing here is derived. Sign, nakshatra, pada, house, dignity and combustion are
/// all computed from these values by the assembler.
@immutable
class RawBodyPosition {
  const RawBodyPosition({
    required this.graha,
    required this.siderealLongitude,
    required this.latitude,
    required this.speed,
  });

  final Graha graha;

  /// Sidereal ecliptic longitude in degrees, with the ayanamsa already applied.
  final double siderealLongitude;

  /// Ecliptic latitude in degrees.
  final double latitude;

  /// Longitudinal speed in degrees per day. Negative indicates retrograde motion.
  final double speed;
}

/// Everything the engine needs from Swiss Ephemeris, and nothing it can derive itself.
///
/// This type is the seam between the two halves of the engine:
///
/// - **Ephemeris half** — planetary longitudes, the ayanamsa value, the ascendant and
///   quadrant house cusps. Requires the native Swiss Ephemeris library, and therefore
///   the FFI or WebAssembly build.
/// - **Derivation half** — signs, nakshatras, padas, houses, dignity, combustion,
///   vargas and dashas. Pure arithmetic over the values above, identical on every
///   platform, and testable without any native code.
///
/// Keeping the seam explicit is what makes the cross-platform equality requirement
/// tractable: the FFI and WASM builds need only agree on this struct, after which the
/// derived output follows deterministically.
@immutable
class RawEphemeris {
  const RawEphemeris({
    required this.bodies,
    required this.ascendant,
    required this.ayanamsaValue,
    this.houseCusps,
  });

  final List<RawBodyPosition> bodies;

  /// Sidereal longitude of the ascendant in degrees.
  final double ascendant;

  /// The ayanamsa applied, in degrees.
  final double ayanamsaValue;

  /// Twelve cusps from `swe_houses`, required only for Placidus and Koch. Whole sign
  /// and equal cusps are derived, so this may be null for them.
  final List<double>? houseCusps;

  /// Position of [graha], or null if the ephemeris did not supply it.
  RawBodyPosition? operator [](Graha graha) {
    for (final body in bodies) {
      if (body.graha == graha) return body;
    }
    return null;
  }

  /// Returns a copy with Ketu derived from Rahu if Ketu is absent.
  ///
  /// The nodes are always exactly opposite one another, so an ephemeris that reports
  /// only Rahu carries enough information for both. Latitude is zeroed and speed is
  /// mirrored, matching how the nodes are conventionally reported.
  RawEphemeris withDerivedKetu() {
    if (this[Graha.ketu] != null) return this;
    final rahu = this[Graha.rahu];
    if (rahu == null) return this;

    return RawEphemeris(
      bodies: [
        ...bodies,
        RawBodyPosition(
          graha: Graha.ketu,
          siderealLongitude: normaliseDegrees(rahu.siderealLongitude + 180),
          latitude: 0,
          speed: rahu.speed,
        ),
      ],
      ascendant: ascendant,
      ayanamsaValue: ayanamsaValue,
      houseCusps: houseCusps,
    );
  }
}
