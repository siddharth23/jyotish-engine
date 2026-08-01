import 'planet.dart';
import 'rasi.dart';

/// Deep exaltation point of a graha: the sign it is exalted in, and the degree
/// within that sign at which exaltation is exact.
///
/// Source: Brihat Parashara Hora Shastra, ch. 3. The seven classical grahas only.
/// Rahu and Ketu are deliberately absent — sources disagree (Taurus/Gemini for
/// Rahu, Scorpio/Sagittarius for Ketu) and picking one silently would change
/// every chart's dignity output with no citable basis.
class ExaltationPoint {
  const ExaltationPoint(this.sign, this.degree);

  final Rasi sign;
  final double degree;

  /// Debilitation is exactly opposite the exaltation point.
  Rasi get debilitationSign => Rasi.fromIndex(sign.index + 6);
}

const Map<Graha, ExaltationPoint> exaltationPoints = {
  Graha.sun: ExaltationPoint(Rasi.mesha, 10),
  Graha.moon: ExaltationPoint(Rasi.vrishabha, 3),
  Graha.mars: ExaltationPoint(Rasi.makara, 28),
  Graha.mercury: ExaltationPoint(Rasi.kanya, 15),
  Graha.jupiter: ExaltationPoint(Rasi.karka, 5),
  Graha.venus: ExaltationPoint(Rasi.meena, 27),
  Graha.saturn: ExaltationPoint(Rasi.tula, 20),
};

/// Natural (naisargika) friendship between grahas.
///
/// Source: Brihat Parashara Hora Shastra, ch. 3. Any graha not listed as a friend
/// or an enemy of a given graha is neutral to it. Rahu and Ketu are absent for the
/// same reason as above.
const Map<Graha, Set<Graha>> naturalFriends = {
  Graha.sun: {Graha.moon, Graha.mars, Graha.jupiter},
  Graha.moon: {Graha.sun, Graha.mercury},
  Graha.mars: {Graha.sun, Graha.moon, Graha.jupiter},
  Graha.mercury: {Graha.sun, Graha.venus},
  Graha.jupiter: {Graha.sun, Graha.moon, Graha.mars},
  Graha.venus: {Graha.mercury, Graha.saturn},
  Graha.saturn: {Graha.mercury, Graha.venus},
};

const Map<Graha, Set<Graha>> naturalEnemies = {
  Graha.sun: {Graha.venus, Graha.saturn},
  Graha.moon: {},
  Graha.mars: {Graha.mercury},
  Graha.mercury: {Graha.moon},
  Graha.jupiter: {Graha.mercury, Graha.venus},
  Graha.venus: {Graha.sun, Graha.moon},
  Graha.saturn: {Graha.sun, Graha.moon, Graha.mars},
};

/// Dignity of [graha] placed in [sign].
///
/// Evaluated in the classical order of precedence: exaltation, debilitation, own
/// sign, then natural relationship with the sign's lord.
///
/// Rahu and Ketu always return [Dignity.neutral]: they rule no sign and have no
/// agreed friendship table, so any other answer would be invented.
Dignity dignityOf(Graha graha, Rasi sign) {
  if (graha.isShadow) return Dignity.neutral;

  final exaltation = exaltationPoints[graha];
  if (exaltation != null) {
    if (exaltation.sign == sign) return Dignity.exalted;
    if (exaltation.debilitationSign == sign) return Dignity.debilitated;
  }

  if (sign.lord == graha) return Dignity.ownSign;

  final dispositor = sign.lord;
  if (naturalFriends[graha]?.contains(dispositor) ?? false) {
    return Dignity.friendly;
  }
  if (naturalEnemies[graha]?.contains(dispositor) ?? false) {
    return Dignity.inimical;
  }
  return Dignity.neutral;
}

/// Longitudinal orb within which a graha is considered combust (asta), in degrees.
///
/// Retrograde Mercury and Venus use a tighter orb. These are the values in common
/// Parashari practice; sources vary by a degree or two, so they are tabulated here
/// rather than buried in the combustion check.
double combustionOrb(Graha graha, {required bool isRetrograde}) =>
    switch (graha) {
      Graha.moon => 12,
      Graha.mars => 17,
      Graha.mercury => isRetrograde ? 12 : 14,
      Graha.jupiter => 11,
      Graha.venus => isRetrograde ? 8 : 10,
      Graha.saturn => 15,
      Graha.sun || Graha.rahu || Graha.ketu => 0,
    };

/// Whether [graha] at [longitude] is combust given the Sun at [sunLongitude].
///
/// The Sun cannot be combust itself, and the nodes are not physical bodies so the
/// concept does not apply to them.
bool isCombust(
  Graha graha,
  double longitude,
  double sunLongitude, {
  required bool isRetrograde,
}) {
  if (graha == Graha.sun || graha.isShadow) return false;
  final orb = combustionOrb(graha, isRetrograde: isRetrograde);
  return angularSeparation(longitude, sunLongitude) <= orb;
}
