import 'package:meta/meta.dart';

import 'planet.dart';

/// A Vimshottari dasha period.
///
/// The Vimshottari cycle spans 120 years and is apportioned between the nine grahas
/// in fixed proportions. The starting point is derived from the Moon's nakshatra at
/// birth, which is why an accurate birth time matters: an error of a few minutes
/// shifts every period boundary.
@immutable
class DashaPeriod {
  const DashaPeriod({
    required this.lord,
    required this.start,
    required this.end,
    required this.level,
    this.children = const [],
  });

  final Graha lord;
  final DateTime start;
  final DateTime end;

  /// 1 = mahadasha, 2 = antardasha, 3 = pratyantardasha.
  final int level;

  final List<DashaPeriod> children;

  bool containsDate(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  Map<String, Object?> toJson() => {
        'lord': lord.name,
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
        'level': level,
        if (children.isNotEmpty) 'children': [for (final c in children) c.toJson()],
      };
}

/// Years allotted to each graha in the 120-year Vimshottari cycle.
const Map<Graha, int> vimshottariYears = {
  Graha.ketu: 7,
  Graha.venus: 20,
  Graha.sun: 6,
  Graha.moon: 10,
  Graha.mars: 7,
  Graha.rahu: 18,
  Graha.jupiter: 16,
  Graha.saturn: 19,
  Graha.mercury: 17,
};

/// Order in which dasha lords succeed one another. Fixed and cyclic.
const List<Graha> vimshottariOrder = [
  Graha.ketu,
  Graha.venus,
  Graha.sun,
  Graha.moon,
  Graha.mars,
  Graha.rahu,
  Graha.jupiter,
  Graha.saturn,
  Graha.mercury,
];
