/// Sidereal ayanamsa systems.
///
/// The ayanamsa is the angular offset between the tropical and sidereal zodiacs.
/// Different traditions use different values; results are not comparable across
/// systems, so the active ayanamsa must always be surfaced to the user.
enum Ayanamsa {
  /// Chitrapaksha. The Indian government standard and the default here.
  lahiri,

  /// B. V. Raman's variant.
  raman,

  /// Krishnamurti Paddhati.
  krishnamurti,

  /// Fagan-Bradley, common in Western sidereal practice.
  faganBradley;

  /// Swiss Ephemeris `SE_SIDM_*` constant for this system.
  int get sweConstant => switch (this) {
        Ayanamsa.lahiri => 1,
        Ayanamsa.raman => 3,
        Ayanamsa.krishnamurti => 5,
        Ayanamsa.faganBradley => 0,
      };

  String get displayName => switch (this) {
        Ayanamsa.lahiri => 'Lahiri (Chitrapaksha)',
        Ayanamsa.raman => 'Raman',
        Ayanamsa.krishnamurti => 'Krishnamurti (KP)',
        Ayanamsa.faganBradley => 'Fagan-Bradley',
      };
}
