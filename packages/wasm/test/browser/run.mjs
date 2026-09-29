// Runs test/browser/harness.html in headless Chrome and checks the results.
//
// The engine refuses to load outside a browser, so its WebAssembly half can only be
// tested in one. The static file server below exists for this test alone and binds
// to localhost; it is not a way to serve the engine.
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';
import { chromium } from 'playwright-core';

const root = fileURLToPath(new URL('../../', import.meta.url));
const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.wasm': 'application/wasm' };

const server = createServer(async (request, response) => {
  const path = normalize(decodeURIComponent(new URL(request.url, 'http://localhost').pathname));
  try {
    const body = await readFile(join(root, path));
    response.writeHead(200, { 'content-type': types[extname(path)] ?? 'application/octet-stream' });
    response.end(body);
  } catch {
    response.writeHead(404).end();
  }
});
await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
const { port } = server.address();

const browser = await chromium.launch({
  channel: process.env.CHROME_PATH ? undefined : 'chrome',
  executablePath: process.env.CHROME_PATH,
});
let failed = false;
try {
  const page = await browser.newPage();
  await page.goto(`http://127.0.0.1:${port}/test/browser/harness.html`);
  await page.waitForFunction(() => window.__result || window.__error, null, { timeout: 30_000 });
  const error = await page.evaluate(() => window.__error);
  assert.equal(error, undefined, error);
  const r = await page.evaluate(() => window.__result);

  const checks = {
    'engine version is embedded': () => assert.equal(r.chart.engineVersion, r.version),
    'input time is canonicalised': () => assert.equal(r.chart.input.utcDateTime, '2000-01-01T12:00:00.000Z'),
    // J2000.0 reference values (Astronomical Almanac): apparent Sun 280.37, Moon 223.32.
    'Lahiri ayanamsa at J2000 is 23 deg 51 min': () => assert.ok(Math.abs(r.chart.ayanamsaValue - 23.853) < 0.01),
    'Sun at J2000': () => assert.ok(Math.abs(r.chart.positions.sun.siderealLongitude + r.chart.ayanamsaValue - 280.37) < 0.01),
    'Moon at J2000': () => assert.ok(Math.abs(r.chart.positions.moon.siderealLongitude + r.chart.ayanamsaValue - 223.32) < 0.05),
    'Saturn is retrograde at J2000': () => assert.equal(r.chart.positions.saturn.isRetrograde, true),
    'Ketu opposes Rahu': () => assert.equal((r.chart.positions.ketu.siderealLongitude - r.chart.positions.rahu.siderealLongitude + 360) % 360, 180),
    'repeat computation is bit-identical': () => assert.equal(r.repeatIdentical, true),
    // Berlin, 21 June 2026: sunrise 04:43 CEST, sunset 21:33 CEST.
    'Berlin midsummer sunrise': () => assert.ok(Math.abs(Date.parse(r.panchang.sunrise) - Date.parse('2026-06-21T02:43:00Z')) < 120_000),
    'Berlin midsummer sunset': () => assert.ok(Math.abs(Date.parse(r.panchang.sunset) - Date.parse('2026-06-21T19:33:00Z')) < 120_000),
    'no sunrise in Tromsø at midsummer': () => assert.equal(r.polarPanchang.sunrise, null),
    'dates before 1800 are rejected': () => assert.match(r.outOfRange, /outside the supported range/),
    'placidus cusps come from the ephemeris': () => assert.equal(r.placidusCusps, 12),
    'worker entry point gives identical output': () => assert.equal(r.workerIdentical, true),
    'transits use natal houses': () => assert.equal(r.transitAscendant, r.chart.ascendant),
  };
  for (const [name, check] of Object.entries(checks)) {
    try {
      check();
      console.log(`ok   ${name}`);
    } catch (e) {
      failed = true;
      console.log(`FAIL ${name}\n     ${e.message}`);
    }
  }
} finally {
  await browser.close();
  server.close();
}
process.exit(failed ? 1 : 0);
