import 'package:jyotish_engine/jyotish_engine.dart';
import 'package:test/test.dart';

/// Longitude of [degree] degrees into [sign].
double at(Rasi sign, double degree) => sign.index * 30 + degree;

void main() {
  group('Navamsa (D9)', () {
    // Classical rule: a movable sign's navamsas start from the sign itself, a fixed
    // sign's from the 9th from it, and a dual sign's from the 5th.
    test('movable signs start their navamsa from themselves', () {
      expect(Rasi.mesha.modality, Modality.movable);
      expect(vargaSign(at(Rasi.mesha, 0), Varga.d9), Rasi.mesha);
      expect(Rasi.karka.modality, Modality.movable);
      expect(vargaSign(at(Rasi.karka, 0), Varga.d9), Rasi.karka);
    });

    test('fixed signs start from the ninth sign from themselves', () {
      expect(Rasi.vrishabha.modality, Modality.fixed);
      expect(vargaSign(at(Rasi.vrishabha, 0), Varga.d9), Rasi.makara);
      expect(Rasi.simha.modality, Modality.fixed);
      expect(vargaSign(at(Rasi.simha, 0), Varga.d9), Rasi.mesha);
    });

    test('dual signs start from the fifth sign from themselves', () {
      expect(Rasi.mithuna.modality, Modality.dual);
      expect(vargaSign(at(Rasi.mithuna, 0), Varga.d9), Rasi.tula);
      expect(Rasi.kanya.modality, Modality.dual);
      expect(vargaSign(at(Rasi.kanya, 0), Varga.d9), Rasi.makara);
    });

    test('advances one sign per 3 degrees 20 minutes', () {
      const span = 30 / 9;
      expect(vargaSign(at(Rasi.mesha, span * 0.5), Varga.d9), Rasi.mesha);
      expect(vargaSign(at(Rasi.mesha, span * 1.5), Varga.d9), Rasi.vrishabha);
      expect(vargaSign(at(Rasi.mesha, span * 8.5), Varga.d9), Rasi.dhanu);
    });

    test('the first navamsa of a movable sign is vargottama', () {
      // Vargottama: the same sign in D1 and D9.
      final longitude = at(Rasi.mesha, 1);
      expect(Rasi.fromLongitude(longitude), Rasi.mesha);
      expect(vargaSign(longitude, Varga.d9), Rasi.mesha);
    });
  });

  group('Hora (D2)', () {
    test('odd signs give the Sun\'s hora then the Moon\'s', () {
      expect(Rasi.mesha.isOdd, isTrue);
      expect(vargaSign(at(Rasi.mesha, 5), Varga.d2), Rasi.simha);
      expect(vargaSign(at(Rasi.mesha, 20), Varga.d2), Rasi.karka);
    });

    test('even signs reverse that order', () {
      expect(Rasi.vrishabha.isOdd, isFalse);
      expect(vargaSign(at(Rasi.vrishabha, 5), Varga.d2), Rasi.karka);
      expect(vargaSign(at(Rasi.vrishabha, 20), Varga.d2), Rasi.simha);
    });

    test('only ever produces Cancer or Leo', () {
      for (var degree = 0; degree < 360; degree++) {
        expect(
          vargaSign(degree.toDouble(), Varga.d2),
          anyOf(Rasi.karka, Rasi.simha),
        );
      }
    });
  });

  group('Drekkana (D3)', () {
    test('the three parts fall in the sign, the 5th and the 9th from it', () {
      expect(vargaSign(at(Rasi.mesha, 5), Varga.d3), Rasi.mesha);
      expect(vargaSign(at(Rasi.mesha, 15), Varga.d3), Rasi.simha);
      expect(vargaSign(at(Rasi.mesha, 25), Varga.d3), Rasi.dhanu);
    });

    test('holds for a sign other than the first', () {
      expect(vargaSign(at(Rasi.vrishchika, 5), Varga.d3), Rasi.vrishchika);
      expect(vargaSign(at(Rasi.vrishchika, 15), Varga.d3), Rasi.meena);
      expect(vargaSign(at(Rasi.vrishchika, 25), Varga.d3), Rasi.karka);
    });
  });

  group('Saptamsha (D7)', () {
    test('odd signs start from the sign itself', () {
      expect(vargaSign(at(Rasi.mesha, 1), Varga.d7), Rasi.mesha);
    });

    test('even signs start from the seventh sign', () {
      expect(vargaSign(at(Rasi.vrishabha, 1), Varga.d7), Rasi.vrishchika);
    });
  });

  group('Dashamsha (D10)', () {
    test('odd signs start from the sign itself', () {
      expect(vargaSign(at(Rasi.mesha, 1), Varga.d10), Rasi.mesha);
      expect(vargaSign(at(Rasi.mesha, 4), Varga.d10), Rasi.vrishabha);
    });

    test('even signs start from the ninth sign', () {
      expect(vargaSign(at(Rasi.vrishabha, 1), Varga.d10), Rasi.makara);
    });
  });

  group('Dwadashamsha (D12)', () {
    test('every sign starts from itself, advancing per 2 degrees 30 minutes',
        () {
      expect(vargaSign(at(Rasi.mesha, 1), Varga.d12), Rasi.mesha);
      expect(vargaSign(at(Rasi.mesha, 3), Varga.d12), Rasi.vrishabha);
      expect(vargaSign(at(Rasi.vrishchika, 1), Varga.d12), Rasi.vrishchika);
    });
  });

  group('Chaturthamsa (D4)', () {
    test('the four parts fall in the sign and the three kendras from it', () {
      expect(vargaSign(at(Rasi.mesha, 3), Varga.d4), Rasi.mesha);
      expect(vargaSign(at(Rasi.mesha, 10), Varga.d4), Rasi.karka);
      expect(vargaSign(at(Rasi.mesha, 20), Varga.d4), Rasi.tula);
      expect(vargaSign(at(Rasi.mesha, 28), Varga.d4), Rasi.makara);
    });

    test('holds for a sign other than the first', () {
      expect(vargaSign(at(Rasi.vrishchika, 3), Varga.d4), Rasi.vrishchika);
      expect(vargaSign(at(Rasi.vrishchika, 28), Varga.d4), Rasi.simha);
    });
  });

  group('Shodashamsa (D16)', () {
    test('starts from Mesha, Simha or Dhanu by modality', () {
      expect(vargaSign(at(Rasi.mesha, 1), Varga.d16), Rasi.mesha);
      expect(vargaSign(at(Rasi.vrishabha, 1), Varga.d16), Rasi.simha);
      expect(vargaSign(at(Rasi.mithuna, 1), Varga.d16), Rasi.dhanu);
    });

    test('advances one sign per 1 degree 52.5 minutes', () {
      expect(vargaSign(at(Rasi.mesha, 2), Varga.d16), Rasi.vrishabha);
    });
  });

  group('Vimshamsa (D20)', () {
    test('starts from Mesha, Dhanu or Simha by modality', () {
      expect(vargaSign(at(Rasi.mesha, 1), Varga.d20), Rasi.mesha);
      expect(vargaSign(at(Rasi.vrishabha, 1), Varga.d20), Rasi.dhanu);
      expect(vargaSign(at(Rasi.mithuna, 1), Varga.d20), Rasi.simha);
    });

    test('advances one sign per 1 degree 30 minutes', () {
      expect(vargaSign(at(Rasi.mesha, 2), Varga.d20), Rasi.vrishabha);
    });
  });

  group('Siddhamsa (D24)', () {
    test('odd signs start from Simha, even signs from Karka', () {
      expect(vargaSign(at(Rasi.mesha, 1), Varga.d24), Rasi.simha);
      expect(vargaSign(at(Rasi.vrishabha, 1), Varga.d24), Rasi.karka);
    });

    test('advances one sign per 1 degree 15 minutes', () {
      expect(vargaSign(at(Rasi.mesha, 2), Varga.d24), Rasi.kanya);
      expect(vargaSign(at(Rasi.vrishabha, 2), Varga.d24), Rasi.simha);
    });
  });

  group('Bhamsa (D27)', () {
    // The starting sign follows the element, which cycles every four signs.
    test('fiery signs start from Mesha', () {
      expect(vargaSign(at(Rasi.mesha, 0.5), Varga.d27), Rasi.mesha);
      expect(vargaSign(at(Rasi.simha, 0.5), Varga.d27), Rasi.mesha);
      expect(vargaSign(at(Rasi.dhanu, 0.5), Varga.d27), Rasi.mesha);
    });

    test('earthy from Karka, airy from Tula, watery from Makara', () {
      expect(vargaSign(at(Rasi.vrishabha, 0.5), Varga.d27), Rasi.karka);
      expect(vargaSign(at(Rasi.mithuna, 0.5), Varga.d27), Rasi.tula);
      expect(vargaSign(at(Rasi.karka, 0.5), Varga.d27), Rasi.makara);
    });
  });

  group('Trimshamsa (D30)', () {
    // The one varga with unequal parts: Mars 5, Saturn 5, Jupiter 8, Mercury 7
    // and Venus 5 degrees in an odd sign, the same five reversed in an even one.
    test('an odd sign runs Mars, Saturn, Jupiter, Mercury, Venus', () {
      expect(vargaSign(at(Rasi.mesha, 3), Varga.d30), Rasi.mesha);
      expect(vargaSign(at(Rasi.mesha, 7), Varga.d30), Rasi.kumbha);
      expect(vargaSign(at(Rasi.mesha, 15), Varga.d30), Rasi.dhanu);
      expect(vargaSign(at(Rasi.mesha, 20), Varga.d30), Rasi.mithuna);
      expect(vargaSign(at(Rasi.mesha, 27), Varga.d30), Rasi.tula);
    });

    test('an even sign reverses that order', () {
      expect(vargaSign(at(Rasi.vrishabha, 3), Varga.d30), Rasi.vrishabha);
      expect(vargaSign(at(Rasi.vrishabha, 8), Varga.d30), Rasi.kanya);
      expect(vargaSign(at(Rasi.vrishabha, 15), Varga.d30), Rasi.meena);
      expect(vargaSign(at(Rasi.vrishabha, 22), Varga.d30), Rasi.makara);
      expect(vargaSign(at(Rasi.vrishabha, 27), Varga.d30), Rasi.vrishchika);
    });

    test('a part boundary belongs to the part above it', () {
      expect(vargaSign(at(Rasi.mesha, 5), Varga.d30), Rasi.kumbha);
      expect(vargaSign(at(Rasi.mesha, 10), Varga.d30), Rasi.dhanu);
      expect(vargaSign(at(Rasi.vrishabha, 12), Varga.d30), Rasi.meena);
    });

    test('never produces Karka or Simha', () {
      // Only the five tara grahas rule trimshamsas; the Sun and Moon rule none,
      // so their signs can never appear. A rule table typo would show up here.
      for (var tenth = 0; tenth < 3600; tenth++) {
        expect(
          vargaSign(tenth / 10, Varga.d30),
          isNot(anyOf(Rasi.karka, Rasi.simha)),
          reason: 'at ${tenth / 10} degrees',
        );
      }
    });

    test('reports unequal divisions, unlike every other varga', () {
      expect(Varga.d30.hasEqualDivisions, isFalse);
      for (final varga in Varga.values.where((v) => v != Varga.d30)) {
        expect(varga.hasEqualDivisions, isTrue, reason: varga.name);
      }
    });
  });

  group('Khavedamsa (D40)', () {
    test('odd signs start from Mesha, even signs from Tula', () {
      expect(vargaSign(at(Rasi.mesha, 0.5), Varga.d40), Rasi.mesha);
      expect(vargaSign(at(Rasi.vrishabha, 0.5), Varga.d40), Rasi.tula);
    });

    test('advances one sign per 45 minutes', () {
      expect(vargaSign(at(Rasi.mesha, 1), Varga.d40), Rasi.vrishabha);
    });
  });

  group('Akshavedamsa (D45)', () {
    test('starts from Mesha, Simha or Dhanu by modality', () {
      expect(vargaSign(at(Rasi.mesha, 0.5), Varga.d45), Rasi.mesha);
      expect(vargaSign(at(Rasi.vrishabha, 0.5), Varga.d45), Rasi.simha);
      expect(vargaSign(at(Rasi.mithuna, 0.5), Varga.d45), Rasi.dhanu);
    });
  });

  group('Shashtiamsa (D60)', () {
    test('every sign starts from itself, advancing per 30 minutes', () {
      expect(vargaSign(at(Rasi.mesha, 0.25), Varga.d60), Rasi.mesha);
      expect(vargaSign(at(Rasi.mesha, 0.75), Varga.d60), Rasi.vrishabha);
      expect(vargaSign(at(Rasi.vrishchika, 0.25), Varga.d60), Rasi.vrishchika);
    });

    test('wraps the full zodiac every 6 degrees', () {
      expect(vargaSign(at(Rasi.mesha, 6.25), Varga.d60), Rasi.mesha);
    });
  });

  group('Varga invariants', () {
    test('the Shodashavarga has exactly sixteen members', () {
      // Brihat Parashara Hora Shastra ch. 6. Adding a seventeenth would mean a
      // non-classical division had been introduced.
      expect(Varga.values.length, 16);
      expect(
        Varga.values.map((v) => v.divisions).toList(),
        [1, 2, 3, 4, 7, 9, 10, 12, 16, 20, 24, 27, 30, 40, 45, 60],
      );
    });

    test('D1 is the identity mapping', () {
      for (var degree = 0; degree < 360; degree++) {
        expect(
          vargaSign(degree.toDouble(), Varga.d1),
          Rasi.fromLongitude(degree.toDouble()),
        );
        expect(
            vargaLongitude(degree.toDouble(), Varga.d1), closeTo(degree, 1e-9));
      }
    });

    test('no varga ever produces an out-of-range longitude', () {
      for (final varga in Varga.values) {
        for (var tenth = 0; tenth < 3600; tenth++) {
          final longitude = vargaLongitude(tenth / 10, varga);
          expect(longitude, greaterThanOrEqualTo(0), reason: varga.name);
          expect(longitude, lessThan(360), reason: varga.name);
        }
      }
    });

    test('the scaled longitude stays inside the sign the varga selected', () {
      for (final varga in Varga.values) {
        for (var tenth = 0; tenth < 3600; tenth++) {
          final source = tenth / 10;
          expect(
            Rasi.fromLongitude(vargaLongitude(source, varga)),
            vargaSign(source, varga),
            reason: '${varga.name} at $source degrees',
          );
        }
      }
    });

    test('a division boundary maps to the start of its varga sign', () {
      // 3 degrees 20 minutes is the second navamsa of Aries, which is Taurus.
      final longitude = vargaLongitude(at(Rasi.mesha, 30 / 9), Varga.d9);
      expect(Rasi.fromLongitude(longitude), Rasi.vrishabha);
      expect(longitude % 30, closeTo(0, 1e-9));
    });
  });
}
