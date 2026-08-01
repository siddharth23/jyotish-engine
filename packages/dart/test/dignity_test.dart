import 'package:jyotish_engine/jyotish_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Exaltation and debilitation', () {
    // Source: Brihat Parashara Hora Shastra, ch. 3. Each graha is exalted in one
    // sign and debilitated in the sign opposite.
    test('the seven classical grahas are exalted in their classical signs', () {
      expect(dignityOf(Graha.sun, Rasi.mesha), Dignity.exalted);
      expect(dignityOf(Graha.moon, Rasi.vrishabha), Dignity.exalted);
      expect(dignityOf(Graha.mars, Rasi.makara), Dignity.exalted);
      expect(dignityOf(Graha.mercury, Rasi.kanya), Dignity.exalted);
      expect(dignityOf(Graha.jupiter, Rasi.karka), Dignity.exalted);
      expect(dignityOf(Graha.venus, Rasi.meena), Dignity.exalted);
      expect(dignityOf(Graha.saturn, Rasi.tula), Dignity.exalted);
    });

    test('each is debilitated in the opposite sign', () {
      expect(dignityOf(Graha.sun, Rasi.tula), Dignity.debilitated);
      expect(dignityOf(Graha.moon, Rasi.vrishchika), Dignity.debilitated);
      expect(dignityOf(Graha.mars, Rasi.karka), Dignity.debilitated);
      expect(dignityOf(Graha.mercury, Rasi.meena), Dignity.debilitated);
      expect(dignityOf(Graha.jupiter, Rasi.makara), Dignity.debilitated);
      expect(dignityOf(Graha.venus, Rasi.kanya), Dignity.debilitated);
      expect(dignityOf(Graha.saturn, Rasi.mesha), Dignity.debilitated);
    });

    test('exaltation and debilitation signs are exactly six signs apart', () {
      for (final entry in exaltationPoints.entries) {
        final separation =
            (entry.value.debilitationSign.index - entry.value.sign.index) % 12;
        expect(separation, 6, reason: entry.key.name);
      }
    });
  });

  group('Own sign', () {
    test('a graha in a sign it rules is in its own sign', () {
      expect(dignityOf(Graha.sun, Rasi.simha), Dignity.ownSign);
      expect(dignityOf(Graha.moon, Rasi.karka), Dignity.ownSign);
      expect(dignityOf(Graha.mars, Rasi.mesha), Dignity.ownSign);
      expect(dignityOf(Graha.mars, Rasi.vrishchika), Dignity.ownSign);
      expect(dignityOf(Graha.jupiter, Rasi.dhanu), Dignity.ownSign);
      expect(dignityOf(Graha.saturn, Rasi.kumbha), Dignity.ownSign);
    });

    // Mercury rules Virgo and is also exalted there. Exaltation takes precedence,
    // which is the one place the ordering of the checks is observable.
    test('exaltation outranks own sign for Mercury in Virgo', () {
      expect(Rasi.kanya.lord, Graha.mercury);
      expect(dignityOf(Graha.mercury, Rasi.kanya), Dignity.exalted);
    });
  });

  group('Natural relationships', () {
    test('a graha in a friend\'s sign is friendly', () {
      // Jupiter rules Sagittarius and is the Sun's natural friend.
      expect(Rasi.dhanu.lord, Graha.jupiter);
      expect(dignityOf(Graha.sun, Rasi.dhanu), Dignity.friendly);
    });

    test('a graha in an enemy\'s sign is inimical', () {
      // Venus rules Taurus and is the Sun's natural enemy.
      expect(Rasi.vrishabha.lord, Graha.venus);
      expect(dignityOf(Graha.sun, Rasi.vrishabha), Dignity.inimical);
    });

    test('a graha in a neutral\'s sign is neutral', () {
      // Mercury rules Gemini and is neutral to the Sun.
      expect(Rasi.mithuna.lord, Graha.mercury);
      expect(dignityOf(Graha.sun, Rasi.mithuna), Dignity.neutral);
    });

    test('friendship tables never list a graha as both friend and enemy', () {
      for (final graha in naturalFriends.keys) {
        final friends = naturalFriends[graha] ?? const {};
        final enemies = naturalEnemies[graha] ?? const {};
        expect(friends.intersection(enemies), isEmpty, reason: graha.name);
        expect(friends, isNot(contains(graha)), reason: '${graha.name} self');
      }
    });
  });

  group('Rahu and Ketu', () {
    // They rule no sign and have no agreed friendship or exaltation, so the engine
    // reports neutral everywhere rather than inventing an answer.
    test('are neutral in every sign', () {
      for (final sign in Rasi.values) {
        expect(dignityOf(Graha.rahu, sign), Dignity.neutral);
        expect(dignityOf(Graha.ketu, sign), Dignity.neutral);
      }
    });

    test('have no exaltation point defined', () {
      expect(exaltationPoints[Graha.rahu], isNull);
      expect(exaltationPoints[Graha.ketu], isNull);
    });

    test('rule no sign', () {
      for (final sign in Rasi.values) {
        expect(sign.lord, isNot(Graha.rahu));
        expect(sign.lord, isNot(Graha.ketu));
      }
    });
  });

  group('Combustion', () {
    test('a graha close to the Sun is combust', () {
      // Mercury 5 degrees from the Sun is inside its 14 degree direct orb.
      expect(isCombust(Graha.mercury, 105, 100, isRetrograde: false), isTrue);
    });

    test('a graha beyond its orb is not', () {
      expect(isCombust(Graha.mercury, 120, 100, isRetrograde: false), isFalse);
    });

    test('retrograde Mercury and Venus use a tighter orb', () {
      expect(combustionOrb(Graha.mercury, isRetrograde: true), 12);
      expect(combustionOrb(Graha.mercury, isRetrograde: false), 14);
      expect(combustionOrb(Graha.venus, isRetrograde: true), 8);
      expect(combustionOrb(Graha.venus, isRetrograde: false), 10);

      // 13 degrees is combust when direct but not when retrograde.
      expect(isCombust(Graha.mercury, 113, 100, isRetrograde: false), isTrue);
      expect(isCombust(Graha.mercury, 113, 100, isRetrograde: true), isFalse);
    });

    test('measures separation the short way around the circle', () {
      // 5 degrees apart, but either side of 0 degrees.
      expect(isCombust(Graha.jupiter, 2, 357, isRetrograde: false), isTrue);
    });

    test('does not apply to the Sun or the nodes', () {
      expect(isCombust(Graha.sun, 100, 100, isRetrograde: false), isFalse);
      expect(isCombust(Graha.rahu, 100, 100, isRetrograde: true), isFalse);
      expect(isCombust(Graha.ketu, 100, 100, isRetrograde: true), isFalse);
    });
  });
}
