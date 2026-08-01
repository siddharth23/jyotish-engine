import 'chart.dart';
import 'divisional.dart';
import 'rules.dart';

/// Evaluates rule sets conforming to `packages/rules/schema/rule-set.schema.json`.
///
/// A rule matches when **every** one of its conditions holds. Conditions address
/// chart facts by dotted path — `positions.saturn.house`, `ascendantSign` — resolved
/// against the chart's JSON form, which is also the form stored by consuming
/// applications. Evaluating against the serialised shape rather than the object graph
/// keeps rule sets stable across engine refactors.
///
/// The evaluator returns identifiers and evidence, never prose. What a match *means*
/// is the consuming application's business.
///
/// Conditions naming a divisional chart require that chart to have been supplied to
/// the constructor; a rule set that asks for D9 when no D9 was provided throws rather
/// than quietly failing to match, since a silently unmatched rule looks identical to
/// a rule that was correctly evaluated and found false.
class DefaultRuleEvaluator implements RuleEvaluator {
  const DefaultRuleEvaluator({this.divisionalCharts = const {}});

  /// Divisional charts available to conditions that name one. The rasi chart is
  /// passed to [evaluate] directly and need not appear here.
  final Map<Varga, Chart> divisionalCharts;

  @override
  List<RuleMatch> evaluate(Chart chart, Map<String, Object?> ruleSet) {
    final version = ruleSet['version'];
    if (version is! String) {
      throw ArgumentError('Rule set is missing a string "version".');
    }
    final rules = ruleSet['rules'];
    if (rules is! List || rules.isEmpty) {
      throw ArgumentError('Rule set is missing a non-empty "rules" array.');
    }

    final serialised = <Varga, Map<String, Object?>>{
      Varga.d1: chart.toJson(),
      for (final entry in divisionalCharts.entries)
        entry.key: entry.value.toJson(),
    };

    final matches = <RuleMatch>[];
    final cancellations = <String, List<String>>{};

    for (final rule in rules) {
      if (rule is! Map<String, Object?>) {
        throw ArgumentError('Every entry in "rules" must be an object.');
      }
      final id = rule['id'];
      if (id is! String) {
        throw ArgumentError('Every rule needs a string "id".');
      }
      final conditions = rule['conditions'];
      if (conditions is! List || conditions.isEmpty) {
        throw ArgumentError('Rule "$id" needs a non-empty "conditions" array.');
      }

      final evidence = <String, Object?>{};
      var allHold = true;

      for (final condition in conditions) {
        if (condition is! Map<String, Object?>) {
          throw ArgumentError(
              'Every condition in rule "$id" must be an object.');
        }
        final outcome = _evaluateCondition(condition, serialised, id);
        evidence[outcome.evidenceKey] = outcome.actual;
        if (!outcome.holds) {
          allHold = false;
          break;
        }
      }

      if (!allHold) continue;

      final cancelledBy = rule['cancelledBy'];
      if (cancelledBy is List) {
        cancellations[id] = [for (final other in cancelledBy) other.toString()];
      }

      final strength = rule['strength'];
      matches.add(
        RuleMatch(
          ruleId: id,
          ruleSetVersion: version,
          evidence: evidence,
          strength: strength is num ? strength.toDouble() : 1.0,
        ),
      );
    }

    final matchedIds = {for (final match in matches) match.ruleId};
    return [
      for (final match in matches)
        if (!(cancellations[match.ruleId] ?? const []).any(matchedIds.contains))
          match,
    ];
  }

  _ConditionOutcome _evaluateCondition(
    Map<String, Object?> condition,
    Map<Varga, Map<String, Object?>> serialised,
    String ruleId,
  ) {
    final subject = condition['subject'];
    if (subject is! String) {
      throw ArgumentError(
          'A condition in rule "$ruleId" is missing "subject".');
    }
    final operator = condition['operator'];
    if (operator is! String) {
      throw ArgumentError(
          'A condition in rule "$ruleId" is missing "operator".');
    }

    final chartName = condition['chart'] as String? ?? Varga.d1.name;
    final Varga varga;
    try {
      varga = Varga.values.byName(chartName);
    } on ArgumentError {
      throw ArgumentError(
          'Rule "$ruleId" names an unknown chart "$chartName".');
    }
    final json = serialised[varga];
    if (json == null) {
      throw ArgumentError(
        'Rule "$ruleId" needs the $chartName chart, which was not supplied to the '
        'evaluator.',
      );
    }

    final actual = _resolvePath(json, subject, ruleId);
    final expected = condition['value'];

    return _ConditionOutcome(
      evidenceKey: varga == Varga.d1 ? subject : '$chartName.$subject',
      actual: actual,
      holds: _applyOperator(operator, actual, expected, ruleId),
    );
  }

  Object? _resolvePath(Map<String, Object?> json, String path, String ruleId) {
    Object? cursor = json;
    for (final segment in path.split('.')) {
      if (cursor is! Map<String, Object?>) {
        throw ArgumentError(
          'Rule "$ruleId" path "$path" descends into a non-object at "$segment".',
        );
      }
      if (!cursor.containsKey(segment)) {
        throw ArgumentError(
          'Rule "$ruleId" path "$path" has no key "$segment" in this chart.',
        );
      }
      cursor = cursor[segment];
    }
    return cursor;
  }

  bool _applyOperator(
    String operator,
    Object? actual,
    Object? expected,
    String ruleId,
  ) {
    switch (operator) {
      case 'equals':
        return actual == expected;
      case 'notEquals':
        return actual != expected;
      case 'in':
        return _asList(expected, operator, ruleId).contains(actual);
      case 'notIn':
        return !_asList(expected, operator, ruleId).contains(actual);
      case 'greaterThan':
        return _asNum(actual, operator, ruleId) >
            _asNum(expected, operator, ruleId);
      case 'lessThan':
        return _asNum(actual, operator, ruleId) <
            _asNum(expected, operator, ruleId);
      case 'between':
        final bounds = _asList(expected, operator, ruleId);
        if (bounds.length != 2) {
          throw ArgumentError(
            'Rule "$ruleId" operator "between" needs exactly two bounds.',
          );
        }
        final value = _asNum(actual, operator, ruleId);
        final lower = _asNum(bounds[0], operator, ruleId);
        final upper = _asNum(bounds[1], operator, ruleId);
        return value >= lower && value <= upper;
      default:
        throw ArgumentError(
            'Rule "$ruleId" uses unknown operator "$operator".');
    }
  }

  List<Object?> _asList(Object? value, String operator, String ruleId) {
    if (value is List) return value;
    throw ArgumentError(
        'Rule "$ruleId" operator "$operator" needs a list value.');
  }

  num _asNum(Object? value, String operator, String ruleId) {
    if (value is num) return value;
    throw ArgumentError(
      'Rule "$ruleId" operator "$operator" needs numbers, got ${value.runtimeType}.',
    );
  }
}

class _ConditionOutcome {
  const _ConditionOutcome({
    required this.evidenceKey,
    required this.actual,
    required this.holds,
  });

  final String evidenceKey;
  final Object? actual;
  final bool holds;
}
