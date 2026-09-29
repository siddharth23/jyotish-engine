import { angularSeparation } from './math.js';
import { rasiFromIndex, rasiLord } from './rasi.js';
import type { Dignity, Graha } from './types.js';

/**
 * Deep exaltation points: sign index and degree. Brihat Parashara Hora Shastra, ch. 3.
 * Rahu and Ketu are deliberately absent -- sources disagree.
 */
export const EXALTATION_POINTS: Readonly<Partial<Record<Graha, { sign: number; degree: number }>>> = {
  sun: { sign: 0, degree: 10 },
  moon: { sign: 1, degree: 3 },
  mars: { sign: 9, degree: 28 },
  mercury: { sign: 5, degree: 15 },
  jupiter: { sign: 3, degree: 5 },
  venus: { sign: 11, degree: 27 },
  saturn: { sign: 6, degree: 20 },
};

/** Natural (naisargika) friendship. Brihat Parashara Hora Shastra, ch. 3. */
export const NATURAL_FRIENDS: Readonly<Partial<Record<Graha, readonly Graha[]>>> = {
  sun: ['moon', 'mars', 'jupiter'],
  moon: ['sun', 'mercury'],
  mars: ['sun', 'moon', 'jupiter'],
  mercury: ['sun', 'venus'],
  jupiter: ['sun', 'moon', 'mars'],
  venus: ['mercury', 'saturn'],
  saturn: ['mercury', 'venus'],
};

export const NATURAL_ENEMIES: Readonly<Partial<Record<Graha, readonly Graha[]>>> = {
  sun: ['venus', 'saturn'],
  moon: [],
  mars: ['mercury'],
  mercury: ['moon'],
  jupiter: ['mercury', 'venus'],
  venus: ['sun', 'moon'],
  saturn: ['sun', 'moon', 'mars'],
};

export function isShadow(graha: Graha): boolean {
  return graha === 'rahu' || graha === 'ketu';
}

/**
 * Dignity of a graha in a sign, in classical precedence: exaltation, debilitation,
 * own sign, then natural relationship with the sign's lord. Nodes are always neutral.
 */
export function dignityOf(graha: Graha, sign: number): Dignity {
  if (isShadow(graha)) return 'neutral';

  const exaltation = EXALTATION_POINTS[graha];
  if (exaltation) {
    if (exaltation.sign === sign) return 'exalted';
    if (rasiFromIndex(exaltation.sign + 6) === sign) return 'debilitated';
  }

  const dispositor = rasiLord(sign);
  if (dispositor === graha) return 'ownSign';
  if (NATURAL_FRIENDS[graha]?.includes(dispositor)) return 'friendly';
  if (NATURAL_ENEMIES[graha]?.includes(dispositor)) return 'inimical';
  return 'neutral';
}

/** Combustion orb in degrees. Retrograde Mercury and Venus use a tighter orb. */
export function combustionOrb(graha: Graha, isRetrograde: boolean): number {
  switch (graha) {
    case 'moon': return 12;
    case 'mars': return 17;
    case 'mercury': return isRetrograde ? 12 : 14;
    case 'jupiter': return 11;
    case 'venus': return isRetrograde ? 8 : 10;
    case 'saturn': return 15;
    default: return 0;
  }
}

export function isCombust(
  graha: Graha,
  longitude: number,
  sunLongitude: number,
  isRetrograde: boolean,
): boolean {
  if (graha === 'sun' || isShadow(graha)) return false;
  return angularSeparation(longitude, sunLongitude) <= combustionOrb(graha, isRetrograde);
}
