import 'package:jyotish_engine/jyotish_engine.dart';
import 'package:test/test.dart';

/// A synthetic ephemeris. Values are chosen to exercise the derivations, not to
/// represent a real sky — real positions arrive from Swiss Ephemeris.
RawEphemeris ephemeris({
  double ascendant = 125, // 5 Leo
  Map<Graha, double> longitudes = const {},
  Map<Graha, double> speeds = const {},
  List<double>? houseCusps,
  bool includeKetu = false,
}) {
  final defaults = <Graha, double>{
    Graha.sun: 100, // 10 Cancer
    Graha.moon: 40, // 10 Taurus
    Graha.mars: 285, // 15 Capricorn
    Graha.mercury: 105, // 15 Cancer, 5 degrees from the Sun
    Graha.jupiter: 95, // 5 Cancer
    Graha.venus: 350, // 20 Pisces
    Graha.saturn: 190, // 10 Libra
    Graha.rahu: 60, // 0 Gemini
    if (includeKetu) Graha.ketu: 240,
  };
  final merged = {...defaults, ...longitudes};

  return RawEphemeris(
    ascendant: ascendant,
    ayanamsaValue: 23.85,
    houseCusps: houseCusps,
    bodies: [
      for (final entry in merged.entries)
        RawBodyPosition(
          graha: entry.key,
          siderealLongitude: entry.value,
          latitude: 0,
          speed: speeds[entry.key] ?? (entry.key.isShadow ? -0.05 : 1.0),
        ),
    ],
  );
}

BirthData birthData({
  HouseSystem houseSystem = HouseSystem.wholeSign,
}) =>
    BirthData(
      utcDateTime: DateTime.utc(1990, 5, 17, 8, 30),
      latitude: 52.52,
      longitude: 13.405,
      houseSystem: houseSystem,
    );

