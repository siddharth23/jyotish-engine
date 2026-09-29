// Copies the Emscripten output into dist/native so the package ships a complete,
// self-contained browser build. A missing native build is not an error here: the
// pure derivation layer still builds and tests without it.
import { cpSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const source = fileURLToPath(new URL('../../../native/out/wasm/', import.meta.url));
const target = fileURLToPath(new URL('../dist/native/', import.meta.url));

if (existsSync(source)) {
  cpSync(source, target, { recursive: true });
  console.log('Copied native build into dist/native.');
} else {
  console.warn('No native build found. Run ../../native/fetch_swisseph.sh and build_wasm.sh.');
}
