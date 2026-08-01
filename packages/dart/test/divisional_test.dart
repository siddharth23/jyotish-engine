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

  group('Varga invariants', () {
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
