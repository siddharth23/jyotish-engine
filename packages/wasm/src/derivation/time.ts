/**
 * Microsecond-precision UTC instants.
 *
 * Dasha boundaries are computed in integer microseconds, like the Dart package. A
 * JavaScript number cannot hold microseconds beyond roughly 285 years from 1970, and
 * the engine supports 1800-2399, so instants are bigint.
 */

const MICROS_PER_MILLI = 1000n;

/** Parses an ISO-8601 UTC string. Throws unless it names an unambiguous UTC instant. */
export function parseUtcMicros(iso: string): bigint {
  if (!/(Z|[+-]00:?00)$/.test(iso)) {
    throw new Error(`Expected a UTC ISO-8601 timestamp ending in Z, got "${iso}".`);
  }
  const millis = Date.parse(iso);
  if (Number.isNaN(millis)) throw new Error(`Invalid timestamp "${iso}".`);
  const fraction = /\.(\d+)/.exec(iso)?.[1] ?? '';
  const extraMicros = fraction.length > 3 ? BigInt(fraction.slice(3, 6).padEnd(3, '0')) : 0n;
  return BigInt(millis) * MICROS_PER_MILLI + extraMicros;
}

function pad(value: number, width: number): string {
  return String(value).padStart(width, '0');
}

/**
 * Formats like Dart's `DateTime.toIso8601String()` for a UTC instant:
 * `yyyy-MM-ddTHH:mm:ss.mmmZ`, with three further digits only when the microsecond
 * component is non-zero.
 */
export function formatUtcMicros(micros: bigint): string {
  let millis = micros / MICROS_PER_MILLI;
  let extra = micros % MICROS_PER_MILLI;
  if (extra < 0n) {
    extra += MICROS_PER_MILLI;
    millis -= 1n;
  }
  const date = new Date(Number(millis));
  const base =
    `${pad(date.getUTCFullYear(), 4)}-${pad(date.getUTCMonth() + 1, 2)}-${pad(date.getUTCDate(), 2)}` +
    `T${pad(date.getUTCHours(), 2)}:${pad(date.getUTCMinutes(), 2)}:${pad(date.getUTCSeconds(), 2)}` +
    `.${pad(date.getUTCMilliseconds(), 3)}`;
  return extra === 0n ? `${base}Z` : `${base}${pad(Number(extra), 3)}Z`;
}

export function formatUtcMillis(millis: number): string {
  return formatUtcMicros(BigInt(Math.round(millis)) * MICROS_PER_MILLI);
}

/** Julian day (UT) of a millisecond timestamp. */
export function julianDayFromMillis(millis: number): number {
  return millis / 86_400_000 + 2_440_587.5;
}

export function millisFromJulianDay(jd: number): number {
  return (jd - 2_440_587.5) * 86_400_000;
}
