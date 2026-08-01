import 'package:jyotish_engine/jyotish_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Vimshottari', () {
    test('total cycle is exactly 120 years', () {
      final total = vimshottariYears.values.reduce((a, b) => a + b);
      expect(total, 120);
    });

    test('order contains all nine grahas exactly once', () {
      expect(vimshottariOrder.length, 9);
      expect(vimshottariOrder.toSet().length, 9);
    });

    test('every graha in the order has an allotted period', () {
      for (final graha in vimshottariOrder) {
        expect(vimshottariYears[graha], isNotNull);
      }
    });

    test('period containment is inclusive of start and exclusive of end', () {
      final period = DashaPeriod(
        lord: Graha.venus,
        start: DateTime.utc(2020),
        end: DateTime.utc(2040),
        level: 1,
      );
      expect(period.containsDate(DateTime.utc(2020)), isTrue);
      expect(period.containsDate(DateTime.utc(2030)), isTrue);
      expect(period.containsDate(DateTime.utc(2040)), isFalse);
      expect(period.containsDate(DateTime.utc(2019)), isFalse);
    });
  });
}
