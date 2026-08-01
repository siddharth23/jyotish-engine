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
 * @packageDocumentation
 */

export const ENGINE_VERSION = '0.1.0';

export type Ayanamsa = 'lahiri' | 'raman' | 'krishnamurti' | 'faganBradley';
export type HouseSystem = 'wholeSign' | 'equal' | 'placidus' | 'koch';

export type Graha =
  | 'sun' | 'moon' | 'mars' | 'mercury' | 'jupiter'
  | 'venus' | 'saturn' | 'rahu' | 'ketu';

export type Dignity =
  | 'exalted' | 'ownSign' | 'friendly' | 'neutral' | 'inimical' | 'debilitated';

export interface BirthData {
  /** ISO-8601 UTC. Local-to-UTC conversion is the caller's responsibility. */
  readonly utcDateTime: string;
  readonly latitude: number;
  readonly longitude: number;
  readonly ayanamsa?: Ayanamsa;
  readonly houseSystem?: HouseSystem;
  readonly useTrueNode?: boolean;
}

export interface GrahaPosition {
  readonly graha: Graha;
  readonly siderealLongitude: number;
  readonly latitude: number;
  readonly speed: number;
  readonly sign: number;
  readonly degreeInSign: number;
  readonly nakshatra: number;
  readonly pada: number;
  readonly house: number;
  readonly dignity: Dignity;
  readonly isRetrograde: boolean;
  readonly isCombust: boolean;
}

export interface Chart {
  readonly input: BirthData;
  readonly ascendant: number;
  readonly ascendantSign: number;
  readonly houseCusps: readonly number[];
  readonly positions: Readonly<Partial<Record<Graha, GrahaPosition>>>;
  readonly ayanamsaValue: number;
  readonly engineVersion: string;
}

export interface JyotishEngine {
  computeChart(birthData: BirthData): Chart;
  computeDivisional(rasi: Chart, divisions: number): Chart;
  computePanchang(utcDate: string, latitude: number, longitude: number): unknown;
  computeTransits(utcDateTime: string, natal: Chart): Chart;
  dispose(): void;
}

/**
 * Loads the WebAssembly module and returns an engine instance.
 *
 * Throws if called outside a browser environment. This guard is a safety net for the
 * licensing constraint described above, not a security boundary.
 */
export async function loadEngine(_wasmUrl?: string): Promise<JyotishEngine> {
  if (typeof window === 'undefined') {
    throw new Error(
      'jyotish-engine-wasm is browser-only. Server-side execution would place the ' +
        'surrounding service under AGPL-3.0. See docs/AGPL-BOUNDARY.md.',
    );
  }
  throw new Error('Not yet implemented: run ./native/build_wasm.sh first.');
}
