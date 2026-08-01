import 'dasha.dart';
import 'nakshatra.dart';
import 'planet.dart';

/// Days in a Vimshottari year.
///
/// **This constant defines every period boundary the engine produces.** The 120-year
/// cycle is conventionally reckoned in Julian years of 365.25 days, which is what
/// mainstream Jyotish software uses. Some traditions use a 360-day savana year
/// instead, which shifts boundaries by years over a full cycle.
///
/// Changing this changes every dasha date the engine has ever produced, so it must
/// come with an `engineVersion` increment.
const double vimshottariYearDays = 365.25;

/// Total years in one Vimshottari cycle.
const int vimshottariCycleYears = 120;

int _yearsToMicroseconds(num years) =>
    (years * vimshottariYearDays * Duration.microsecondsPerDay).round();

/// Computes the Vimshottari dasha tree.
///
/// The cycle's starting point is the Vimshottari lord of the nakshatra occupied by
/// the Moon at birth, and the portion of that nakshatra already traversed gives the
/// portion of that lord's mahadasha already elapsed. A few minutes of error in the
/// birth time moves every boundary in the tree, which is why birth-time accuracy
/// matters more here than anywhere else in the engine.
///
/// [depth] 1 returns mahadashas only, 2 adds antardashas, 3 adds pratyantardashas.
///
/// **Period boundaries are true, not clipped to birth.** The first mahadasha starts
/// before the birth moment, because the native is born partway through it. Clipping
/// it to the birth instant would misplace every antardasha inside it. Consumers that
/// want to display "balance at birth" should filter the returned tree rather than ask
/// for different arithmetic.
///
/// Periods are generated until they cover [coverageYears] beyond the birth moment.
List<DashaPeriod> computeVimshottariDashas({
  required double moonSiderealLongitude,
  required DateTime birthUtc,
  int depth = 3,
  // Defaults to one full cycle, [vimshottariCycleYears]; a literal is required
  // here because a const default cannot call a method.
  double coverageYears = 120,
}) {
  if (depth < 1 || depth > 3) {
    throw ArgumentError.value(depth, 'depth', 'Must be 1, 2 or 3.');
  }
  if (coverageYears <= 0) {
    throw ArgumentError.value(
        coverageYears, 'coverageYears', 'Must be positive.');
  }

  final nakshatra = Nakshatra.fromLongitude(moonSiderealLongitude);
  final elapsedFraction = nakshatraElapsedFraction(moonSiderealLongitude);
  final startLord = nakshatra.lord;

  final birthMicros = birthUtc.toUtc().microsecondsSinceEpoch;
  final elapsedMicros =
      _yearsToMicroseconds(vimshottariYears[startLord]! * elapsedFraction);
  final coverUntilMicros = birthMicros + _yearsToMicroseconds(coverageYears);

  final periods = <DashaPeriod>[];
  var cursorMicros = birthMicros - elapsedMicros;
  var lordIndex = vimshottariOrder.indexOf(startLord);

  while (cursorMicros < coverUntilMicros) {
    final lord = vimshottariOrder[lordIndex % 9];
    final durationMicros = _yearsToMicroseconds(vimshottariYears[lord]!);

    periods.add(
      DashaPeriod(
        lord: lord,
        start: _utc(cursorMicros),
        end: _utc(cursorMicros + durationMicros),
        level: 1,
        children: _subdivide(
          lord: lord,
          startMicros: cursorMicros,
          durationMicros: durationMicros,
          level: 2,
          maxLevel: depth,
        ),
      ),
    );

    cursorMicros += durationMicros;
    lordIndex++;
  }

  return periods;
}

/// Subdivides a period into the nine sub-periods proportional to the Vimshottari
/// allotments, beginning with the parent's own lord.
///
/// Boundaries are computed as cumulative offsets from the parent's start rather than
/// by summing individual durations, so that the children exactly tile the parent with
/// no rounding gap at either end.
List<DashaPeriod> _subdivide({
  required Graha lord,
  required int startMicros,
  required int durationMicros,
  required int level,
  required int maxLevel,
}) {
  if (level > maxLevel) return const [];

  final periods = <DashaPeriod>[];
  final lordIndex = vimshottariOrder.indexOf(lord);
  var cumulativeYears = 0;

  for (var i = 0; i < 9; i++) {
    final subLord = vimshottariOrder[(lordIndex + i) % 9];
    final subStart = startMicros + _proportion(durationMicros, cumulativeYears);
    cumulativeYears += vimshottariYears[subLord]!;
    final subEnd = startMicros + _proportion(durationMicros, cumulativeYears);

    periods.add(
      DashaPeriod(
        lord: subLord,
        start: _utc(subStart),
        end: _utc(subEnd),
        level: level,
        children: _subdivide(
          lord: subLord,
          startMicros: subStart,
          durationMicros: subEnd - subStart,
          level: level + 1,
          maxLevel: maxLevel,
        ),
      ),
    );
  }

  return periods;
}

int _proportion(int durationMicros, int cumulativeYears) =>
    (durationMicros * cumulativeYears / vimshottariCycleYears).round();

DateTime _utc(int micros) =>
    DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);

/// The chain of periods running at [instant], outermost first.
///
/// Returns mahadasha, then antardasha, then pratyantardasha, as deep as the tree was
/// built. Empty if [instant] falls outside the generated range.
List<DashaPeriod> activeDashaChain(
    List<DashaPeriod> periods, DateTime instant) {
  final utc = instant.toUtc();
  for (final period in periods) {
    if (period.containsDate(utc)) {
      return [period, ...activeDashaChain(period.children, utc)];
    }
  }
  return const [];
}
