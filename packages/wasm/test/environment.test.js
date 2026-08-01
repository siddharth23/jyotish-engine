import { test } from 'node:test';
import assert from 'node:assert/strict';

import { loadEngine, ENGINE_VERSION } from '../src/index.ts';

test('engine version follows semantic versioning', () => {
  assert.match(ENGINE_VERSION, /^\d+\.\d+\.\d+/);
});

test('loadEngine refuses to run outside a browser', async () => {
  // Guards the AGPL boundary: this package must not run server-side.
  await assert.rejects(() => loadEngine(), /browser-only/);
});
