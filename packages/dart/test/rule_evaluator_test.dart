import 'package:jyotish_engine/jyotish_engine.dart';
import 'package:test/test.dart';

Chart testChart() => assembleChart(
      BirthData(
        utcDateTime: DateTime.utc(1990, 5, 17, 8, 30),
        latitude: 52.52,
        longitude: 13.405,
      ),
      const RawEphemeris(
        ascendant: 125, // 5 Leo
        ayanamsaValue: 23.85,
        bodies: [
          RawBodyPosition(
              graha: Graha.sun, siderealLongitude: 100, latitude: 0, speed: 1),
          RawBodyPosition(
              graha: Graha.moon, siderealLongitude: 40, latitude: 0, speed: 13),
          RawBodyPosition(
              graha: Graha.saturn,
              siderealLongitude: 190,
              latitude: 0,
              speed: -0.02),
          RawBodyPosition(
              graha: Graha.rahu,
              siderealLongitude: 60,
              latitude: 0,
              speed: -0.05),
        ],
      ),
    );

Map<String, Object?> ruleSet(List<Map<String, Object?>> rules) => {
      'version': '1.0.0',
      'name': 'test',
      'rules': rules,
    };

Map<String, Object?> rule(
  String id,
  List<Map<String, Object?>> conditions, {
  num? strength,
  List<String>? cancelledBy,
}) =>
    {
      'id': id,
      'conditions': conditions,
      if (strength != null) 'strength': strength,
      if (cancelledBy != null) 'cancelledBy': cancelledBy,
    };

