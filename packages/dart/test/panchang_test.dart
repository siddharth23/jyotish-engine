import 'package:jyotish_engine/jyotish_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Tithi', () {
    test('is 1 at the new moon, when the Moon and Sun share a longitude', () {
      expect(tithiOf(100, 100), 1);
    });

    test('advances one per 12 degrees of elongation', () {
      expect(tithiOf(0, 11.99), 1);
      expect(tithiOf(0, 12), 2);
      expect(tithiOf(0, 24), 3);
    });

    test('tithi 15 ends at the full moon', () {
      expect(tithiOf(0, 179.99), 15);
      expect(tithiOf(0, 180), 16);
    });

    test('tithi 30 is the last before the new moon', () {
      expect(tithiOf(0, 359.99), 30);
    });

    test('measures elongation the correct way round', () {
      // The Moon is 30 degrees ahead of the Sun, not 330 behind.
      expect(tithiOf(350, 20), 3);
    });

    test('never falls outside 1 to 30', () {
      for (var degree = 0; degree < 360; degree++) {
        expect(tithiOf(0, degree.toDouble()), inInclusiveRange(1, 30));
        expect(tithiOf(degree.toDouble(), 0), inInclusiveRange(1, 30));
      }
    });

    test('elapsed fraction runs from 0 to just under 1 within a tithi', () {
      expect(tithiElapsedFraction(0, 12), 0);
      expect(tithiElapsedFraction(0, 18), closeTo(0.5, 1e-12));
      expect(tithiElapsedFraction(0, 23.99), closeTo(0.999, 1e-3));
    });
  });

  group('Paksha', () {
    test('the first fifteen tithis are the waxing half', () {
      expect(pakshaOf(1), Paksha.shukla);
      expect(pakshaOf(15), Paksha.shukla);
    });

    test('the last fifteen are the waning half', () {
      expect(pakshaOf(16), Paksha.krishna);
      expect(pakshaOf(30), Paksha.krishna);
    });
  });

  group('Yoga', () {
    test('is formed from the sum of the longitudes, not the difference', () {
      // Sum 0 puts us at the start of the first yoga.
      expect(yogaOf(0, 0), Yoga.vishkambha);
      // Same difference, different sum, therefore a different yoga.
      expect(yogaOf(100, 100), isNot(Yoga.vishkambha));
    });

    test('spans the same width as a nakshatra', () {
      expect(yogaOf(0, nakshatraSpan - 0.01), Yoga.vishkambha);
      expect(yogaOf(0, nakshatraSpan), Yoga.priti);
    });

    test('wraps after the twenty-seventh', () {
      expect(yogaOf(0, 360 - 0.01), Yoga.vaidhriti);
      expect(yogaOf(180, 180), Yoga.vishkambha);
    });

    test('never falls outside the 27', () {
      for (var degree = 0; degree < 360; degree++) {
        final yoga = yogaOf(degree.toDouble(), degree.toDouble());
        expect(yoga.index, inInclusiveRange(0, 26));
      }
    });
  });

  group('Karana', () {
    test('the first half-tithi of the month is Kimstughna', () {
      expect(karanaPosition(0, 0), 0);
      expect(karanaOf(0, 0), Karana.kimstughna);
    });

    test('the movable karanas follow it in order', () {
      expect(karanaOf(0, karanaSpan), Karana.bava);
      expect(karanaOf(0, karanaSpan * 2), Karana.balava);
      expect(karanaOf(0, karanaSpan * 3), Karana.kaulava);
      expect(karanaOf(0, karanaSpan * 7), Karana.vishti);
      // Then the cycle of seven repeats.
      expect(karanaOf(0, karanaSpan * 8), Karana.bava);
    });

    test('the three fixed karanas close the month', () {
      expect(karanaOf(0, karanaSpan * 57), Karana.shakuni);
      expect(karanaOf(0, karanaSpan * 58), Karana.chatushpada);
      expect(karanaOf(0, karanaSpan * 59), Karana.naga);
    });

    test('the movable karanas occupy exactly 56 of the 60 positions', () {
      var movable = 0;
      final seen = <Karana>{};
      for (var position = 0; position < 60; position++) {
        final karana = karanaOf(0, karanaSpan * position + karanaSpan / 2);
        seen.add(karana);
        if (karana.isMovable) movable++;
      }
      expect(movable, 56);
      expect(seen, hasLength(11));
      expect(seen, containsAll(Karana.values));
    });

    test('each karana is half a tithi', () {
      // Two karana positions per tithi, throughout the month.
      for (var position = 0; position < 60; position++) {
        final longitude = karanaSpan * position + karanaSpan / 2;
        expect(karanaPosition(0, longitude), position);
        expect(tithiOf(0, longitude), position ~/ 2 + 1);
      }
    });
  });

  group('Vara', () {
    test('an instant after sunrise takes that day\'s weekday', () {
      // 2024-01-03 was a Wednesday.
      final sunrise = DateTime.utc(2024, 1, 3, 6);
      expect(varaOf(DateTime.utc(2024, 1, 3, 12), sunrise), 3);
    });

    test('an instant before sunrise belongs to the previous weekday', () {
      final sunrise = DateTime.utc(2024, 1, 3, 6);
      // 03:00 on Wednesday is still the Tuesday vara.
      expect(varaOf(DateTime.utc(2024, 1, 3, 3), sunrise), 2);
    });

    test('Sunday is 0 and Saturday is 6', () {
      // 2024-01-07 was a Sunday.
      expect(
          varaOf(DateTime.utc(2024, 1, 7, 12), DateTime.utc(2024, 1, 7, 6)), 0);
      // 2024-01-06 was a Saturday.
      expect(
          varaOf(DateTime.utc(2024, 1, 6, 12), DateTime.utc(2024, 1, 6, 6)), 6);
    });
  });

  group('Assembly', () {
    test('fills every limb from the two longitudes', () {
      final panchang = Panchang.fromLongitudes(
        instant: DateTime.utc(2024, 1, 3, 12),
        sunLongitude: 0,
        moonLongitude: 40,
        sunrise: DateTime.utc(2024, 1, 3, 6),
        sunset: DateTime.utc(2024, 1, 3, 16),
      );

      expect(panchang.tithi, tithiOf(0, 40));
      expect(panchang.nakshatra, Nakshatra.fromLongitude(40).index);
      expect(panchang.yoga, yogaOf(0, 40).index);
      expect(panchang.karana, karanaOf(0, 40).index);
      expect(panchang.vara, 3);
      expect(panchang.paksha, Paksha.shukla);
    });

    test('takes the nakshatra from the Moon, not the Sun', () {
      final panchang = Panchang.fromLongitudes(
        instant: DateTime.utc(2024, 1, 3, 12),
        sunLongitude: 0,
        moonLongitude: 120,
      );
      expect(panchang.nakshatra, Nakshatra.magha.index);
    });

    test('falls back to the UTC weekday when there is no sunrise', () {
      // Above the polar circle the Sun may not cross the horizon at all.
      final panchang = Panchang.fromLongitudes(
        instant: DateTime.utc(2024, 1, 3, 12),
        sunLongitude: 0,
        moonLongitude: 40,
      );
      expect(panchang.sunrise, isNull);
      expect(panchang.sunset, isNull);
      expect(panchang.vara, 3);
    });

    test('serialises every limb', () {
      final panchang = Panchang.fromLongitudes(
        instant: DateTime.utc(2024, 1, 3, 12),
        sunLongitude: 0,
        moonLongitude: 40,
        sunrise: DateTime.utc(2024, 1, 3, 6),
      );
      expect(panchang.toJson().keys.toSet(), {
        'tithi',
        'nakshatra',
        'yoga',
        'karana',
        'vara',
        'sunrise',
        'sunset',
      });
      expect(panchang.toJson()['sunset'], isNull);
    });
  });
}
