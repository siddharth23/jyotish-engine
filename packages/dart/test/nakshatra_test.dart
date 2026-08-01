import 'package:jyotish_engine/jyotish_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Nakshatra boundaries', () {
    // These starting points are classical and independent of this implementation:
    // Ashwini opens the zodiac at 0 Aries, Krittika begins at 26 degrees 40 minutes
    // of Aries, Magha begins exactly at 0 Leo, and Mula exactly at 0 Sagittarius.
    test('Ashwini begins at 0 Aries', () {
      expect(Nakshatra.fromLongitude(0), Nakshatra.ashwini);
    });

    test('Krittika begins at 26 degrees 40 minutes of Aries', () {
      expect(Nakshatra.fromLongitude(26 + 40 / 60), Nakshatra.krittika);
      expect(Nakshatra.fromLongitude(26 + 39 / 60), Nakshatra.bharani);
    });

    test('Magha begins exactly at 0 Leo', () {
      expect(Nakshatra.fromLongitude(120), Nakshatra.magha);
      expect(Nakshatra.fromLongitude(119.999), Nakshatra.ashlesha);
    });

    test('Mula begins exactly at 0 Sagittarius', () {
      expect(Nakshatra.fromLongitude(240), Nakshatra.mula);
      expect(Nakshatra.fromLongitude(239.999), Nakshatra.jyeshtha);
    });

    test('Revati closes the zodiac', () {
      expect(Nakshatra.fromLongitude(359.999), Nakshatra.revati);
    });

    test('wraps rather than throwing at and beyond a full circle', () {
      expect(Nakshatra.fromLongitude(360), Nakshatra.ashwini);
      expect(Nakshatra.fromLongitude(-0.001), Nakshatra.revati);
    });
  });

  group('Nakshatra lords', () {
    // The Vimshottari lords repeat every nine nakshatras. Ketu opens each run.
    test('the three Ketu nakshatras are Ashwini, Magha and Mula', () {
      expect(Nakshatra.ashwini.lord, Graha.ketu);
      expect(Nakshatra.magha.lord, Graha.ketu);
      expect(Nakshatra.mula.lord, Graha.ketu);
    });

    test('follow the Vimshottari order from Ashwini', () {
      expect(Nakshatra.bharani.lord, Graha.venus);
      expect(Nakshatra.krittika.lord, Graha.sun);
      expect(Nakshatra.rohini.lord, Graha.moon);
      expect(Nakshatra.mrigashira.lord, Graha.mars);
      expect(Nakshatra.ardra.lord, Graha.rahu);
      expect(Nakshatra.punarvasu.lord, Graha.jupiter);
      expect(Nakshatra.pushya.lord, Graha.saturn);
      expect(Nakshatra.ashlesha.lord, Graha.mercury);
    });

    test('every graha lords exactly three nakshatras', () {
      final counts = <Graha, int>{};
      for (final nakshatra in Nakshatra.values) {
        counts[nakshatra.lord] = (counts[nakshatra.lord] ?? 0) + 1;
      }
      expect(counts.length, 9);
      expect(counts.values.every((count) => count == 3), isTrue);
    });
  });

  group('Padas', () {
    test('divide Ashwini into four quarters of 3 degrees 20 minutes', () {
      expect(padaOfLongitude(0), 1);
      expect(padaOfLongitude(3 + 19 / 60), 1);
      expect(padaOfLongitude(3 + 20 / 60), 2);
      expect(padaOfLongitude(6 + 40 / 60), 3);
      expect(padaOfLongitude(10), 4);
      expect(padaOfLongitude(13 + 19 / 60), 4);
    });

    test('reset at the start of the next nakshatra', () {
      expect(padaOfLongitude(13 + 20 / 60), 1);
    });

    test('never fall outside 1 to 4 anywhere in the zodiac', () {
      for (var tenth = 0; tenth < 3600; tenth++) {
        final pada = padaOfLongitude(tenth / 10);
        expect(pada, inInclusiveRange(1, 4),
            reason: 'at ${tenth / 10} degrees');
      }
    });
  });

  group('Elapsed fraction', () {
    test('is 0 at a nakshatra start and approaches 1 at its end', () {
      expect(nakshatraElapsedFraction(0), 0);
      expect(nakshatraElapsedFraction(120), 0);
      expect(nakshatraElapsedFraction(nakshatraSpan / 2), closeTo(0.5, 1e-12));
      expect(nakshatraElapsedFraction(nakshatraSpan * 0.999),
          closeTo(0.999, 1e-12));
    });

    test('stays within 0 inclusive and 1 exclusive across the zodiac', () {
      for (var tenth = 0; tenth < 3600; tenth++) {
        final fraction = nakshatraElapsedFraction(tenth / 10);
        expect(fraction, greaterThanOrEqualTo(0));
        expect(fraction, lessThan(1));
      }
    });
  });
}
