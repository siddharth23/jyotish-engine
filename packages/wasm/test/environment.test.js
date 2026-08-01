import { test } from 'node:test';
import assert from 'node:assert/strict';

// Imports the built output rather than the TypeScript source: Node cannot load
// .ts directly, and testing dist/ is what consumers actually get. `npm test`
// builds first.
import { loadEngine, ENGINE_VERSION } from '../dist/index.js';

test('engine version follows semantic versioning', () => {
  assert.match(ENGINE_VERSION, /^\d+\.\d+\.\d+/);
});

test('loadEngine refuses to run outside a browser', async () => {
  // Guards the AGPL boundary: this package must not run server-side.
  await assert.rejects(() => loadEngine(), /browser-only/);
});
