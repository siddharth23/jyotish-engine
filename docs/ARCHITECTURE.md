# Architecture

## Design goals

1. **Deterministic.** Identical inputs and identical engine version always produce identical
   output, byte for byte, on every platform.
2. **Versioned.** Every result carries the engine version that produced it, so a chart
   computed today remains reproducible after future changes.
3. **Free of business logic.** Facts and generic rule evaluation only. No interpretation.
4. **Client-executable.** Small enough and fast enough to run on a mid-range phone.

## Layers

```
┌────────────────────────────────────────────────────────────┐
│ Public API                                                  │
│   computeChart() · computeDashas() · computePanchang()      │
│   computeTransits() · evaluateRules()                       │
├────────────────────────────────────────────────────────────┤
│ Domain                                                      │
│   Sidereal conversion · house systems · divisional charts   │
│   Vimshottari cycle · dignity scoring · nakshatra mapping   │
├────────────────────────────────────────────────────────────┤
│ Rule evaluator                                              │
│   Generic predicate engine over externally supplied JSON    │
├────────────────────────────────────────────────────────────┤
│ Platform bindings                                           │
│   Dart FFI (mobile)          │  WASM + TS wrapper (browser) │
├────────────────────────────────────────────────────────────┤
│ Swiss Ephemeris (C) — AGPL                                  │
└────────────────────────────────────────────────────────────┘
```

## Determinism

Determinism is a hard requirement, not an aspiration. A chart delivered to a paying customer
must be reproducible years later during a dispute.

- No floating-point formatting differences between platforms; all output rounded explicitly
  at defined precision before serialisation.
- No dependence on system time, locale, or timezone in the computation path. The caller
  supplies UTC.
- No map or set iteration order in serialised output; all collections explicitly ordered.
- Engine version embedded in every result object.

The shared test-vector suite is what proves this. Dart and WASM must agree exactly.

## Timezone handling

The engine accepts **UTC only**. Local-time-to-UTC conversion is the caller's responsibility
and the single most common source of error in astrology software.

Callers must resolve the offset using the IANA database keyed on *both* coordinates *and* the
historical date. Notable traps:

- Germany: double summer time 1945–1949; no DST 1950–1979.
- India: Calcutta local time +05:53:20 before 1955; IST +05:30 after.
- Ambiguous local times during a DST fall-back hour require an explicit caller choice.

`docs/ACCURACY.md` lists the vectors covering these.

## Rule evaluator

Rule sets are supplied by the caller as JSON conforming to `packages/rules/schema/`. The
evaluator matches predicates against a computed chart and returns matched rule identifiers
with the facts that satisfied them.

It returns **identifiers and evidence, never prose**. Interpretation text lives in the
consuming application. This keeps the engine free of content and lets consumers version their
interpretations independently of the engine.
