/**
 * Sidereal (Vedic) astrological calculations, WebAssembly build.
 *
 * ## Licensing — read before use
 *
 * This package embeds Swiss Ephemeris under AGPL-3.0. It is intended for
 * **browser execution only**.
 *
 * Running it under Node.js, Deno, Bun, or any other server-side runtime places the
 * surrounding service under AGPL-3.0 and obliges you to offer its complete source to
 * every user who interacts with it over a network.
 *
 * See `docs/AGPL-BOUNDARY.md` in the repository root.
 *
 * The pure derivation functions re-exported below compute nothing astronomical and
 * load no WebAssembly; `loadEngine` is the only entry point that does.
 *
 * @packageDocumentation
 */
import { assembleChart, computeDivisionalChart } from './derivation/chart.js';
import { dartMod } from './derivation/math.js';
import { panchangFromLongitudes } from './derivation/panchang.js';
import { evaluateRules } from './derivation/rules.js';
import { formatUtcMicros, parseUtcMicros } from './derivation/time.js';
import type {
  BirthData, BirthDataInput, Chart, DashaPeriod, Panchang, RuleMatch, Varga,
} from './derivation/types.js';
import { computeVimshottariDashas } from './derivation/vimshottari.js';
import { EPHEMERIS_FILES, NativeEphemeris, type ModuleFactory } from './native.js';

export { ENGINE_VERSION } from './version.js';
export * from './derivation/types.js';
export { RASI_NAMES, rasiFromLongitude, rasiLord, rasiModality, rasiIsOdd } from './derivation/rasi.js';
export { NAKSHATRA_NAMES, VIMSHOTTARI_ORDER, nakshatraFromLongitude, nakshatraLord, padaOfLongitude } from './derivation/nakshatra.js';
export { EXALTATION_POINTS, NATURAL_FRIENDS, NATURAL_ENEMIES, dignityOf, isCombust, combustionOrb } from './derivation/dignity.js';
export { VARGA_DIVISIONS, VARGA_NAMES, vargaSign, vargaLongitude } from './derivation/divisional.js';
export { houseOfLongitude, wholeSignCusps, equalCusps } from './derivation/houses.js';
export { VIMSHOTTARI_YEARS, activeDashaChain } from './derivation/vimshottari.js';
export { YOGA_NAMES, KARANA_NAMES } from './derivation/panchang.js';
export { assembleChart, computeDivisionalChart, evaluateRules, computeVimshottariDashas };
export { FIRST_SUPPORTED_YEAR, LAST_SUPPORTED_YEAR, EPHEMERIS_FILES } from './native.js';

export interface JyotishEngine {
  /** Computes the rasi (D1) chart. */
  computeChart(birthData: BirthDataInput): Chart;
  /** Derives a divisional chart from an already computed rasi chart. */
  computeDivisional(rasi: Chart, varga: Varga): Chart;
  /** Vimshottari dasha tree. depth 1 mahadashas, 2 antardashas, 3 pratyantardashas. */
  computeDashas(chart: Chart, depth?: number): DashaPeriod[];
  /** Panchang at an instant and place, with sunrise and sunset of that local day. */
  computePanchang(utcDateTime: string, latitude: number, longitude: number): Panchang;
  /**
   * Positions at an instant, placed in the natal chart's houses, as gochara is read.
   * The ascendant and cusps are the natal ones; longitudes and ayanamsa are the
   * transit instant's.
   */
  computeTransits(utcDateTime: string, natal: Chart): Chart;
  /** Evaluates a rule set against a rasi chart. Returns identifiers, never prose. */
  evaluateRules(chart: Chart, ruleSet: unknown): RuleMatch[];
  /** Releases the module's resources. */
  dispose(): void;
}

export interface LoadEngineOptions {
  /**
   * URL of the directory holding `jyotish_engine.mjs`, `jyotish_engine.wasm` and
   * `ephe/`. Defaults to the `native/` directory next to this file.
   */
  readonly assetBaseUrl?: string | URL;
}

function isBrowser(): boolean {
  return typeof window !== 'undefined' ||
    (typeof self !== 'undefined' && typeof (self as { importScripts?: unknown }).importScripts === 'function');
}

