import { dartMod, normaliseDegrees } from './math.js';
import type { Graha } from './types.js';

export type Modality = 'movable' | 'fixed' | 'dual';

export const RASI_NAMES = [
  'Mesha', 'Vrishabha', 'Mithuna', 'Karka', 'Simha', 'Kanya',
  'Tula', 'Vrishchika', 'Dhanu', 'Makara', 'Kumbha', 'Meena',
] as const;

/** Rasi index for any integer, wrapping in both directions. */
export function rasiFromIndex(index: number): number {
  return dartMod(index, 12);
}

/** Sign occupied by a sidereal longitude. */
export function rasiFromLongitude(siderealLongitude: number): number {
  return rasiFromIndex(Math.floor(normaliseDegrees(siderealLongitude) / 30));
}

/**
 * Ruling graha. Rahu and Ketu are given no rulership: classical sources do not agree
 * on one, and inventing it here would silently affect dignity.
 */
export function rasiLord(sign: number): Graha {
  switch (rasiFromIndex(sign)) {
    case 0: case 7: return 'mars';
    case 1: case 6: return 'venus';
    case 2: case 5: return 'mercury';
    case 3: return 'moon';
    case 4: return 'sun';
    case 8: case 11: return 'jupiter';
    default: return 'saturn';
  }
}

export function rasiModality(sign: number): Modality {
  return (['movable', 'fixed', 'dual'] as const)[rasiFromIndex(sign) % 3] ?? 'movable';
}

/** Odd (vishama) signs are the 1st, 3rd, 5th and so on: even zero-based indices. */
export function rasiIsOdd(sign: number): boolean {
  return rasiFromIndex(sign) % 2 === 0;
}
