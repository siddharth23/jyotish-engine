import 'package:jyotish_engine/jyotish_engine.dart';
import 'package:test/test.dart';

void main() {
  group('engineVersion', () {
    test('follows semantic versioning', () {
      expect(engineVersion, matches(RegExp(r'^\d+\.\d+\.\d+')));
    });

    test('is not empty', () {
      expect(engineVersion, isNotEmpty);
    });
  });
}
