# @jyotish/engine-wasm

WebAssembly build of the Jyotish calculation engine. **Browser only.**

## Licensing

AGPL-3.0-only. This package embeds Swiss Ephemeris.

Running it in Node.js, Deno, Bun or any other server-side runtime places your entire service
under AGPL-3.0 and requires you to offer its complete source to every user who interacts with
it over a network. `loadEngine()` throws outside a browser as a safety net.

See `docs/AGPL-BOUNDARY.md` in the repository root.

## Build

```bash
../../native/fetch_swisseph.sh
../../native/build_wasm.sh     # requires Emscripten
npm install && npm run build
```

## Use

```ts
import { loadEngine } from '@jyotish/engine-wasm';

const engine = await loadEngine();
const chart = engine.computeChart({
  utcDateTime: '1989-04-12T13:12:00Z',
  latitude: 28.6139,
  longitude: 77.2090,
  ayanamsa: 'lahiri',
  houseSystem: 'wholeSign',
});
engine.dispose();
```
