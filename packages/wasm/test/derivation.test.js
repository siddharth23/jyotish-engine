import { test } from 'node:test';
import assert from 'node:assert/strict';

import { dartMod, normaliseDegrees, angularSeparation } from '../dist/derivation/math.js';
import { rasiFromLongitude, rasiLord, rasiIsOdd } from '../dist/derivation/rasi.js';
import { nakshatraFromLongitude, nakshatraLord, padaOfLongitude } from '../dist/derivation/nakshatra.js';
import { dignityOf, isCombust } from '../dist/derivation/dignity.js';
import {
  VARGA_DIVISIONS,
  vargaHasEqualDivisions,
  vargaLongitude,
  vargaSign,
} from '../dist/derivation/divisional.js';
import { houseOfLongitude, wholeSignCusps } from '../dist/derivation/houses.js';
import { assembleChart, computeDivisionalChart } from '../dist/derivation/chart.js';
import { computeVimshottariDashas, activeDashaChain } from '../dist/derivation/vimshottari.js';
import { tithiOf, karanaOf, yogaOf } from '../dist/derivation/panchang.js';
import { evaluateRules } from '../dist/derivation/rules.js';
import { formatUtcMicros, parseUtcMicros } from '../dist/derivation/time.js';
import { VARGAS } from '../dist/derivation/types.js';

const SPAN = 360 / 27;

test('dartMod keeps the sign of the divisor', () => {
  assert.equal(dartMod(-30, 360), 330);
  assert.equal(dartMod(390, 360), 30);
  assert.equal(normaliseDegrees(720), 0);
  assert.equal(angularSeparation(350, 10), 20);
});

test('signs, lords and parity', () => {
  assert.equal(rasiFromLongitude(0), 0);
  assert.equal(rasiFromLongitude(29.999999), 0);
  assert.equal(rasiFromLongitude(30), 1);
  assert.equal(rasiFromLongitude(-0.5), 11);
  assert.equal(rasiLord(4), 'sun');
  assert.equal(rasiLord(10), 'saturn');
  assert.equal(rasiIsOdd(0), true);
  assert.equal(rasiIsOdd(1), false);
});

test('nakshatra boundaries at whole degrees are exact', () => {
  assert.equal(nakshatraFromLongitude(120), 9, 'Magha opens at 0 Leo');
  assert.equal(nakshatraFromLongitude(240), 18, 'Mula opens at 0 Sagittarius');
  assert.equal(nakshatraFromLongitude(119.9999), 8);
  assert.equal(nakshatraLord(9), 'ketu');
  assert.equal(nakshatraLord(1), 'venus');
  assert.equal(padaOfLongitude(0), 1);
  assert.equal(padaOfLongitude(SPAN - 1e-9), 4);
});

test('dignity follows BPHS precedence', () => {
  assert.equal(dignityOf('sun', 0), 'exalted');
  assert.equal(dignityOf('sun', 6), 'debilitated');
  assert.equal(dignityOf('mars', 7), 'ownSign');
  assert.equal(dignityOf('jupiter', 4), 'friendly');
  assert.equal(dignityOf('saturn', 4), 'inimical');
  assert.equal(dignityOf('rahu', 1), 'neutral');
});

test('combustion orbs tighten for retrograde Mercury and Venus', () => {
  assert.equal(isCombust('mercury', 113, 100, false), true);
  assert.equal(isCombust('mercury', 113, 100, true), false);
  assert.equal(isCombust('sun', 100, 100, false), false);
  assert.equal(isCombust('rahu', 100, 100, false), false);
});

