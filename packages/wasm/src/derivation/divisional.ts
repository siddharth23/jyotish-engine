import { clamp, dartMod, normaliseDegrees } from './math.js';
import { rasiFromIndex, rasiFromLongitude, rasiIsOdd } from './rasi.js';
import type { Varga } from './types.js';

export const VARGA_DIVISIONS: Readonly<Record<Varga, number>> = {
  d1: 1, d2: 2, d3: 3, d7: 7, d9: 9, d10: 10, d12: 12,
};

export const VARGA_NAMES: Readonly<Record<Varga, string>> = {
  d1: 'Rasi', d2: 'Hora', d3: 'Drekkana', d7: 'Saptamsha', d9: 'Navamsa',
  d10: 'Dashamsha', d12: 'Dwadashamsha',
};

/** Multiplication first, for the same reason as nakshatraPosition. */
function divisionPosition(longitude: number, varga: Varga): number {
  return (dartMod(longitude, 30) * VARGA_DIVISIONS[varga]) / 30;
}

function divisionIndex(longitude: number, varga: Varga): number {
  return clamp(Math.floor(divisionPosition(longitude, varga)), 0, VARGA_DIVISIONS[varga] - 1);
}

/**
 * Sign a longitude falls into within a varga. Brihat Parashara Hora Shastra, chs. 6-7:
 * D2 odd signs Simha then Karka, even reversed; D3 the sign, 5th and 9th; D7 odd from
 * itself, even from the 7th; D9 `(sign * 9 + part) % 12`; D10 odd from itself, even
 * from the 9th; D12 from itself.
 */
export function vargaSign(siderealLongitude: number, varga: Varga): number {
  const longitude = normaliseDegrees(siderealLongitude);
  const sign = rasiFromLongitude(longitude);
  const part = divisionIndex(longitude, varga);

  switch (varga) {
    case 'd1': return sign;
    case 'd2': return rasiIsOdd(sign) ? (part === 0 ? 4 : 3) : (part === 0 ? 3 : 4);
    case 'd3': return rasiFromIndex(sign + part * 4);
    case 'd7': return rasiFromIndex(rasiIsOdd(sign) ? sign + part : sign + 6 + part);
    case 'd9': return rasiFromIndex(sign * 9 + part);
    case 'd10': return rasiFromIndex(rasiIsOdd(sign) ? sign + part : sign + 8 + part);
    case 'd12': return rasiFromIndex(sign + part);
  }
}

/**
 * Longitude within the varga sign, scaled so the division fills a whole sign. Only
 * the varga sign is classically meaningful; treat the degree as an engine artefact.
 */
export function vargaLongitude(siderealLongitude: number, varga: Varga): number {
  const longitude = normaliseDegrees(siderealLongitude);
  const position = divisionPosition(longitude, varga);
  const within = position - Math.floor(position);
  return normaliseDegrees(vargaSign(longitude, varga) * 30 + within * 30);
}
