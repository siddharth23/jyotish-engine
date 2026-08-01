import 'package:jyotish_engine/jyotish_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Whole sign cusps', () {
    test('begin at the ascendant\'s sign and run in zodiacal order', () {
      final cusps = wholeSignCusps(Rasi.simha);
      expect(cusps.first, 120); // 0 Leo
      expect(cusps[1], 150); // 0 Virgo
      expect(cusps.last, 90); // 0 Cancer, the twelfth
      expect(cusps.length, 12);
    });

    test('are always exact sign boundaries regardless of ascendant degree', () {
      for (final sign in Rasi.values) {
        for (final cusp in wholeSignCusps(sign)) {
          expect(cusp % 30, 0, reason: sign.name);
        }
      }
    });
  });

  group('Whole sign house assignment', () {
    test('the ascendant\'s whole sign is the first house', () {
      final cusps = wholeSignCusps(Rasi.simha);
      expect(houseOfLongitude(120, cusps), 1); // 0 Leo
      expect(houseOfLongitude(149.99, cusps), 1); // 29 Leo
    });

    test('counts forward from the ascendant sign', () {
      final cusps = wholeSignCusps(Rasi.simha);
      expect(houseOfLongitude(150, cusps), 2); // Virgo
      expect(houseOfLongitude(0, cusps), 9); // Aries
      expect(houseOfLongitude(90, cusps), 12); // Cancer
    });

    test(
        'places a body in the ascendant sign in the first house even when it '
        'sits below the ascendant degree', () {
      // The defining difference from equal houses: whole sign ignores the degree.
      final cusps = wholeSignCusps(Rasi.simha);
      expect(houseOfLongitude(121, cusps), 1);
    });
  });

  group('Equal house assignment', () {
    test('measures 30 degree houses from the ascendant degree itself', () {
      final cusps = equalCusps(135); // 15 Leo
      expect(houseOfLongitude(135, cusps), 1);
      expect(houseOfLongitude(164.99, cusps), 1);
      expect(houseOfLongitude(165, cusps), 2);
      expect(houseOfLongitude(134.99, cusps), 12);
    });

    test('differs from whole sign for a body below the ascendant degree', () {
      const ascendant = 135.0; // 15 Leo
      final equal = equalCusps(ascendant);
      final wholeSign = wholeSignCusps(Rasi.fromLongitude(ascendant));
      const body = 121.0; // 1 Leo, below the ascendant

      expect(houseOfLongitude(body, wholeSign), 1);
      expect(houseOfLongitude(body, equal), 12);
    });
  });

  group('Wrapping across 0 degrees', () {
    test('assigns correctly when a house spans the zodiac start', () {
      final cusps = equalCusps(350);
      expect(houseOfLongitude(350, cusps), 1);
      expect(houseOfLongitude(355, cusps), 1);
      expect(houseOfLongitude(5, cusps), 1); // still inside 350 to 20
      expect(houseOfLongitude(19.99, cusps), 1);
      expect(houseOfLongitude(20, cusps), 2);
    });

    test('every longitude lands in exactly one house', () {
      final cusps = equalCusps(217.3);
      final counts = <int, int>{};
      for (var tenth = 0; tenth < 3600; tenth++) {
        final house = houseOfLongitude(tenth / 10, cusps);
        expect(house, inInclusiveRange(1, 12));
        counts[house] = (counts[house] ?? 0) + 1;
      }
      expect(counts.length, 12);
      // Equal houses are the same width, so each takes the same share of the
      // 3600 samples. The cusps sit on a fractional degree, so a sample landing
      // exactly on a boundary may fall either side; allow one either way.
      for (final entry in counts.entries) {
        expect(entry.value, closeTo(300, 1), reason: 'house ${entry.key}');
      }
    });
  });

  group('Unequal cusps', () {
    test('handles houses of differing widths, as quadrant systems produce', () {
      // A deliberately uneven but valid set covering the circle.
      final cusps = <double>[
        0,
        20,
        50,
        90,
        130,
        160,
        180,
        200,
        230,
        270,
        310,
        340
      ];
      expect(houseOfLongitude(10, cusps), 1);
      expect(houseOfLongitude(25, cusps), 2);
      expect(houseOfLongitude(89, cusps), 3);
      expect(houseOfLongitude(350, cusps), 12);
    });
  });

  group('Failure modes', () {
    test('rejects a cusp list that is not twelve long', () {
      expect(() => houseOfLongitude(10, [0, 30, 60]), throwsArgumentError);
    });

    test('throws rather than guessing when cusps do not cover the circle', () {
      // A degenerate set, as a quadrant system yields at extreme latitude.
      final degenerate = List<double>.filled(12, 100);
      expect(() => houseOfLongitude(10, degenerate), throwsStateError);
    });

    test('refuses to derive Placidus or Koch cusps without an ephemeris', () {
      expect(() => cuspsFor(HouseSystem.placidus, 100), throwsArgumentError);
      expect(() => cuspsFor(HouseSystem.koch, 100), throwsArgumentError);
    });

    test('derives whole sign and equal cusps without one', () {
      expect(cuspsFor(HouseSystem.wholeSign, 125).first, 120);
      expect(cuspsFor(HouseSystem.equal, 125).first, 125);
    });
  });
}
