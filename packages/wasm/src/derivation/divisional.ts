import { clamp, dartMod, normaliseDegrees } from './math.js';
import { rasiFromIndex, rasiFromLongitude, rasiIsOdd, rasiModality } from './rasi.js';
import type { Modality } from './rasi.js';
import type { Varga } from './types.js';

export const VARGA_DIVISIONS: Readonly<Record<Varga, number>> = {
  d1: 1, d2: 2, d3: 3, d4: 4, d7: 7, d9: 9, d10: 10, d12: 12,
  d16: 16, d20: 20, d24: 24, d27: 27, d30: 30, d40: 40, d45: 45, d60: 60,
};

export const VARGA_NAMES: Readonly<Record<Varga, string>> = {
  d1: 'Rasi', d2: 'Hora', d3: 'Drekkana', d4: 'Chaturthamsa', d7: 'Saptamsha',
  d9: 'Navamsa', d10: 'Dashamsha', d12: 'Dwadashamsha', d16: 'Shodashamsa',
  d20: 'Vimshamsa', d24: 'Siddhamsa', d27: 'Bhamsa', d30: 'Trimshamsa',
  d40: 'Khavedamsa', d45: 'Akshavedamsa', d60: 'Shashtiamsa',
};

/** Whether every part of a varga has the same width. False only for D30. */
export function vargaHasEqualDivisions(varga: Varga): boolean {
  return varga !== 'd30';
}

/** Multiplication first, for the same reason as nakshatraPosition. */
function divisionPosition(longitude: number, varga: Varga): number {
  return (dartMod(longitude, 30) * VARGA_DIVISIONS[varga]) / 30;
}

function divisionIndex(longitude: number, varga: Varga): number {
  return clamp(Math.floor(divisionPosition(longitude, varga)), 0, VARGA_DIVISIONS[varga] - 1);
}

/** Upper bound of a trimshamsa part, and the sign it maps to. */
type TrimshamsaPart = readonly [upper: number, sign: number];

/**
 * The trimshamsa always has exactly five parts, so the tuple length is fixed:
 * it lets the final part be read back without an unchecked index.
 */
type TrimshamsaParts = readonly [
  TrimshamsaPart, TrimshamsaPart, TrimshamsaPart, TrimshamsaPart, TrimshamsaPart,
];

/**
 * Brihat Parashara Hora Shastra ch. 6: Mars 5 degrees, Saturn 5, Jupiter 8,
 * Mercury 7, Venus 5, each mapping to that graha's odd-sign rulership.
 */
const TRIMSHAMSA_ODD: TrimshamsaParts = [
  [5, 0], // Mars — Mesha
  [10, 10], // Saturn — Kumbha
  [18, 8], // Jupiter — Dhanu
  [25, 2], // Mercury — Mithuna
  [30, 6], // Venus — Tula
];

/**
 * The same five rulers in reverse for an even sign, mapping to their even-sign
 * rulerships. The widths mirror: 5, 7, 8, 5, 5.
 */
const TRIMSHAMSA_EVEN: TrimshamsaParts = [
  [5, 1], // Venus — Vrishabha
  [12, 5], // Mercury — Kanya
  [20, 11], // Jupiter — Meena
  [25, 9], // Saturn — Makara
  [30, 7], // Mars — Vrishchika
];

interface TrimshamsaSpan {
  readonly sign: number;
  readonly start: number;
  readonly end: number;
}

/**
 * The trimshamsa part containing `degreeInSign`, with the part's own bounds.
 *
 * The bounds come back because the part widths differ, so a caller scaling a
 * position to fill a sign cannot assume a uniform division span.
 */
function trimshamsaPart(degreeInSign: number, isOdd: boolean): TrimshamsaSpan {
  const parts = isOdd ? TRIMSHAMSA_ODD : TRIMSHAMSA_EVEN;
  let lower = 0;
  for (const [upper, sign] of parts) {
    if (degreeInSign < upper) return { sign, start: lower, end: upper };
    lower = upper;
  }
  // Unreachable: normaliseDegrees keeps the degree under 30 and the last part
  // ends there. The final part is the only consistent answer regardless.
  return { sign: parts[4][1], start: parts[3][0], end: parts[4][0] };
}