void main() {
  group('Node derivation', () {
    test('derives Ketu exactly opposite Rahu when absent', () {
      final chart = assembleChart(birthData(), ephemeris());
      final rahu = chart.positions[Graha.rahu]!;
      final ketu = chart.positions[Graha.ketu]!;

      expect(ketu.siderealLongitude, 240);
      expect(
        angularSeparation(rahu.siderealLongitude, ketu.siderealLongitude),
        closeTo(180, 1e-9),
      );
    });

    test('leaves a supplied Ketu untouched', () {
      final chart = assembleChart(
        birthData(),
        ephemeris(includeKetu: true, longitudes: {Graha.ketu: 241}),
      );
      expect(chart.positions[Graha.ketu]!.siderealLongitude, 241);
    });

    test('wraps the derived node across 0 degrees', () {
      final chart =
          assembleChart(birthData(), ephemeris(longitudes: {Graha.rahu: 200}));
      expect(chart.positions[Graha.ketu]!.siderealLongitude, 20);
    });
  });

  group('Derived fields', () {
    test('splits longitude into sign and degree within sign', () {
      final chart = assembleChart(birthData(), ephemeris());
      final sun = chart.positions[Graha.sun]!;
      expect(sun.sign, Rasi.karka.index);
      expect(sun.degreeInSign, closeTo(10, 1e-9));
    });

    test('assigns nakshatra and pada', () {
      final chart =
          assembleChart(birthData(), ephemeris(longitudes: {Graha.moon: 120}));
      final moon = chart.positions[Graha.moon]!;
      expect(moon.nakshatra, Nakshatra.magha.index);
      expect(moon.pada, 1);
    });

    test('assigns whole sign houses counted from the ascendant sign', () {
      // Ascendant 125 is 5 Leo, so Leo is the first house.
      final chart = assembleChart(birthData(), ephemeris());
      expect(chart.ascendantSign, Rasi.simha.index);
      // The Sun at 10 Cancer is the twelfth from Leo.
      expect(chart.positions[Graha.sun]!.house, 12);
      // Saturn at 10 Libra is the third.
      expect(chart.positions[Graha.saturn]!.house, 3);
    });

    test('reports retrograde motion from the sign of the speed', () {
      final chart = assembleChart(
        birthData(),
        ephemeris(speeds: {Graha.saturn: -0.02, Graha.mars: 0.5}),
      );
      expect(chart.positions[Graha.saturn]!.isRetrograde, isTrue);
      expect(chart.positions[Graha.mars]!.isRetrograde, isFalse);
      // The mean node always moves backwards.
      expect(chart.positions[Graha.rahu]!.isRetrograde, isTrue);
    });

    test('marks a graha inside its orb of the Sun combust', () {
      final chart = assembleChart(birthData(), ephemeris());
      // Mercury at 105 is 5 degrees from the Sun at 100.
      expect(chart.positions[Graha.mercury]!.isCombust, isTrue);
      // Jupiter at 95 is 5 degrees the other side, inside its 11 degree orb.
      expect(chart.positions[Graha.jupiter]!.isCombust, isTrue);
      // Saturn at 190 is 90 degrees away.
      expect(chart.positions[Graha.saturn]!.isCombust, isFalse);
      // The Sun is never combust.
      expect(chart.positions[Graha.sun]!.isCombust, isFalse);
    });

    test('assigns dignity from the sign', () {
      final chart = assembleChart(
        birthData(),
        ephemeris(longitudes: {Graha.jupiter: 95, Graha.saturn: 190}),
      );
      // Jupiter in Cancer is exalted, Saturn in Libra is exalted.
      expect(chart.positions[Graha.jupiter]!.dignity, Dignity.exalted);
      expect(chart.positions[Graha.saturn]!.dignity, Dignity.exalted);
    });

    test('embeds the engine version and the ayanamsa used', () {
      final chart = assembleChart(birthData(), ephemeris());
      expect(chart.engineVersion, engineVersion);
      expect(chart.ayanamsaValue, 23.85);
      expect(chart.varga, Varga.d1);
    });
  });

  group('House systems', () {
    test('derives equal cusps from the ascendant degree', () {
      final chart = assembleChart(
        birthData(houseSystem: HouseSystem.equal),
        ephemeris(),
      );
      expect(chart.houseCusps.first, 125);
    });

    test('uses ephemeris cusps for Placidus', () {
      const cusps = <double>[
        125,
        155,
        185,
        215,
        245,
        275,
        305,
        335,
        5,
        35,
        65,
        95,
      ];
      final chart = assembleChart(
        birthData(houseSystem: HouseSystem.placidus),
        ephemeris(houseCusps: cusps),
      );
      expect(chart.houseCusps, cusps);
    });

    test('refuses Placidus without ephemeris cusps rather than substituting',
        () {
      expect(
        () => assembleChart(
          birthData(houseSystem: HouseSystem.placidus),
          ephemeris(),
        ),
        throwsArgumentError,
      );
    });
  });

  group('Failure modes', () {
    test('rejects an ephemeris with no Sun, which combustion needs', () {
      const withoutSun = RawEphemeris(
        ascendant: 125,
        ayanamsaValue: 23.85,
        bodies: [
          RawBodyPosition(
            graha: Graha.moon,
            siderealLongitude: 40,
            latitude: 0,
            speed: 13,
          ),
        ],
      );
      expect(() => assembleChart(birthData(), withoutSun), throwsArgumentError);
    });
  });

  group('Divisional charts', () {
    test('D1 returns the rasi chart itself', () {
      final rasi = assembleChart(birthData(), ephemeris());
      expect(identical(computeDivisionalChart(rasi, Varga.d1), rasi), isTrue);
    });

    test('remaps every body into its varga sign', () {
      final rasi = assembleChart(birthData(), ephemeris());
      final navamsa = computeDivisionalChart(rasi, Varga.d9);

      expect(navamsa.varga, Varga.d9);
      for (final graha in rasi.positions.keys) {
        expect(
          navamsa.positions[graha]!.sign,
          vargaSign(rasi.positions[graha]!.siderealLongitude, Varga.d9).index,
          reason: graha.name,
        );
      }
    });

    test('casts the varga in whole sign from the varga ascendant', () {
      final rasi = assembleChart(birthData(), ephemeris());
      final navamsa = computeDivisionalChart(rasi, Varga.d9);

      expect(
          navamsa.ascendantSign, Rasi.fromLongitude(navamsa.ascendant).index);
      for (final cusp in navamsa.houseCusps) {
        expect(cusp % 30, 0);
      }
      expect(navamsa.houseCusps.first, navamsa.ascendantSign * 30);
    });

    test('carries combustion and physical quantities across unchanged', () {
      final rasi = assembleChart(birthData(), ephemeris());
      final navamsa = computeDivisionalChart(rasi, Varga.d9);

      for (final graha in rasi.positions.keys) {
        final source = rasi.positions[graha]!;
        final derived = navamsa.positions[graha]!;
        expect(derived.isCombust, source.isCombust, reason: graha.name);
        expect(derived.speed, source.speed, reason: graha.name);
        expect(derived.latitude, source.latitude, reason: graha.name);
        expect(derived.isRetrograde, source.isRetrograde, reason: graha.name);
      }
    });

    test('recomputes dignity in the varga sign', () {
      final rasi = assembleChart(birthData(), ephemeris());
      final navamsa = computeDivisionalChart(rasi, Varga.d9);
      for (final graha in navamsa.positions.keys) {
        final position = navamsa.positions[graha]!;
        expect(
          position.dignity,
          dignityOf(graha, Rasi.fromIndex(position.sign)),
          reason: graha.name,
        );
      }
    });

    test('refuses to derive a varga from another varga', () {
      final rasi = assembleChart(birthData(), ephemeris());
      final navamsa = computeDivisionalChart(rasi, Varga.d9);
      expect(
        () => computeDivisionalChart(navamsa, Varga.d10),
        throwsArgumentError,
      );
    });

    test('produces every supported varga without error', () {
      final rasi = assembleChart(birthData(), ephemeris());
      for (final varga in Varga.values) {
        final chart = computeDivisionalChart(rasi, varga);
        expect(chart.positions, hasLength(rasi.positions.length),
            reason: varga.name);
        for (final position in chart.positions.values) {
          expect(position.house, inInclusiveRange(1, 12), reason: varga.name);
        }
      }
    });
  });

  group('Determinism', () {
    test('the same input serialises identically every time', () {
      final first = assembleChart(birthData(), ephemeris()).toJson().toString();
      final second =
          assembleChart(birthData(), ephemeris()).toJson().toString();
      expect(first, second);
    });

    test('positions serialise in a fixed graha order', () {
      final chart = assembleChart(birthData(), ephemeris());
      final serialised = chart.toJson()['positions']! as Map<String, Object?>;
      expect(
        serialised.keys.toList(),
        [for (final graha in Graha.values) graha.name],
      );
    });
  });
}