test('varga starting rules', () => {
  // D9: movable from itself, fixed from the 9th, dual from the 5th.
  assert.equal(vargaSign(0.1, 'd9'), 0);
  assert.equal(vargaSign(30.1, 'd9'), 9);
  assert.equal(vargaSign(60.1, 'd9'), 6);
  // D10: even signs start from the 9th.
  assert.equal(vargaSign(30.1, 'd10'), 9);
  // D2: odd signs give Simha first, even signs Karka first.
  assert.equal(vargaSign(1, 'd2'), 4);
  assert.equal(vargaSign(31, 'd2'), 3);
  // D3: the sign, the 5th and the 9th.
  assert.equal(vargaSign(25, 'd3'), 8);
  // D4: the sign and the three kendras from it.
  assert.equal(vargaSign(3, 'd4'), 0);
  assert.equal(vargaSign(10, 'd4'), 3);
  assert.equal(vargaSign(20, 'd4'), 6);
  assert.equal(vargaSign(28, 'd4'), 9);
  // D16 and D45: movable Mesha, fixed Simha, dual Dhanu.
  assert.equal(vargaSign(1, 'd16'), 0);
  assert.equal(vargaSign(31, 'd16'), 4);
  assert.equal(vargaSign(61, 'd16'), 8);
  assert.equal(vargaSign(0.5, 'd45'), 0);
  assert.equal(vargaSign(30.5, 'd45'), 4);
  assert.equal(vargaSign(60.5, 'd45'), 8);
  // D20: movable Mesha, fixed Dhanu, dual Simha.
  assert.equal(vargaSign(1, 'd20'), 0);
  assert.equal(vargaSign(31, 'd20'), 8);
  assert.equal(vargaSign(61, 'd20'), 4);
  // D24: odd signs from Simha, even from Karka.
  assert.equal(vargaSign(1, 'd24'), 4);
  assert.equal(vargaSign(31, 'd24'), 3);
  // D27: by element, which cycles every four signs.
  assert.equal(vargaSign(0.5, 'd27'), 0);
  assert.equal(vargaSign(30.5, 'd27'), 3);
  assert.equal(vargaSign(60.5, 'd27'), 6);
  assert.equal(vargaSign(90.5, 'd27'), 9);
  assert.equal(vargaSign(120.5, 'd27'), 0);
  // D40: odd signs from Mesha, even from Tula.
  assert.equal(vargaSign(0.5, 'd40'), 0);
  assert.equal(vargaSign(30.5, 'd40'), 6);
  // D60: from the sign itself, wrapping the zodiac every 6 degrees.
  assert.equal(vargaSign(0.25, 'd60'), 0);
  assert.equal(vargaSign(0.75, 'd60'), 1);
  assert.equal(vargaSign(6.25, 'd60'), 0);
});

test('the trimshamsa divides a sign unequally', () => {
  // Mars 5, Saturn 5, Jupiter 8, Mercury 7, Venus 5 degrees in an odd sign.
  assert.equal(vargaSign(3, 'd30'), 0);
  assert.equal(vargaSign(7, 'd30'), 10);
  assert.equal(vargaSign(15, 'd30'), 8);
  assert.equal(vargaSign(20, 'd30'), 2);
  assert.equal(vargaSign(27, 'd30'), 6);
  // An even sign reverses the five rulers: 5, 7, 8, 5, 5.
  assert.equal(vargaSign(33, 'd30'), 1);
  assert.equal(vargaSign(38, 'd30'), 5);
  assert.equal(vargaSign(45, 'd30'), 11);
  assert.equal(vargaSign(52, 'd30'), 9);
  assert.equal(vargaSign(57, 'd30'), 7);
  // A part boundary belongs to the part above it.
  assert.equal(vargaSign(5, 'd30'), 10);
  assert.equal(vargaSign(10, 'd30'), 8);
  assert.equal(vargaSign(42, 'd30'), 11);
  assert.equal(vargaHasEqualDivisions('d30'), false);
});

test('the trimshamsa never produces Karka or Simha', () => {
  // Only the five tara grahas rule trimshamsas, so the Sun's and Moon's signs
  // can never appear. A rule table typo shows up here.
  for (let tenth = 0; tenth < 3600; tenth += 1) {
    const sign = vargaSign(tenth / 10, 'd30');
    assert.ok(sign !== 3 && sign !== 4, `Karka or Simha at ${tenth / 10} degrees`);
  }
});

test('the scaled varga longitude stays inside the sign the varga selected', () => {
  // Guards the D30 branch in particular: its parts are 5, 7 or 8 degrees wide,
  // so scaling against a uniform span would push values into the wrong sign.
  for (const varga of VARGAS) {
    for (let tenth = 0; tenth < 3600; tenth += 7) {
      const source = tenth / 10;
      assert.equal(
        Math.floor(vargaLongitude(source, varga) / 30),
        vargaSign(source, varga),
        `${varga} at ${source} degrees`,
      );
    }
  }
});

test('the Shodashavarga has exactly sixteen members', () => {
  assert.equal(VARGAS.length, 16);
  assert.deepEqual(
    VARGAS.map((v) => VARGA_DIVISIONS[v]),
    [1, 2, 3, 4, 7, 9, 10, 12, 16, 20, 24, 27, 30, 40, 45, 60],
  );
});

test('houses wrap around Pisces', () => {
  const cusps = wholeSignCusps(11);
  assert.equal(houseOfLongitude(345, cusps), 1);
  assert.equal(houseOfLongitude(5, cusps), 2);
  assert.throws(() => houseOfLongitude(5, [0, 1, 2]));
});

const RAW = {
  ascendant: 95.5,
  ayanamsaValue: 24.1,
  bodies: [
    { graha: 'sun', siderealLongitude: 10.2, latitude: 0, speed: 1 },
    { graha: 'moon', siderealLongitude: 187.4, latitude: 4, speed: 13 },
    { graha: 'mars', siderealLongitude: 298, latitude: 1, speed: 0.6 },
    { graha: 'mercury', siderealLongitude: 20, latitude: -1, speed: -0.5 },
    { graha: 'jupiter', siderealLongitude: 95, latitude: 0.5, speed: 0.1 },
    { graha: 'venus', siderealLongitude: 356, latitude: 2, speed: 1.2 },
    { graha: 'saturn', siderealLongitude: 200, latitude: -2, speed: -0.03 },
    { graha: 'rahu', siderealLongitude: 50, latitude: 0, speed: -0.05 },
  ],
};
const BIRTH = {
  utcDateTime: '2000-01-01T00:00:00.000Z', latitude: 50, longitude: 8,
  ayanamsa: 'lahiri', houseSystem: 'wholeSign', useTrueNode: false,
};

