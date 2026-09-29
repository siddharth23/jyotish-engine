#!/usr/bin/env bash
# Builds Swiss Ephemeris to WebAssembly for browser use.
#
# The resulting module is for BROWSER use only. Loading it in a server-side runtime
# places the surrounding service under AGPL-3.0. See ../docs/AGPL-BOUNDARY.md.
set -euo pipefail

command -v emcc >/dev/null 2>&1 || {
  echo "ERROR: emcc not found. Install Emscripten 3.1.50 or later." >&2
  exit 1
}

NATIVE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$NATIVE_DIR/vendor/swisseph-2.10.03"
EPHE_DIR="$NATIVE_DIR/vendor/ephe"
OUT_DIR="$NATIVE_DIR/out/wasm"

[[ -d "$SOURCE_DIR" && -d "$EPHE_DIR" ]] || {
  echo "ERROR: Swiss Ephemeris sources missing. Run ./native/fetch_swisseph.sh first." >&2
  exit 1
}

SOURCES=(sweph.c swephlib.c swecl.c swehouse.c swejpl.c swemmoon.c swemplan.c swedate.c)

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR/ephe"

echo "Building WebAssembly module"
# -ffp-contract=off keeps floating point contraction out of the output, so the same
# inputs yield bit-identical results in every browser.
emcc -O2 -ffp-contract=off \
  -I "$SOURCE_DIR" \
  "${SOURCES[@]/#/$SOURCE_DIR/}" \
  "$NATIVE_DIR/shim/jyotish_shim.c" \
  -o "$OUT_DIR/jyotish_engine.mjs" \
  -sMODULARIZE=1 \
  -sEXPORT_ES6=1 \
  -sEXPORT_NAME=createJyotishModule \
  -sENVIRONMENT=web,worker \
  -sALLOW_MEMORY_GROWTH=1 \
  -sFILESYSTEM=1 \
  -sFORCE_FILESYSTEM=1 \
  -sEXPORTED_FUNCTIONS=_jy_set_ephe_path,_jy_raw_length,_jy_raw,_jy_sun_rise_set,_jy_close,_malloc,_free \
  -sEXPORTED_RUNTIME_METHODS=FS,UTF8ToString,stringToUTF8,HEAPF64 \
  -Wno-deprecated-non-prototype

cp "$EPHE_DIR"/*.se1 "$OUT_DIR/ephe/"

echo "Built:"
ls -l "$OUT_DIR" "$OUT_DIR/ephe"
