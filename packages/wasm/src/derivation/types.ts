/** Wire types. Field names and shapes match the Dart package's `toJson` output. */

export const GRAHAS = [
  'sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn', 'rahu', 'ketu',
] as const;
export type Graha = (typeof GRAHAS)[number];

export type Ayanamsa = 'lahiri' | 'raman' | 'krishnamurti' | 'faganBradley';
export type HouseSystem = 'wholeSign' | 'equal' | 'placidus' | 'koch';
export type Dignity =
  | 'exalted' | 'ownSign' | 'friendly' | 'neutral' | 'inimical' | 'debilitated';

export const VARGAS = ['d1', 'd2', 'd3', 'd7', 'd9', 'd10', 'd12'] as const;
export type Varga = (typeof VARGAS)[number];

export interface BirthData {
  /** ISO-8601 UTC. Local-to-UTC conversion is the caller's responsibility. */
  readonly utcDateTime: string;
  readonly latitude: number;
  readonly longitude: number;
  readonly ayanamsa: Ayanamsa;
  readonly houseSystem: HouseSystem;
  /** True node uses the osculating lunar node; classical practice assumes the mean. */
  readonly useTrueNode: boolean;
}

/** Input as accepted by the engine; unspecified options take the defaults. */
export interface BirthDataInput {
  readonly utcDateTime: string;
  readonly latitude: number;
  readonly longitude: number;
  readonly ayanamsa?: Ayanamsa;
  readonly houseSystem?: HouseSystem;
  readonly useTrueNode?: boolean;
}

export interface GrahaPosition {
  readonly graha: Graha;
  /** Sidereal ecliptic longitude in degrees, 0 to 360. */
  readonly siderealLongitude: number;
  readonly latitude: number;
  /** Degrees per day. Negative indicates retrograde motion. */
  readonly speed: number;
  /** Rasi index, 0 = Mesha through 11 = Meena. */
  readonly sign: number;
  readonly degreeInSign: number;
  /** Nakshatra index, 0 = Ashwini through 26 = Revati. */
  readonly nakshatra: number;
  /** 1 to 4. */
  readonly pada: number;
  /** 1 to 12. */
  readonly house: number;
  readonly dignity: Dignity;
  readonly isRetrograde: boolean;
  readonly isCombust: boolean;
}

export interface Chart {
  readonly input: BirthData;
  readonly varga: Varga;
  readonly ascendant: number;
  readonly ascendantSign: number;
  readonly houseCusps: readonly number[];
  readonly positions: Readonly<Partial<Record<Graha, GrahaPosition>>>;
  readonly ayanamsaValue: number;
  readonly engineVersion: string;
}

export interface DashaPeriod {
  readonly lord: Graha;
  /** ISO-8601 UTC with microsecond precision where non-zero, as Dart formats it. */
  readonly start: string;
  readonly end: string;
  /** 1 = mahadasha, 2 = antardasha, 3 = pratyantardasha. */
  readonly level: number;
  readonly children?: readonly DashaPeriod[];
}

export interface Panchang {
  /** Lunar day, 1 to 30. */
  readonly tithi: number;
  readonly nakshatra: number;
  readonly yoga: number;
  readonly karana: number;
  /** Weekday reckoned from sunrise, 0 = Sunday. */
  readonly vara: number;
  /** Null above the polar circles when the Sun does not cross the horizon. */
  readonly sunrise: string | null;
  readonly sunset: string | null;
}

export interface RuleMatch {
  readonly ruleId: string;
  readonly ruleSetVersion: string;
  readonly evidence: Readonly<Record<string, unknown>>;
  readonly strength: number;
}

/** One body's raw position exactly as Swiss Ephemeris reports it. */
export interface RawBodyPosition {
  readonly graha: Graha;
  readonly siderealLongitude: number;
  readonly latitude: number;
  readonly speed: number;
}

/** Everything the engine needs from Swiss Ephemeris and nothing it can derive. */
export interface RawEphemeris {
  readonly bodies: readonly RawBodyPosition[];
  readonly ascendant: number;
  readonly ayanamsaValue: number;
  /** Required only for Placidus and Koch. */
  readonly houseCusps?: readonly number[];
}