test('assembleChart derives Ketu, houses, dignity and combustion', () => {
  const chart = assembleChart(BIRTH, RAW);
  assert.deepEqual(Object.keys(chart.positions),
    ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn', 'rahu', 'ketu']);
  assert.equal(chart.positions.ketu.siderealLongitude, 230);
  assert.equal(chart.ascendantSign, 3);
  assert.equal(chart.positions.jupiter.house, 1);
  assert.equal(chart.positions.jupiter.dignity, 'exalted');
  assert.equal(chart.positions.mercury.isCombust, true);
  assert.equal(chart.positions.saturn.isRetrograde, true);
  assert.equal(chart.positions.mars.dignity, 'exalted');
});

test('divisional charts keep combustion and recast houses from the varga ascendant', () => {
  const rasi = assembleChart(BIRTH, RAW);
  const d9 = computeDivisionalChart(rasi, 'd9');
  assert.equal(d9.varga, 'd9');
  assert.equal(d9.positions.mercury.isCombust, true);
  assert.equal(d9.houseCusps[0], d9.ascendantSign * 30);
  assert.throws(() => computeDivisionalChart(d9, 'd10'));
});

test('dashas start from the Moon nakshatra lord and tile exactly', () => {
  const zero = computeVimshottariDashas(0, '2000-01-01T00:00:00Z');
  assert.equal(zero[0].lord, 'ketu');
  assert.equal(zero[0].start, '2000-01-01T00:00:00.000Z');
  // 7 x 365.25 days from 2000-01-01 ends a quarter day short of 2007-01-01.
  assert.equal(zero[0].end, '2006-12-31T18:00:00.000Z');

  const periods = computeVimshottariDashas(187.4, '2000-01-01T00:00:00Z');
  for (let i = 0; i + 1 < periods.length; i++) assert.equal(periods[i].end, periods[i + 1].start);
  for (const maha of periods) {
    assert.equal(maha.children[0].start, maha.start);
    assert.equal(maha.children.at(-1).end, maha.end);
  }
  const chain = activeDashaChain(periods, '2010-06-01T00:00:00Z');
  assert.equal(chain.length, 3);
});

test('dashas keep microsecond precision far from 1970', () => {
  const periods = computeVimshottariDashas(SPAN / 3, '1850-03-01T06:00:00Z');
  assert.match(periods[0].start, /^18\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}(\d{3})?Z$/);
  assert.equal(formatUtcMicros(parseUtcMicros(periods[0].start)), periods[0].start);
});

test('panchang limbs', () => {
  assert.equal(tithiOf(0, 0), 1);
  assert.equal(tithiOf(0, 180), 16);
  assert.equal(karanaOf(0, 0), 10, 'Kimstughna opens the month');
  assert.equal(karanaOf(0, 6), 0, 'then Bava');
  assert.equal(karanaOf(0, 359), 9, 'Naga closes it');
  assert.equal(yogaOf(0, 0), 0);
});

test('rule evaluator matches, cancels and derives vargas on demand', () => {
  const chart = assembleChart(BIRTH, RAW);
  const matches = evaluateRules(chart, {
    version: '1.0.0',
    rules: [
      { id: 'a', conditions: [{ subject: 'positions.jupiter.house', operator: 'equals', value: 1 }] },
      { id: 'b', conditions: [{ subject: 'positions.saturn.sign', operator: 'in', value: [6, 7] }], cancelledBy: ['a'] },
      { id: 'c', conditions: [{ chart: 'd9', subject: 'ascendantSign', operator: 'between', value: [0, 11] }], strength: 0.5 },
      { id: 'd', conditions: [{ subject: 'positions.moon.house', operator: 'greaterThan', value: 11 }] },
    ],
  });
  assert.deepEqual(matches.map((m) => m.ruleId), ['a', 'c']);
  assert.equal(matches[1].strength, 0.5);
  assert.ok('d9.ascendantSign' in matches[1].evidence);
  assert.throws(() => evaluateRules(chart, { version: '1.0.0', rules: [{ id: 'x', conditions: [{ subject: 'nope', operator: 'equals', value: 1 }] }] }));
});

test('time parsing rejects non-UTC input', () => {
  assert.throws(() => parseUtcMicros('2000-01-01T00:00:00+01:00'));
  assert.equal(formatUtcMicros(parseUtcMicros('2000-01-01T00:00:00.123456Z')), '2000-01-01T00:00:00.123456Z');
});
