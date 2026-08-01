import 'package:jyotish_engine/jyotish_engine.dart';
import 'package:test/test.dart';

void main() {
  group('HouseSystem', () {
    test('maps every system to a distinct Swiss Ephemeris code', () {
      final codes = HouseSystem.values.map((h) => h.sweCode).toSet();
      expect(codes.length, HouseSystem.values.length);
    });

    test('quadrant systems are flagged unreliable at high latitude', () {
      expect(HouseSystem.placidus.isReliableAtHighLatitude, isFalse);
      expect(HouseSystem.koch.isReliableAtHighLatitude, isFalse);
      expect(HouseSystem.wholeSign.isReliableAtHighLatitude, isTrue);
      expect(HouseSystem.equal.isReliableAtHighLatitude, isTrue);
    });
  });
}
