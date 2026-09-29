/**
 * Binding to the Emscripten module built by native/build_wasm.sh.
 *
 * AGPL-3.0-only. Browser use only; see docs/AGPL-BOUNDARY.md.
 */
import { julianDayFromMillis, millisFromJulianDay } from './derivation/time.js';
import type { Ayanamsa, Graha, HouseSystem, RawEphemeris } from './derivation/types.js';

interface EmscriptenFs {
  mkdir(path: string): void;
  writeFile(path: string, data: Uint8Array): void;
}

export interface JyotishModule {
  readonly FS: EmscriptenFs;
  readonly HEAPF64: Float64Array;
  _malloc(bytes: number): number;
  _free(pointer: number): void;
  _jy_set_ephe_path(path: number): void;
  _jy_raw_length(): number;
  _jy_raw(jd: number, lat: number, lon: number, sidMode: number, hsys: number,
    trueNode: number, out: number, serr: number): number;
  _jy_sun_rise_set(jd: number, lat: number, lon: number, rise: number, out: number,
    serr: number): number;
  _jy_close(): void;
  UTF8ToString(pointer: number): string;
  stringToUTF8(value: string, pointer: number, maxBytes: number): void;
}

export type ModuleFactory = (options: { locateFile: (path: string) => string }) => Promise<JyotishModule>;

/** Ephemeris data files bundled with the build, covering 1800-2399. */
export const EPHEMERIS_FILES = ['sepl_18.se1', 'semo_18.se1'] as const;
export const FIRST_SUPPORTED_YEAR = 1800;
export const LAST_SUPPORTED_YEAR = 2399;

const SID_MODE: Readonly<Record<Ayanamsa, number>> = {
  lahiri: 1, raman: 3, krishnamurti: 5, faganBradley: 0,
};

const HOUSE_CODE: Readonly<Record<HouseSystem, string>> = {
  wholeSign: 'W', equal: 'E', placidus: 'P', koch: 'K',
};

const RAW_BODIES: readonly Graha[] = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn', 'rahu'];
const SERR_BYTES = 256;
const DOUBLE_BYTES = 8;

export class NativeEphemeris {
  private readonly out: number;
  private readonly serr: number;
  private readonly rawLength: number;
  private disposed = false;

  constructor(private readonly module: JyotishModule) {
    this.rawLength = module._jy_raw_length();
    this.out = module._malloc(this.rawLength * DOUBLE_BYTES);
    this.serr = module._malloc(SERR_BYTES);
  }

  /** Writes the data files into the module's virtual filesystem. */
  mountEphemeris(files: ReadonlyMap<string, Uint8Array>): void {
    this.module.FS.mkdir('/ephe');
    for (const [name, bytes] of files) this.module.FS.writeFile(`/ephe/${name}`, bytes);
    const path = this.module._malloc(16);
    this.module.stringToUTF8('/ephe', path, 16);
    this.module._jy_set_ephe_path(path);
    this.module._free(path);
  }

  raw(utcMillis: number, latitude: number, longitude: number, ayanamsa: Ayanamsa,
    houseSystem: HouseSystem, useTrueNode: boolean): RawEphemeris {
    this.assertUsable();
    assertSupportedInstant(utcMillis);
    assertCoordinates(latitude, longitude);

    const status = this.module._jy_raw(
      julianDayFromMillis(utcMillis), latitude, longitude, SID_MODE[ayanamsa],
      HOUSE_CODE[houseSystem].charCodeAt(0), useTrueNode ? 1 : 0, this.out, this.serr,
    );
    if (status !== 0) throw new Error(this.error('Ephemeris calculation failed.'));

    const values = this.module.HEAPF64.subarray(this.out / DOUBLE_BYTES, this.out / DOUBLE_BYTES + this.rawLength);
    const at = (index: number): number => values[index] ?? Number.NaN;
    const bodyCount = RAW_BODIES.length;

    return {
      bodies: RAW_BODIES.map((graha, i) => ({
        graha,
        siderealLongitude: at(i * 3),
        latitude: at(i * 3 + 1),
        speed: at(i * 3 + 2),
      })),
      ascendant: at(bodyCount * 3),
      ayanamsaValue: at(bodyCount * 3 + 1),
      houseCusps: Array.from({ length: 12 }, (_, i) => at(bodyCount * 3 + 2 + i)),
    };
  }

  /** Next sunrise or sunset after an instant, or null if the Sun does not cross the horizon. */
  sunRiseSet(afterUtcMillis: number, latitude: number, longitude: number, rise: boolean): number | null {
    this.assertUsable();
    assertCoordinates(latitude, longitude);
    const status = this.module._jy_sun_rise_set(
      julianDayFromMillis(afterUtcMillis), latitude, longitude, rise ? 1 : 0, this.out, this.serr,
    );
    if (status === -2) return null;
    if (status < 0) throw new Error(this.error('Sunrise calculation failed.'));
    return millisFromJulianDay(this.module.HEAPF64[this.out / DOUBLE_BYTES] ?? Number.NaN);
  }

  dispose(): void {
    if (this.disposed) return;
    this.disposed = true;
    this.module._jy_close();
    this.module._free(this.out);
    this.module._free(this.serr);
  }

  private error(fallback: string): string {
    return this.module.UTF8ToString(this.serr) || fallback;
  }

  private assertUsable(): void {
    if (this.disposed) throw new Error('The engine has been disposed.');
  }
}

function assertSupportedInstant(utcMillis: number): void {
  if (!Number.isFinite(utcMillis)) throw new Error('Invalid instant.');
  const year = new Date(utcMillis).getUTCFullYear();
  if (year < FIRST_SUPPORTED_YEAR || year > LAST_SUPPORTED_YEAR) {
    throw new RangeError(
      `Year ${year} is outside the supported range ${FIRST_SUPPORTED_YEAR}-${LAST_SUPPORTED_YEAR}.`,
    );
  }
}

function assertCoordinates(latitude: number, longitude: number): void {
  if (!(latitude >= -90 && latitude <= 90) || !(longitude >= -180 && longitude <= 180)) {
    throw new RangeError('Coordinates out of range.');
  }
}
