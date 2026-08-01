import 'package:meta/meta.dart';

import 'chart.dart';

/// Result of evaluating one rule against a chart.
///
/// Deliberately carries no prose. The evaluator returns the rule identifier and the
/// facts that satisfied it; the consuming application supplies interpretation text.
/// This keeps content out of an AGPL-licensed package and lets applications version
/// their interpretations independently of the engine.
@immutable
class RuleMatch {
  const RuleMatch({
    required this.ruleId,
    required this.ruleSetVersion,
    required this.evidence,
    this.strength = 1.0,
  });

  final String ruleId;
  final String ruleSetVersion;

  /// The chart facts that caused this rule to match, for explainability.
  final Map<String, Object?> evidence;

  /// 0.0 to 1.0. Meaning is defined by the rule set, not the engine.
  final double strength;

  Map<String, Object?> toJson() => {
        'ruleId': ruleId,
        'ruleSetVersion': ruleSetVersion,
        'evidence': evidence,
        'strength': strength,
      };
}

/// Evaluates externally supplied rule sets against a computed chart.
abstract interface class RuleEvaluator {
  /// Rule sets conform to `packages/rules/schema/rule-set.schema.json`.
  List<RuleMatch> evaluate(Chart chart, Map<String, Object?> ruleSet);
}
