import 'package:jyotish_engine/jyotish_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Ayanamsa', () {
    test('maps every system to a distinct Swiss Ephemeris constant', () {
      final constants = Ayanamsa.values.map((a) => a.sweConstant).toSet();
      expect(constants.length, Ayanamsa.values.length);
    });

    test('exposes a display name for every system', () {
      for (final ayanamsa in Ayanamsa.values) {
        expect(ayanamsa.displayName, isNotEmpty);
      }
    });

    test('Lahiri uses SE_SIDM_LAHIRI', () {
      expect(Ayanamsa.lahiri.sweConstant, 1);
    });
  });
}
