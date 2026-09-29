import { nakshatraElapsedFraction, nakshatraFromLongitude, nakshatraLord, VIMSHOTTARI_ORDER } from './nakshatra.js';
import { formatUtcMicros, parseUtcMicros } from './time.js';
import type { DashaPeriod, Graha } from './types.js';

/** Years allotted to each graha in the 120-year cycle. */
export const VIMSHOTTARI_YEARS: Readonly<Record<Graha, number>> = {
  ketu: 7, venus: 20, sun: 6, moon: 10, mars: 7, rahu: 18, jupiter: 16, saturn: 19, mercury: 17,
};

/**
 * Days in a Vimshottari year. Julian years, as mainstream software uses. Changing this
 * changes every dasha date ever produced and must bump the engine version.
 */
export const VIMSHOTTARI_YEAR_DAYS = 365.25;
export const VIMSHOTTARI_CYCLE_YEARS = 120;
const MICROS_PER_DAY = 86_400_000_000;

function yearsToMicros(years: number): bigint {
  return BigInt(Math.round(years * VIMSHOTTARI_YEAR_DAYS * MICROS_PER_DAY));
}

/** `(duration * cumulativeYears / 120).round()` with Dart's int-to-double semantics. */
function proportion(durationMicros: bigint, cumulativeYears: number): bigint {
  const product = Number(durationMicros * BigInt(cumulativeYears));
  return BigInt(Math.round(product / VIMSHOTTARI_CYCLE_YEARS));
}

function subdivide(
  lord: Graha,
  startMicros: bigint,
  durationMicros: bigint,
  level: number,
  maxLevel: number,
): DashaPeriod[] {
  if (level > maxLevel) return [];

  const periods: DashaPeriod[] = [];
  const lordIndex = VIMSHOTTARI_ORDER.indexOf(lord);
  let cumulativeYears = 0;

  for (let i = 0; i < 9; i++) {
    const subLord = VIMSHOTTARI_ORDER[(lordIndex + i) % 9] ?? 'ketu';
    const subStart = startMicros + proportion(durationMicros, cumulativeYears);
    cumulativeYears += VIMSHOTTARI_YEARS[subLord];
    const subEnd = startMicros + proportion(durationMicros, cumulativeYears);
    periods.push(period(subLord, subStart, subEnd, level,
      subdivide(subLord, subStart, subEnd - subStart, level + 1, maxLevel)));
  }
  return periods;
}

function period(
  lord: Graha,
  start: bigint,
  end: bigint,
  level: number,
  children: DashaPeriod[],
): DashaPeriod {
  const base = { lord, start: formatUtcMicros(start), end: formatUtcMicros(end), level };
  return children.length > 0 ? { ...base, children } : base;
}

/**
 * The Vimshottari dasha tree. The starting lord is the lord of the Moon's nakshatra,
 * and the fraction of that nakshatra already traversed is the fraction of the first
 * mahadasha already elapsed. Boundaries are true, not clipped to birth.
 *
 * depth 1 returns mahadashas, 2 adds antardashas, 3 adds pratyantardashas.
 */
export function computeVimshottariDashas(
  moonSiderealLongitude: number,
  birthUtc: string,
  depth = 3,
  coverageYears = VIMSHOTTARI_CYCLE_YEARS,
): DashaPeriod[] {
  if (!Number.isInteger(depth) || depth < 1 || depth > 3) {
    throw new Error('depth must be 1, 2 or 3.');
  }
  if (!(coverageYears > 0)) throw new Error('coverageYears must be positive.');

  const startLord = nakshatraLord(nakshatraFromLongitude(moonSiderealLongitude));
  const elapsedFraction = nakshatraElapsedFraction(moonSiderealLongitude);

  const birthMicros = parseUtcMicros(birthUtc);
  const elapsedMicros = yearsToMicros(VIMSHOTTARI_YEARS[startLord] * elapsedFraction);
  const coverUntil = birthMicros + yearsToMicros(coverageYears);

  const periods: DashaPeriod[] = [];
  let cursor = birthMicros - elapsedMicros;
  let lordIndex = VIMSHOTTARI_ORDER.indexOf(startLord);

  while (cursor < coverUntil) {
    const lord = VIMSHOTTARI_ORDER[lordIndex % 9] ?? 'ketu';
    const duration = yearsToMicros(VIMSHOTTARI_YEARS[lord]);
    periods.push(period(lord, cursor, cursor + duration, 1,
      subdivide(lord, cursor, duration, 2, depth)));
    cursor += duration;
    lordIndex++;
  }
  return periods;
}

/** The chain of periods running at an instant, outermost first. */
export function activeDashaChain(periods: readonly DashaPeriod[], instantUtc: string): DashaPeriod[] {
  const instant = parseUtcMicros(instantUtc);
  for (const p of periods) {
    if (parseUtcMicros(p.start) <= instant && instant < parseUtcMicros(p.end)) {
      return [p, ...activeDashaChain(p.children ?? [], instantUtc)];
    }
  }
  return [];
}
