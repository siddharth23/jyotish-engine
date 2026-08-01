#!/usr/bin/env bash
# Builds Swiss Ephemeris shared libraries for all supported Android ABIs.
set -euo pipefail

: "${ANDROID_NDK_HOME:?ANDROID_NDK_HOME must be set}"

ABIS=("arm64-v8a" "armeabi-v7a" "x86_64")
API_LEVEL="${API_LEVEL:-24}"
OUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/out/android"

mkdir -p "$OUT_DIR"

for abi in "${ABIS[@]}"; do
  echo "Building $abi (API $API_LEVEL)"
  # TODO: invoke the NDK toolchain and emit libswisseph.so into $OUT_DIR/$abi/
done

# Every ABI must be present. A missing one does not fail the build; it crashes at
# runtime on devices you probably do not own.
for abi in "${ABIS[@]}"; do
  if [[ ! -f "$OUT_DIR/$abi/libswisseph.so" ]]; then
    echo "ERROR: missing build output for $abi" >&2
    exit 1
  fi
done

echo "All ABIs built."