function normaliseInput(input: BirthDataInput): BirthData {
  return {
    // Canonical form, so equal instants serialise identically however they were written.
    utcDateTime: formatUtcMicros(parseUtcMicros(input.utcDateTime)),
    latitude: input.latitude,
    longitude: input.longitude,
    ayanamsa: input.ayanamsa ?? 'lahiri',
    houseSystem: input.houseSystem ?? 'wholeSign',
    useTrueNode: input.useTrueNode ?? false,
  };
}

function utcMillis(iso: string): number {
  return Number(parseUtcMicros(iso)) / 1000;
}

/**
 * Loads the WebAssembly module and its ephemeris data, and returns an engine.
 *
 * Throws if called outside a browser. This guard is a safety net for the licensing
 * constraint described above, not a security boundary.
 */
export async function loadEngine(options: LoadEngineOptions = {}): Promise<JyotishEngine> {
  if (!isBrowser()) {
    throw new Error(
      'jyotish-engine-wasm is browser-only. Server-side execution would place the ' +
        'surrounding service under AGPL-3.0. See docs/AGPL-BOUNDARY.md.',
    );
  }

  const base = new URL(String(options.assetBaseUrl ?? new URL('./native/', import.meta.url)), globalThis.location.href);
  const directory = base.href.endsWith('/') ? base : new URL(`${base.href}/`);

  const glue = (await import(/* @vite-ignore */ new URL('jyotish_engine.mjs', directory).href)) as { default: ModuleFactory };
  const [module, files] = await Promise.all([
    glue.default({ locateFile: (path) => new URL(path, directory).href }),
    Promise.all(EPHEMERIS_FILES.map(async (name) => {
      const response = await fetch(new URL(`ephe/${name}`, directory));
      if (!response.ok) throw new Error(`Could not load ephemeris file ${name} (${response.status}).`);
      return [name, new Uint8Array(await response.arrayBuffer())] as const;
    })),
  ]);

  const native = new NativeEphemeris(module);
  native.mountEphemeris(new Map(files));

  const rawFor = (input: BirthData) => native.raw(
    utcMillis(input.utcDateTime), input.latitude, input.longitude, input.ayanamsa,
    input.houseSystem, input.useTrueNode,
  );

  return {
    computeChart(birthData) {
      const input = normaliseInput(birthData);
      return assembleChart(input, rawFor(input));
    },

    computeDivisional: computeDivisionalChart,

    computeDashas(chart, depth = 3) {
      const moon = chart.positions.moon;
      if (!moon || chart.varga !== 'd1') throw new Error('Dashas need a rasi chart with the Moon.');
      return computeVimshottariDashas(moon.siderealLongitude, chart.input.utcDateTime, depth);
    },

    computePanchang(utcDateTime, latitude, longitude) {
      const instant = utcMillis(utcDateTime);
      const input = normaliseInput({ utcDateTime, latitude, longitude });
      const raw = rawFor(input);
      const sun = raw.bodies.find((b) => b.graha === 'sun');
      const moon = raw.bodies.find((b) => b.graha === 'moon');
      if (!sun || !moon) throw new Error('The ephemeris did not supply the Sun and Moon.');

      // Start searching at local mean midnight before the instant, so the sunrise found
      // is the one that opens this local day.
      const dayMillis = 86_400_000;
      const offsetMillis = (longitude / 360) * dayMillis;
      const localMidnight = Math.floor((instant + offsetMillis) / dayMillis) * dayMillis - offsetMillis;
      const sunrise = native.sunRiseSet(localMidnight, latitude, longitude, true);
      const sunset = native.sunRiseSet(sunrise ?? localMidnight, latitude, longitude, false);

      return panchangFromLongitudes(
        instant, dartMod(sun.siderealLongitude, 360), dartMod(moon.siderealLongitude, 360), sunrise, sunset,
      );
    },

    computeTransits(utcDateTime, natal) {
      const input = normaliseInput({ ...natal.input, utcDateTime });
      const raw = rawFor(input);
      return assembleChart(natal.input, {
        ...raw,
        ascendant: natal.ascendant,
        houseCusps: natal.houseCusps,
      });
    },

    evaluateRules,

    dispose() {
      native.dispose();
    },
  };
}
