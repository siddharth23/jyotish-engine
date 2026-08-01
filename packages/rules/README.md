# Rule sets

The engine evaluates rule sets it is given. It does not ship any.

This separation is deliberate. Interpretation rules and their accompanying text are the
product's substance, and keeping them out of an AGPL-licensed package means applications can
version their interpretations independently of the engine and are not obliged to publish
them.

## Format

Rule sets are JSON conforming to [`schema/rule-set.schema.json`](schema/rule-set.schema.json).
`examples/` contains a minimal illustrative set — it is a format demonstration, not an
astrological reference.

## What the evaluator returns

Rule identifiers, the chart facts that satisfied them, and a strength value. **Never prose.**
The consuming application maps identifiers to text in whatever language and register it needs.

## Versioning

Every rule set declares a `version`. Consuming applications must record which version produced
a given analysis, so a result delivered to a user remains reproducible after the rules change.
