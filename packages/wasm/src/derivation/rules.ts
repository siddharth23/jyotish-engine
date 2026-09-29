import { computeDivisionalChart } from './chart.js';
import { VARGAS, type Chart, type RuleMatch, type Varga } from './types.js';

type Json = Record<string, unknown>;

function isObject(value: unknown): value is Json {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function asList(value: unknown, operator: string, ruleId: string): unknown[] {
  if (Array.isArray(value)) return value;
  throw new Error(`Rule "${ruleId}" operator "${operator}" needs a list value.`);
}

function asNum(value: unknown, operator: string, ruleId: string): number {
  if (typeof value === 'number') return value;
  throw new Error(`Rule "${ruleId}" operator "${operator}" needs numbers, got ${typeof value}.`);
}

function applyOperator(operator: string, actual: unknown, expected: unknown, ruleId: string): boolean {
  switch (operator) {
    case 'equals': return actual === expected;
    case 'notEquals': return actual !== expected;
    case 'in': return asList(expected, operator, ruleId).includes(actual);
    case 'notIn': return !asList(expected, operator, ruleId).includes(actual);
    case 'greaterThan': return asNum(actual, operator, ruleId) > asNum(expected, operator, ruleId);
    case 'lessThan': return asNum(actual, operator, ruleId) < asNum(expected, operator, ruleId);
    case 'between': {
      const bounds = asList(expected, operator, ruleId);
      if (bounds.length !== 2) {
        throw new Error(`Rule "${ruleId}" operator "between" needs exactly two bounds.`);
      }
      const value = asNum(actual, operator, ruleId);
      return value >= asNum(bounds[0], operator, ruleId) && value <= asNum(bounds[1], operator, ruleId);
    }
    default:
      throw new Error(`Rule "${ruleId}" uses unknown operator "${operator}".`);
  }
}

function resolvePath(json: unknown, path: string, ruleId: string): unknown {
  let cursor = json;
  for (const segment of path.split('.')) {
    if (!isObject(cursor)) {
      throw new Error(`Rule "${ruleId}" path "${path}" descends into a non-object at "${segment}".`);
    }
    if (!(segment in cursor)) {
      throw new Error(`Rule "${ruleId}" path "${path}" has no key "${segment}" in this chart.`);
    }
    cursor = cursor[segment];
  }
  return cursor;
}

/**
 * Evaluates a rule set conforming to packages/rules/schema/rule-set.schema.json.
 *
 * A rule matches when every condition holds. Conditions address the chart's JSON form
 * by dotted path. Returns identifiers and evidence, never prose. Divisional charts a
 * rule names are derived from the rasi chart on demand, so a rule can never silently
 * fail to match for want of a chart.
 */
export function evaluateRules(chart: Chart, ruleSet: unknown): RuleMatch[] {
  if (!isObject(ruleSet) || typeof ruleSet['version'] !== 'string') {
    throw new Error('Rule set is missing a string "version".');
  }
  const version = ruleSet['version'];
  const rules = ruleSet['rules'];
  if (!Array.isArray(rules) || rules.length === 0) {
    throw new Error('Rule set is missing a non-empty "rules" array.');
  }

  const charts = new Map<Varga, unknown>([['d1', chart]]);
  const chartFor = (varga: Varga): unknown => {
    let json = charts.get(varga);
    if (json === undefined) {
      json = computeDivisionalChart(chart, varga);
      charts.set(varga, json);
    }
    return json;
  };

  const matches: RuleMatch[] = [];
  const cancellations = new Map<string, string[]>();

  for (const rule of rules) {
    if (!isObject(rule)) throw new Error('Every entry in "rules" must be an object.');
    const id = rule['id'];
    if (typeof id !== 'string') throw new Error('Every rule needs a string "id".');
    const conditions = rule['conditions'];
    if (!Array.isArray(conditions) || conditions.length === 0) {
      throw new Error(`Rule "${id}" needs a non-empty "conditions" array.`);
    }

    const evidence: Record<string, unknown> = {};
    let allHold = true;

    for (const condition of conditions) {
      if (!isObject(condition)) throw new Error(`Every condition in rule "${id}" must be an object.`);
      const subject = condition['subject'];
      const operator = condition['operator'];
      if (typeof subject !== 'string') throw new Error(`A condition in rule "${id}" is missing "subject".`);
      if (typeof operator !== 'string') throw new Error(`A condition in rule "${id}" is missing "operator".`);
      const chartName = condition['chart'] ?? 'd1';
      if (typeof chartName !== 'string' || !(VARGAS as readonly string[]).includes(chartName)) {
        throw new Error(`Rule "${id}" names an unknown chart "${String(chartName)}".`);
      }
      const varga = chartName as Varga;
      const actual = resolvePath(chartFor(varga), subject, id);
      evidence[varga === 'd1' ? subject : `${varga}.${subject}`] = actual;
      if (!applyOperator(operator, actual, condition['value'], id)) {
        allHold = false;
        break;
      }
    }
    if (!allHold) continue;

    const cancelledBy = rule['cancelledBy'];
    if (Array.isArray(cancelledBy)) cancellations.set(id, cancelledBy.map(String));
    const strength = rule['strength'];
    matches.push({
      ruleId: id,
      ruleSetVersion: version,
      evidence,
      strength: typeof strength === 'number' ? strength : 1,
    });
  }

  const matched = new Set(matches.map((m) => m.ruleId));
  return matches.filter((m) => !(cancellations.get(m.ruleId) ?? []).some((c) => matched.has(c)));
}
