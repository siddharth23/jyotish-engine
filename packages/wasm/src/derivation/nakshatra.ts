import { clamp, normaliseDegrees } from './math.js';
import type { Graha } from './types.js';

export const NAKSHATRA_COUNT = 27;
export const PADAS_PER_NAKSHATRA = 4;

export const NAKSHATRA_NAMES = [
  'Ashwini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira', 'Ardra', 'Punarvasu',
  'Pushya', 'Ashlesha', 'Magha', 'Purva Phalguni', 'Uttara Phalguni', 'Hasta', 'Chitra',
  'Swati', 'Vishakha', 'Anuradha', 'Jyeshtha', 'Mula', 'Purva Ashadha', 'Uttara Ashadha',
  'Shravana', 'Dhanishta', 'Shatabhisha', 'Purva Bhadrapada', 'Uttara Bhadrapada', 'Revati',
] as const;

/** Order in which dasha lords succeed one another. Fixed and cyclic. */
export const VIMSHOTTARI_ORDER: readonly Graha[] = [
  'ketu', 'venus', 'sun', 'moon', 'mars', 'rahu', 'jupiter', 'saturn', 'mercury',
];

/**
 * Position along the nakshatra cycle, 0.0 at 0 Aries to 27.0 after a full circle.
 *
 * Multiplies before dividing: 360/27 is not exactly representable, so dividing by it
 * can place an exact boundary longitude in the wrong nakshatra, and one slip in the
 * Moon's nakshatra changes every dasha date.
 */
export function nakshatraPosition(siderealLongitude: number): number {
  return (normaliseDegrees(siderealLongitude) * NAKSHATRA_COUNT) / 360;
}

export function nakshatraFromLongitude(siderealLongitude: number): number {
  return Math.floor(nakshatraPosition(siderealLongitude)) % NAKSHATRA_COUNT;
}

/** Vimshottari lord of a nakshatra index. */
export function nakshatraLord(nakshatra: number): Graha {
  return VIMSHOTTARI_ORDER[nakshatra % 9] ?? 'ketu';
}

/** Fraction of the current nakshatra already traversed, 0.0 to just under 1.0. */
export function nakshatraElapsedFraction(siderealLongitude: number): number {
  const position = nakshatraPosition(siderealLongitude);
  return position - Math.floor(position);
}

/** Pada of the nakshatra occupied by a longitude, 1 to 4. */
export function padaOfLongitude(siderealLongitude: number): number {
  const within = nakshatraElapsedFraction(siderealLongitude);
  return clamp(Math.floor(within * PADAS_PER_NAKSHATRA), 0, 3) + 1;
}
