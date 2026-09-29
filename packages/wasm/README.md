# @jyotish/engine-wasm

WebAssembly build of the Jyotish calculation engine. **Browser only.**

## Licensing

AGPL-3.0-only. This package embeds Swiss Ephemeris.

Running it in Node.js, Deno, Bun or any other server-side runtime places your entire service
under AGPL-3.0 and requires you to offer its complete source to every user who interacts with
it over a network. `loadEngine()` throws outside a browser as a safety net.

A page that loads this engine must offer its users the corresponding source — a link to this
repository at the commit you built from.

See `docs/AGPL-BOUNDARY.md` in the repository root.

## Build

```bash
../../native/fetch_swisseph.sh   # sources and data files, checksum-verified
../../native/build_wasm.sh       # requires Emscripten
npm install && npm run build     # TypeScript, then copies the native build into dist/native
```

`dist/native/` holds `jyotish_engine.mjs`, `jyotish_engine.wasm` and `ephe/` (about 2 MB of
Swiss Ephemeris data for 1800–2399). Serve that directory as static files.

## Use

```ts
import { loadEngine } from '@jyotish/engine-wasm';

const engine = await loadEngine({ assetBaseUrl: '/engine/' });
const chart = engine.computeChart({
  utcDateTime: '1989-04-12T13:12:00Z',
  latitude: 28.6139,
  longitude: 77.2090,
  ayanamsa: 'lahiri',       // default
  houseSystem: 'wholeSign', // default
});
const navamsa = engine.computeDivisional(chart, 'd9');
const dashas = engine.computeDashas(chart, 3);
engine.dispose();
```

Local-to-UTC conversion is the caller's responsibility, and must use the IANA history for the
birthplace and date — not the user's current timezone.

Dates outside 1800–2399 throw rather than falling back to a lower-precision ephemeris.

## Web Worker

`dist/worker.js` runs the engine off the main thread. An application can use it without
importing any engine code — serve `dist/` as static files and exchange JSON messages:

```ts
const worker = new Worker('/engine/worker.js', { type: 'module' });
worker.onmessage = ({ data }) => { /* { id, result } or { id, error }; id 0 = ready */ };
worker.postMessage({ id: 1, method: 'computeChart', args: [{ utcDateTime, latitude, longitude }] });
```

## Structure

| Path | What |
|---|---|
| `src/derivation/` | Pure arithmetic over raw longitudes: signs, nakshatras, dignity, vargas, dashas, panchang, rules. A port of `packages/dart`, checked value-for-value against it by `test/parity.test.js`. |
| `src/native.ts` | Binding to the Emscripten module (`native/shim/jyotish_shim.c`). |
| `src/index.ts` | `loadEngine` and the public API. |

## Tests

```bash
npm test               # derivation unit tests and Dart parity, in Node (no WebAssembly)
npm run test:browser   # the full engine in headless Chrome
```
