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
}
