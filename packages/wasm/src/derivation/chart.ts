import { dignityOf, isCombust } from './dignity.js';
import { vargaLongitude } from './divisional.js';
import { cuspsFor, houseOfLongitude, wholeSignCusps } from './houses.js';
import { dartMod, normaliseDegrees } from './math.js';
import { nakshatraFromLongitude, padaOfLongitude } from './nakshatra.js';
import { rasiFromLongitude } from './rasi.js';
import {
  GRAHAS,
  type BirthData,
  type Chart,
  type Graha,
  type GrahaPosition,
  type RawEphemeris,
  type Varga,
} from './types.js';
import { ENGINE_VERSION } from '../version.js';

/** Adds Ketu opposite Rahu when the ephemeris supplied only one node. */
export function withDerivedKetu(raw: RawEphemeris): RawEphemeris {
  if (raw.bodies.some((b) => b.graha === 'ketu')) return raw;
  const rahu = raw.bodies.find((b) => b.graha === 'rahu');
  if (!rahu) return raw;
  return {
    ...raw,
    bodies: [
      ...raw.bodies,
      {
        graha: 'ketu',
        siderealLongitude: normaliseDegrees(rahu.siderealLongitude + 180),
        latitude: 0,
        speed: rahu.speed,
      },
    ],
  };
}

/** Rebuilds positions in canonical graha order so serialised output is stable. */
function ordered(positions: Map<Graha, GrahaPosition>): Partial<Record<Graha, GrahaPosition>> {
  const result: Partial<Record<Graha, GrahaPosition>> = {};
  for (const graha of GRAHAS) {
    const position = positions.get(graha);
    if (position) result[graha] = position;
  }
  return result;
}

/**
 * Builds a complete chart from raw ephemeris output: the whole derivation half of the
 * engine. Retrograde motion comes from the sign of the speed, so the true node will
 * occasionally report direct motion, which is astronomically correct.
 */
export function assembleChart(birthData: BirthData, rawEphemeris: RawEphemeris): Chart {
  const raw = withDerivedKetu(rawEphemeris);

  let cusps: readonly number[];
  if (birthData.houseSystem === 'wholeSign' || birthData.houseSystem === 'equal') {
    cusps = cuspsFor(birthData.houseSystem, raw.ascendant);
  } else if (raw.houseCusps) {
    cusps = raw.houseCusps;
  } else {
    throw new Error(
      `${birthData.houseSystem} requires ephemeris-derived cusps, but ` +
        'RawEphemeris.houseCusps was missing.',
    );
  }

  const sun = raw.bodies.find((b) => b.graha === 'sun');
  if (!sun) throw new Error('The ephemeris did not supply the Sun, which combustion needs.');

  const positions = new Map<Graha, GrahaPosition>();
  for (const body of raw.bodies) {
    const longitude = normaliseDegrees(body.siderealLongitude);
    const sign = rasiFromLongitude(longitude);
    const isRetrograde = body.speed < 0;
    positions.set(body.graha, {
      graha: body.graha,
      siderealLongitude: longitude,
      latitude: body.latitude,
      speed: body.speed,
      sign,
      degreeInSign: dartMod(longitude, 30),
      nakshatra: nakshatraFromLongitude(longitude),
      pada: padaOfLongitude(longitude),
      house: houseOfLongitude(longitude, cusps),
      dignity: dignityOf(body.graha, sign),
      isRetrograde,
      isCombust: isCombust(body.graha, longitude, sun.siderealLongitude, isRetrograde),
    });
  }

  return {
    input: birthData,
    varga: 'd1',
    ascendant: normaliseDegrees(raw.ascendant),
    ascendantSign: rasiFromLongitude(raw.ascendant),
    houseCusps: [...cusps],
    positions: ordered(positions),
    ayanamsaValue: raw.ayanamsaValue,
    engineVersion: ENGINE_VERSION,
  };
}

/**
 * Derives a divisional chart from a rasi chart, cast in whole sign from the varga
 * ascendant. Combustion, latitude and speed are physical facts about the sky at birth
 * and are carried across rather than recomputed.
 */
export function computeDivisionalChart(rasi: Chart, varga: Varga): Chart {
  if (varga === 'd1') return rasi;
  if (rasi.varga !== 'd1') {
    throw new Error(
      `Divisional charts must be derived from a rasi chart, but the input is ${rasi.varga}.`,
    );
  }

  const ascendantLongitude = vargaLongitude(rasi.ascendant, varga);
  const ascendantSign = rasiFromLongitude(ascendantLongitude);
  const cusps = wholeSignCusps(ascendantSign);

  const positions = new Map<Graha, GrahaPosition>();
  for (const graha of GRAHAS) {
    const source = rasi.positions[graha];
    if (!source) continue;
    const longitude = vargaLongitude(source.siderealLongitude, varga);
    const sign = rasiFromLongitude(longitude);
    positions.set(graha, {
      graha,
      siderealLongitude: longitude,
      latitude: source.latitude,
      speed: source.speed,
      sign,
      degreeInSign: dartMod(longitude, 30),
      nakshatra: nakshatraFromLongitude(longitude),
      pada: padaOfLongitude(longitude),
      house: houseOfLongitude(longitude, cusps),
      dignity: dignityOf(graha, sign),
      isRetrograde: source.isRetrograde,
      isCombust: source.isCombust,
    });
  }

  return {
    input: rasi.input,
    varga,
    ascendant: ascendantLongitude,
    ascendantSign,
    houseCusps: cusps,
    positions: ordered(positions),
    ayanamsaValue: rasi.ayanamsaValue,
    engineVersion: rasi.engineVersion,
  };
}
