import 'package:jyotish_engine/jyotish_engine.dart';
import 'package:test/test.dart';

void main() {
  final birth = DateTime.utc(2000, 1, 1);

  group('Starting lord', () {
    test('is the lord of the nakshatra the Moon occupies', () {
      // Moon at 0 degrees is at the start of Ashwini, whose lord is Ketu.
      final periods =
          computeVimshottariDashas(moonSiderealLongitude: 0, birthUtc: birth);
      expect(periods.first.lord, Graha.ketu);

      // 120 degrees is the start of Magha, also Ketu.
      final magha =
          computeVimshottariDashas(moonSiderealLongitude: 120, birthUtc: birth);
      expect(magha.first.lord, Graha.ketu);

      // 13 degrees 20 minutes is the start of Bharani, whose lord is Venus.
      final bharani = computeVimshottariDashas(
        moonSiderealLongitude: 13 + 20 / 60,
        birthUtc: birth,
      );
      expect(bharani.first.lord, Graha.venus);
    });

    test('mahadashas then follow the fixed Vimshottari order', () {
      final periods =
          computeVimshottariDashas(moonSiderealLongitude: 0, birthUtc: birth);
      expect(
        periods.take(9).map((p) => p.lord).toList(),
        vimshottariOrder,
      );
    });
  });

  group('Period boundaries', () {
    test('a Moon at a nakshatra start gives a full mahadasha from birth', () {
      final periods =
          computeVimshottariDashas(moonSiderealLongitude: 0, birthUtc: birth);
      expect(periods.first.start, birth);

      // Ketu's 7 Vimshottari years are 7 x 365.25 = 2556.75 days. Counting from
      // 2000-01-01, seven calendar years is 2557 days (2000 and 2004 are leap), so
      // the period ends a quarter day short of 2007-01-01.
      expect(periods.first.end, DateTime.utc(2006, 12, 31, 18));
    });

    test('a Moon mid-nakshatra starts the cycle before birth', () {
      // Halfway through Ashwini: half of Ketu's 7 years has already elapsed.
      final periods = computeVimshottariDashas(
        moonSiderealLongitude: nakshatraSpan / 2,
        birthUtc: birth,
      );
      final first = periods.first;

      expect(first.lord, Graha.ketu);
      expect(first.start.isBefore(birth), isTrue);
      expect(first.end.isAfter(birth), isTrue);

      // 3.5 Vimshottari years before birth, and 3.5 after.
      const halfKetuDays = 3.5 * 365.25;
      expect(
        birth.difference(first.start).inMinutes,
        closeTo(halfKetuDays * 24 * 60, 1),
      );
      expect(
        first.end.difference(birth).inMinutes,
        closeTo(halfKetuDays * 24 * 60, 1),
      );
    });

    test('consecutive mahadashas meet exactly, with no gap or overlap', () {
      final periods = computeVimshottariDashas(
        moonSiderealLongitude: 187.4,
        birthUtc: birth,
      );
      for (var i = 0; i + 1 < periods.length; i++) {
        expect(periods[i].end, periods[i + 1].start,
            reason: 'between $i and ${i + 1}');
      }
    });

    test('each mahadasha lasts its allotted number of Vimshottari years', () {
      final periods =
          computeVimshottariDashas(moonSiderealLongitude: 0, birthUtc: birth);
      for (final period in periods) {
        final expectedDays =
            vimshottariYears[period.lord]! * vimshottariYearDays;
        final actualDays = period.end.difference(period.start).inMicroseconds /
            Duration.microsecondsPerDay;
        expect(actualDays, closeTo(expectedDays, 1e-6),
            reason: period.lord.name);
      }
    });

    test('one full cycle spans exactly 120 Vimshottari years', () {
      final periods =
          computeVimshottariDashas(moonSiderealLongitude: 0, birthUtc: birth);
      final cycle = periods.take(9);
      final days = cycle.last.end.difference(cycle.first.start).inMicroseconds /
          Duration.microsecondsPerDay;
      expect(days, closeTo(120 * vimshottariYearDays, 1e-6));
    });
  });

  group('Sub-periods', () {
    List<DashaPeriod> periodsFor(int depth) => computeVimshottariDashas(
          moonSiderealLongitude: 47.9,
          birthUtc: birth,
          depth: depth,
        );

    test('depth 1 returns mahadashas only', () {
      for (final period in periodsFor(1)) {
        expect(period.children, isEmpty);
        expect(period.level, 1);
      }
    });

    test('depth 2 adds antardashas but no deeper', () {
      for (final period in periodsFor(2)) {
        expect(period.children, hasLength(9));
        for (final child in period.children) {
          expect(child.level, 2);
          expect(child.children, isEmpty);
        }
      }
    });

    test('depth 3 adds pratyantardashas', () {
      final period = periodsFor(3).first;
      expect(period.children, hasLength(9));
      expect(period.children.first.children, hasLength(9));
      expect(period.children.first.children.first.level, 3);
    });

    test('the first sub-period is always ruled by its parent', () {
      for (final period in periodsFor(3)) {
        expect(period.children.first.lord, period.lord);
        for (final child in period.children) {
          expect(child.children.first.lord, child.lord);
        }
      }
    });

    test('sub-periods tile their parent exactly, with no rounding drift', () {
      // The tightest constraint in the whole computation: a gap of even one
      // microsecond would put a date in no period at all.
      void checkTiling(DashaPeriod parent) {
        if (parent.children.isEmpty) return;
        expect(parent.children.first.start, parent.start,
            reason: 'start of ${parent.lord.name}');
        expect(parent.children.last.end, parent.end,
            reason: 'end of ${parent.lord.name}');
        for (var i = 0; i + 1 < parent.children.length; i++) {
          expect(parent.children[i].end, parent.children[i + 1].start);
        }
        parent.children.forEach(checkTiling);
      }

      periodsFor(3).forEach(checkTiling);
    });

    test('sub-period lengths are proportional to the Vimshottari allotments',
        () {
      final mahadasha = periodsFor(2).first;
      final total = mahadasha.end.difference(mahadasha.start).inMicroseconds;
      for (final child in mahadasha.children) {
        final expected = total * vimshottariYears[child.lord]! / 120;
        final actual = child.end.difference(child.start).inMicroseconds;
        expect(actual, closeTo(expected, 1), reason: child.lord.name);
      }
    });
  });

  group('Coverage', () {
    test('extends at least 120 years past birth by default', () {
      final periods =
          computeVimshottariDashas(moonSiderealLongitude: 0, birthUtc: birth);
      final coverUntil = birth.add(
        Duration(
            microseconds:
                (120 * vimshottariYearDays * Duration.microsecondsPerDay)
                    .round()),
      );
      // A Moon exactly at a nakshatra start needs precisely one cycle, so the
      // final period ends on the coverage boundary rather than past it.
      expect(periods.last.end.isBefore(coverUntil), isFalse);
    });

    test('generates an extra period when the first mahadasha is partly elapsed',
        () {
      // Any elapsed portion pushes the cycle end earlier than birth + 120 years,
      // so a tenth mahadasha is needed to cover the full span.
      final periods = computeVimshottariDashas(
        moonSiderealLongitude: nakshatraSpan / 2,
        birthUtc: birth,
      );
      expect(periods.length, greaterThan(9));
    });

    test('honours a shorter requested coverage', () {
      final periods = computeVimshottariDashas(
        moonSiderealLongitude: 0,
        birthUtc: birth,
        coverageYears: 30,
      );
      // Ketu 7 + Venus 20 + Sun 6 clears 30 years, so three periods suffice.
      expect(periods, hasLength(3));
    });
  });

  group('Active period lookup', () {
    test('returns the chain running at an instant, outermost first', () {
      final periods = computeVimshottariDashas(
        moonSiderealLongitude: nakshatraSpan / 2,
        birthUtc: birth,
        depth: 3,
      );
      final chain = activeDashaChain(periods, birth);

      expect(chain, hasLength(3));
      expect(chain[0].level, 1);
      expect(chain[1].level, 2);
      expect(chain[2].level, 3);
      for (final period in chain) {
        expect(period.containsDate(birth), isTrue);
      }
    });

    test('is empty outside the generated range', () {
      final periods =
          computeVimshottariDashas(moonSiderealLongitude: 0, birthUtc: birth);
      expect(activeDashaChain(periods, DateTime.utc(1800)), isEmpty);
    });

    test('every instant across a mahadasha resolves to a full chain', () {
      final periods = computeVimshottariDashas(
        moonSiderealLongitude: 0,
        birthUtc: birth,
        depth: 3,
      );
      final mahadasha = periods.first;
      final span = mahadasha.end.difference(mahadasha.start);
      for (var i = 0; i < 50; i++) {
        final instant = mahadasha.start.add(span * (i / 50));
        expect(activeDashaChain(periods, instant), hasLength(3),
            reason: '$instant');
      }
    });
  });

  group('Input validation', () {
    test('rejects a depth outside 1 to 3', () {
      expect(
        () => computeVimshottariDashas(
          moonSiderealLongitude: 0,
          birthUtc: birth,
          depth: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => computeVimshottariDashas(
          moonSiderealLongitude: 0,
          birthUtc: birth,
          depth: 4,
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-positive coverage', () {
      expect(
        () => computeVimshottariDashas(
          moonSiderealLongitude: 0,
          birthUtc: birth,
          coverageYears: 0,
        ),
        throwsArgumentError,
      );
    });

    test('normalises a local birth time to UTC', () {
      final local = DateTime.utc(2000, 1, 1).toLocal();
      final fromLocal =
          computeVimshottariDashas(moonSiderealLongitude: 0, birthUtc: local);
      final fromUtc =
          computeVimshottariDashas(moonSiderealLongitude: 0, birthUtc: birth);
      expect(fromLocal.first.start, fromUtc.first.start);
      expect(fromLocal.first.start.isUtc, isTrue);
    });
  });
}
