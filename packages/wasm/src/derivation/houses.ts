import { normaliseDegrees } from './math.js';
import { rasiFromIndex, rasiFromLongitude } from './rasi.js';
import type { HouseSystem } from './types.js';

/** Whole-sign cusps: the ascendant's entire sign is the first house. */
export function wholeSignCusps(ascendantSign: number): number[] {
  return Array.from({ length: 12 }, (_, i) => rasiFromIndex(ascendantSign + i) * 30);
}

/** Equal cusps: each house spans 30 degrees from the ascendant degree. */
export function equalCusps(ascendant: number): number[] {
  return Array.from({ length: 12 }, (_, i) => normaliseDegrees(ascendant + i * 30));
}

/** Cusps for systems derivable without an ephemeris. Quadrant systems throw. */
export function cuspsFor(system: HouseSystem, ascendant: number): number[] {
  switch (system) {
    case 'wholeSign': return wholeSignCusps(rasiFromLongitude(ascendant));
    case 'equal': return equalCusps(ascendant);
    default:
      throw new Error(
        `${system} cusps are ephemeris-derived and cannot be computed here. ` +
          'Supply them via RawEphemeris.houseCusps.',
      );
  }
}

/**
 * House, 1 to 12, containing a longitude. House n spans cusps[n-1] up to but
 * excluding cusps[n]. Throws when the cusps do not cover the circle, which happens
 * when a quadrant system degenerates at extreme latitude: a silently wrong house is
 * a wrong chart.
 */
export function houseOfLongitude(longitude: number, cusps: readonly number[]): number {
  if (cusps.length !== 12) throw new Error(`Expected 12 cusps, got ${cusps.length}.`);
  const lon = normaliseDegrees(longitude);

  for (let i = 0; i < 12; i++) {
    const start = normaliseDegrees(cusps[i] ?? 0);
    const end = normaliseDegrees(cusps[(i + 1) % 12] ?? 0);
    const within = start <= end ? lon >= start && lon < end : lon >= start || lon < end;
    if (within) return i + 1;
  }

  throw new Error(
    `Longitude ${lon} falls in no house. The cusps do not cover the circle, which ` +
      'indicates a degenerate quadrant house system at this latitude.',
  );
}
