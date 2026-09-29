import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

import { assembleChart, computeDivisionalChart } from '../dist/derivation/chart.js';
import { computeVimshottariDashas } from '../dist/derivation/vimshottari.js';
import { formatUtcMicros, parseUtcMicros } from '../dist/derivation/time.js';

// The Dart package is the reference implementation of the derivation half. Its output
// for these synthetic raw ephemeris inputs is committed; this port must reproduce every
// value exactly. Regenerate with `dart run tool/derive.dart` in packages/dart.
const read = (name) => JSON.parse(readFileSync(new URL(`../../../test/parity/${name}`, import.meta.url), 'utf8'));
const { cases } = read('cases.json');
const { results } = read('dart_output.json');

test('fixtures line up', () => {
  assert.equal(cases.length, results.length);
});

for (const [index, c] of cases.entries()) {
  test(`derivation matches Dart: ${c.id}`, () => {
    const expected = results[index];
    const birth = { ...c.birth, utcDateTime: formatUtcMicros(parseUtcMicros(c.birth.utcDateTime)) };
    const raw = { ...c.raw, houseCusps: c.raw.houseCusps ?? undefined };
    const chart = assembleChart(birth, raw);

    assert.deepEqual(JSON.parse(JSON.stringify(chart)), expected.d1);
    assert.deepEqual(JSON.parse(JSON.stringify(computeDivisionalChart(chart, 'd9'))), expected.d9);
    assert.deepEqual(JSON.parse(JSON.stringify(computeDivisionalChart(chart, 'd10'))), expected.d10);
    const dashas = computeVimshottariDashas(chart.positions.moon.siderealLongitude, birth.utcDateTime, 2).slice(0, 3);
    assert.deepEqual(dashas, expected.dashas);
  });
}
