#!/usr/bin/env bash
# Builds Swiss Ephemeris to WebAssembly for browser use.
set -euo pipefail

command -v emcc >/dev/null 2>&1 || {
  echo "ERROR: emcc not found. Install Emscripten 3.1.50 or later." >&2
  exit 1
}

OUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/out/wasm"
mkdir -p "$OUT_DIR"

echo "Building WebAssembly module"
# TODO: emcc invocation producing jyotish_engine.wasm + JS glue.
#
# The resulting module is for BROWSER use only. Loading it in a server-side runtime
# places the surrounding service under AGPL-3.0. See ../docs/AGPL-BOUNDARY.md.

echo "Not yet implemented."
exit 1