void main() {
  const evaluator = DefaultRuleEvaluator();
  final chart = testChart();

  group('Matching', () {
    test('returns a match when the single condition holds', () {
      // Saturn at 10 Libra is in the third house from a Leo ascendant.
      final matches = evaluator.evaluate(
        chart,
        ruleSet([
          rule('saturn_third', [
            {
              'subject': 'positions.saturn.house',
              'operator': 'equals',
              'value': 3
            },
          ]),
        ]),
      );
      expect(matches, hasLength(1));
      expect(matches.single.ruleId, 'saturn_third');
      expect(matches.single.ruleSetVersion, '1.0.0');
    });

    test('returns nothing when the condition does not hold', () {
      final matches = evaluator.evaluate(
        chart,
        ruleSet([
          rule('saturn_first', [
            {
              'subject': 'positions.saturn.house',
              'operator': 'equals',
              'value': 1
            },
          ]),
        ]),
      );
      expect(matches, isEmpty);
    });

    test('requires every condition of a rule to hold', () {
      final both = evaluator.evaluate(
        chart,
        ruleSet([
          rule('both', [
            {
              'subject': 'positions.saturn.house',
              'operator': 'equals',
              'value': 3
            },
            {
              'subject': 'positions.saturn.dignity',
              'operator': 'equals',
              'value': 'exalted'
            },
          ]),
        ]),
      );
      expect(both, hasLength(1));

      final oneFails = evaluator.evaluate(
        chart,
        ruleSet([
          rule('one_fails', [
            {
              'subject': 'positions.saturn.house',
              'operator': 'equals',
              'value': 3
            },
            {
              'subject': 'positions.saturn.dignity',
              'operator': 'equals',
              'value': 'debilitated'
            },
          ]),
        ]),
      );
      expect(oneFails, isEmpty);
    });

    test('carries the evidence that satisfied the rule', () {
      final matches = evaluator.evaluate(
        chart,
        ruleSet([
          rule('saturn_third', [
            {
              'subject': 'positions.saturn.house',
              'operator': 'equals',
              'value': 3
            },
            {
              'subject': 'positions.saturn.isRetrograde',
              'operator': 'equals',
              'value': true
            },
          ]),
        ]),
      );
      expect(matches.single.evidence, {
        'positions.saturn.house': 3,
        'positions.saturn.isRetrograde': true,
      });
    });

    test('carries strength, defaulting to 1', () {
      final matches = evaluator.evaluate(
        chart,
        ruleSet([
          rule(
              'weak',
              [
                {'subject': 'ascendantSign', 'operator': 'equals', 'value': 4},
              ],
              strength: 0.25),
          rule('default', [
            {'subject': 'ascendantSign', 'operator': 'equals', 'value': 4},
          ]),
        ]),
      );
      expect(matches.map((m) => m.strength).toList(), [0.25, 1.0]);
    });

    test('returns no prose, only identifiers and evidence', () {
      final matches = evaluator.evaluate(
        chart,
        ruleSet([
          rule('r', [
            {'subject': 'ascendantSign', 'operator': 'equals', 'value': 4},
          ]),
        ]),
      );
      expect(matches.single.toJson().keys.toSet(), {
        'ruleId',
        'ruleSetVersion',
        'evidence',
        'strength',
      });
    });
  });

  group('Operators', () {
    List<RuleMatch> match(String operator, Object? value,
            {String subject = 'positions.saturn.house'}) =>
        evaluator.evaluate(
          chart,
          ruleSet([
            rule('r', [
              {'subject': subject, 'operator': operator, 'value': value},
            ]),
          ]),
        );

    test('equals and notEquals', () {
      expect(match('equals', 3), hasLength(1));
      expect(match('equals', 4), isEmpty);
      expect(match('notEquals', 4), hasLength(1));
      expect(match('notEquals', 3), isEmpty);
    });

    test('in and notIn', () {
      expect(match('in', [1, 3, 5]), hasLength(1));
      expect(match('in', [1, 2]), isEmpty);
      expect(match('notIn', [1, 2]), hasLength(1));
      expect(match('notIn', [1, 3]), isEmpty);
    });

    test('greaterThan and lessThan', () {
      expect(match('greaterThan', 2), hasLength(1));
      expect(match('greaterThan', 3), isEmpty);
      expect(match('lessThan', 4), hasLength(1));
      expect(match('lessThan', 3), isEmpty);
    });

    test('between is inclusive of both bounds', () {
      expect(match('between', [3, 5]), hasLength(1));
      expect(match('between', [1, 3]), hasLength(1));
      expect(match('between', [4, 6]), isEmpty);
    });

    test('compares strings, for enum-valued fields', () {
      expect(
        match('equals', 'exalted', subject: 'positions.saturn.dignity'),
        hasLength(1),
      );
      expect(
        match('in', ['exalted', 'ownSign'],
            subject: 'positions.saturn.dignity'),
        hasLength(1),
      );
    });
  });

  group('Cancellation', () {
    test('a matched canceller removes the rule it cancels', () {
      final matches = evaluator.evaluate(
        chart,
        ruleSet([
          rule('cancelled', [
            {'subject': 'ascendantSign', 'operator': 'equals', 'value': 4},
          ], cancelledBy: [
            'canceller'
          ]),
          rule('canceller', [
            {
              'subject': 'positions.saturn.house',
              'operator': 'equals',
              'value': 3
            },
          ]),
        ]),
      );
      expect(matches.map((m) => m.ruleId).toList(), ['canceller']);
    });

    test('an unmatched canceller leaves the rule standing', () {
      final matches = evaluator.evaluate(
        chart,
        ruleSet([
          rule('survives', [
            {'subject': 'ascendantSign', 'operator': 'equals', 'value': 4},
          ], cancelledBy: [
            'never_matches'
          ]),
          rule('never_matches', [
            {
              'subject': 'positions.saturn.house',
              'operator': 'equals',
              'value': 11
            },
          ]),
        ]),
      );
      expect(matches.map((m) => m.ruleId).toList(), ['survives']);
    });
  });

  group('Divisional charts', () {
    test('evaluates a condition against a supplied varga', () {
      final rasi = testChart();
      final navamsa = computeDivisionalChart(rasi, Varga.d9);
      final withD9 =
          DefaultRuleEvaluator(divisionalCharts: {Varga.d9: navamsa});

      final expectedSign = navamsa.positions[Graha.saturn]!.sign;
      final matches = withD9.evaluate(
        rasi,
        ruleSet([
          rule('saturn_navamsa', [
            {
              'chart': 'd9',
              'subject': 'positions.saturn.sign',
              'operator': 'equals',
              'value': expectedSign,
            },
          ]),
        ]),
      );
      expect(matches, hasLength(1));
      expect(matches.single.evidence.keys.single, 'd9.positions.saturn.sign');
    });

    test('throws when a rule needs a varga that was not supplied', () {
      expect(
        () => evaluator.evaluate(
          chart,
          ruleSet([
            rule('needs_d9', [
              {
                'chart': 'd9',
                'subject': 'positions.saturn.sign',
                'operator': 'equals',
                'value': 0,
              },
            ]),
          ]),
        ),
        throwsArgumentError,
      );
    });
  });

  group('Malformed input', () {
    test('rejects a rule set with no version', () {
      expect(
        () => evaluator.evaluate(chart, {'name': 'x', 'rules': <Object?>[]}),
        throwsArgumentError,
      );
    });

    test('rejects a rule set with no rules', () {
      expect(
        () => evaluator
            .evaluate(chart, {'version': '1.0.0', 'rules': <Object?>[]}),
        throwsArgumentError,
      );
    });

    test('rejects a rule with no id', () {
      expect(
        () => evaluator.evaluate(
            chart,
            ruleSet([
              {
                'conditions': [
                  {
                    'subject': 'ascendantSign',
                    'operator': 'equals',
                    'value': 4
                  },
                ],
              },
            ])),
        throwsArgumentError,
      );
    });

    test(
        'throws on a path that does not exist rather than silently not matching',
        () {
      // A typo in a rule set is a configuration error. Reporting it as "no match"
      // would be indistinguishable from a correctly evaluated false.
      expect(
        () => evaluator.evaluate(
          chart,
          ruleSet([
            rule('typo', [
              {
                'subject': 'positions.saturn.hous',
                'operator': 'equals',
                'value': 3
              },
            ]),
          ]),
        ),
        throwsArgumentError,
      );
    });

    test('throws on a body the chart does not contain', () {
      expect(
        () => evaluator.evaluate(
          chart,
          ruleSet([
            rule('absent', [
              {
                'subject': 'positions.venus.house',
                'operator': 'equals',
                'value': 3
              },
            ]),
          ]),
        ),
        throwsArgumentError,
      );
    });

    test('throws on an unknown operator', () {
      expect(
        () => evaluator.evaluate(
          chart,
          ruleSet([
            rule('bad_op', [
              {
                'subject': 'ascendantSign',
                'operator': 'approximately',
                'value': 4
              },
            ]),
          ]),
        ),
        throwsArgumentError,
      );
    });

    test('throws on an unknown chart name', () {
      expect(
        () => evaluator.evaluate(
          chart,
          ruleSet([
            rule('bad_chart', [
              {
                'chart': 'd16',
                'subject': 'ascendantSign',
                'operator': 'equals',
                'value': 4,
              },
            ]),
          ]),
        ),
        throwsArgumentError,
      );
    });

    test('throws when a numeric operator is given a non-number', () {
      expect(
        () => evaluator.evaluate(
          chart,
          ruleSet([
            rule('bad_type', [
              {
                'subject': 'positions.saturn.dignity',
                'operator': 'greaterThan',
                'value': 3,
              },
            ]),
          ]),
        ),
        throwsArgumentError,
      );
    });

    test('throws when between is not given exactly two bounds', () {
      expect(
        () => evaluator.evaluate(
          chart,
          ruleSet([
            rule('bad_bounds', [
              {
                'subject': 'positions.saturn.house',
                'operator': 'between',
                'value': [1, 2, 3],
              },
            ]),
          ]),
        ),
        throwsArgumentError,
      );
    });
  });

  group('Bundled example rule set', () {
    test('the schema example evaluates without error', () {
      // packages/rules/examples/minimal.json in structural form.
      final matches = evaluator.evaluate(
        chart,
        {
          'version': '0.1.0',
          'name': 'minimal',
          'rules': [
            {
              'id': 'saturn-in-third',
              'source': 'Test fixture',
              'conditions': [
                {
                  'subject': 'positions.saturn.house',
                  'operator': 'equals',
                  'value': 3,
                },
              ],
            },
          ],
        },
      );
      expect(matches.single.ruleId, 'saturn-in-third');
    });
  });
}