/** Starting sign for the vargas whose rule keys off modality. */
function byModality(sign: number, starts: Readonly<Record<Modality, number>>): number {
  return starts[rasiModality(sign)];
}

/**
 * Sign a longitude falls into within a varga. Brihat Parashara Hora Shastra,
 * chs. 6-7. The per-varga starting rules are the standard Parashari ones:
 * D2 odd signs Simha then Karka, even reversed; D3 the sign, 5th and 9th; D4 the
 * sign and the three kendras; D7 odd from itself, even from the 7th; D9
 * `(sign * 9 + part) % 12`; D10 odd from itself, even from the 9th; D12 from
 * itself; D16 movable Mesha, fixed Simha, dual Dhanu; D20 movable Mesha, fixed
 * Dhanu, dual Simha; D24 odd Simha, even Karka; D27 by element, which cycles
 * every four signs; D30 five unequal parts by rulership; D40 odd Mesha, even
 * Tula; D45 movable Mesha, fixed Simha, dual Dhanu; D60 from itself.
 */
export function vargaSign(siderealLongitude: number, varga: Varga): number {
  const longitude = normaliseDegrees(siderealLongitude);
  const sign = rasiFromLongitude(longitude);

  // D30 is the one varga without equal parts, so the shared part index that
  // every other rule below depends on does not apply to it.
  if (varga === 'd30') {
    return trimshamsaPart(dartMod(longitude, 30), rasiIsOdd(sign)).sign;
  }

  const part = divisionIndex(longitude, varga);

  switch (varga) {
    case 'd1': return sign;
    case 'd2': return rasiIsOdd(sign) ? (part === 0 ? 4 : 3) : (part === 0 ? 3 : 4);
    case 'd3': return rasiFromIndex(sign + part * 4);
    case 'd4': return rasiFromIndex(sign + part * 3);
    case 'd7': return rasiFromIndex(rasiIsOdd(sign) ? sign + part : sign + 6 + part);
    case 'd9': return rasiFromIndex(sign * 9 + part);
    case 'd10': return rasiFromIndex(rasiIsOdd(sign) ? sign + part : sign + 8 + part);
    case 'd12': return rasiFromIndex(sign + part);
    case 'd16': return rasiFromIndex(byModality(sign, { movable: 0, fixed: 4, dual: 8 }) + part);
    case 'd20': return rasiFromIndex(byModality(sign, { movable: 0, fixed: 8, dual: 4 }) + part);
    case 'd24': return rasiFromIndex((rasiIsOdd(sign) ? 4 : 3) + part);
    case 'd27': return rasiFromIndex((sign % 4) * 3 + part);
    case 'd40': return rasiFromIndex((rasiIsOdd(sign) ? 0 : 6) + part);
    case 'd45': return rasiFromIndex(byModality(sign, { movable: 0, fixed: 4, dual: 8 }) + part);
    case 'd60': return rasiFromIndex(sign + part);
  }
}

/**
 * Longitude within the varga sign, scaled so the division fills a whole sign. Only
 * the varga sign is classically meaningful; treat the degree as an engine artefact.
 */
export function vargaLongitude(siderealLongitude: number, varga: Varga): number {
  const longitude = normaliseDegrees(siderealLongitude);

  // D30 scales against its own part, which may be 5, 7 or 8 degrees wide.
  if (varga === 'd30') {
    const degreeInSign = dartMod(longitude, 30);
    const part = trimshamsaPart(degreeInSign, rasiIsOdd(rasiFromLongitude(longitude)));
    const within = (degreeInSign - part.start) / (part.end - part.start);
    return normaliseDegrees(part.sign * 30 + within * 30);
  }

  const position = divisionPosition(longitude, varga);
  const within = position - Math.floor(position);
  return normaliseDegrees(vargaSign(longitude, varga) * 30 + within * 30);
}
