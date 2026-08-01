/// Supported house systems.
///
/// Whole sign is the default: it is the system assumed by most classical Jyotish
/// texts, and unlike quadrant systems it remains well-defined at high latitudes.
enum HouseSystem {
  wholeSign,
  equal,
  placidus,
  koch;

  /// Swiss Ephemeris single-character house system code.
  String get sweCode => switch (this) {
        HouseSystem.wholeSign => 'W',
        HouseSystem.equal => 'E',
        HouseSystem.placidus => 'P',
        HouseSystem.koch => 'K',
      };

  /// Quadrant systems degenerate near the poles and must not be offered there.
  bool get isReliableAtHighLatitude => switch (this) {
        HouseSystem.wholeSign || HouseSystem.equal => true,
        HouseSystem.placidus || HouseSystem.koch => false,
      };
}
