import { clamp, normaliseDegrees } from './math.js';
import { NAKSHATRA_COUNT, nakshatraFromLongitude } from './nakshatra.js';
import { formatUtcMillis } from './time.js';
import type { Panchang } from './types.js';

export const YOGA_NAMES = [
  'Vishkambha', 'Priti', 'Ayushman', 'Saubhagya', 'Shobhana', 'Atiganda', 'Sukarman',
  'Dhriti', 'Shula', 'Ganda', 'Vriddhi', 'Dhruva', 'Vyaghata', 'Harshana', 'Vajra',
  'Siddhi', 'Vyatipata', 'Variyana', 'Parigha', 'Shiva', 'Siddha', 'Sadhya', 'Shubha',
  'Shukla', 'Brahma', 'Indra', 'Vaidhriti',
] as const;

export const KARANA_NAMES = [
  'Bava', 'Balava', 'Kaulava', 'Taitila', 'Gara', 'Vanija', 'Vishti', 'Shakuni',
  'Chatushpada', 'Naga', 'Kimstughna',
] as const;

/** Elongation of the Moon from the Sun, 0 to 360 degrees. */
export function elongation(sunLongitude: number, moonLongitude: number): number {
  return normaliseDegrees(moonLongitude - sunLongitude);
}

/** Tithi, 1 to 30. Tithis 1-15 are shukla (waxing), 16-30 krishna (waning). */
export function tithiOf(sunLongitude: number, moonLongitude: number): number {
  return Math.floor((elongation(sunLongitude, moonLongitude) * 30) / 360) + 1;
}

/** Yoga index, from the sum of the two longitudes. */
export function yogaOf(sunLongitude: number, moonLongitude: number): number {
  const sum = normaliseDegrees(sunLongitude + moonLongitude);
  return Math.floor((sum * NAKSHATRA_COUNT) / 360) % 27;
}

export function karanaPosition(sunLongitude: number, moonLongitude: number): number {
  return clamp(Math.floor((elongation(sunLongitude, moonLongitude) * 60) / 360), 0, 59);
}

/**
 * Karana index into KARANA_NAMES. Position 0 is Kimstughna, 1-56 cycle the seven
 * movable karanas, and 57-59 are Shakuni, Chatushpada and Naga.
 */
export function karanaOf(sunLongitude: number, moonLongitude: number): number {
  const position = karanaPosition(sunLongitude, moonLongitude);
  if (position === 0) return 10;
  if (position <= 56) return (position - 1) % 7;
  return position === 57 ? 7 : position === 58 ? 8 : 9;
}

/** Weekday, 0 = Sunday, where the day begins at sunrise rather than midnight. */
export function varaOf(instantMillis: number, sunriseMillis: number): number {
  const reference = instantMillis < sunriseMillis ? instantMillis - 86_400_000 : instantMillis;
  return new Date(reference).getUTCDay();
}

export function panchangFromLongitudes(
  instantMillis: number,
  sunLongitude: number,
  moonLongitude: number,
  sunriseMillis: number | null,
  sunsetMillis: number | null,
): Panchang {
  return {
    tithi: tithiOf(sunLongitude, moonLongitude),
    nakshatra: nakshatraFromLongitude(moonLongitude),
    yoga: yogaOf(sunLongitude, moonLongitude),
    karana: karanaOf(sunLongitude, moonLongitude),
    vara: sunriseMillis === null
      ? new Date(instantMillis).getUTCDay()
      : varaOf(instantMillis, sunriseMillis),
    sunrise: sunriseMillis === null ? null : formatUtcMillis(sunriseMillis),
    sunset: sunsetMillis === null ? null : formatUtcMillis(sunsetMillis),
  };
}
