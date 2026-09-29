/**
 * Arithmetic helpers that reproduce the Dart package's numeric semantics exactly.
 *
 * Dart's `%` on doubles is Euclidean and JavaScript's is a truncated remainder. They
 * differ for negative operands, so every modulo in the derivation goes through
 * {@link dartMod} to keep the two builds producing identical values.
 */

/** Dart's `double % double`: the result always has the sign of the divisor. */
export function dartMod(a: number, b: number): number {
  const r = a % b;
  if (r === 0) return 0;
  return r < 0 ? r + Math.abs(b) : r;
}

/** Wraps degrees into 0 (inclusive) to 360. Mirrors `normaliseDegrees` in Dart. */
export function normaliseDegrees(degrees: number): number {
  const wrapped = dartMod(degrees, 360);
  return wrapped < 0 ? wrapped + 360 : wrapped;
}

/** Shortest angular separation between two longitudes, 0 to 180 degrees. */
export function angularSeparation(a: number, b: number): number {
  const diff = Math.abs(normaliseDegrees(a) - normaliseDegrees(b));
  return diff > 180 ? 360 - diff : diff;
}

export function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}
