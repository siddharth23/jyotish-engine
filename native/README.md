# Native builds

Swiss Ephemeris sources are **not vendored** in this repository. They are fetched and
verified at build time by `fetch_swisseph.sh`.

## Prerequisites

| Target | Requires |
|---|---|
| Android | Android NDK r26 or later, `ANDROID_NDK_HOME` set |
| iOS | Xcode 15 or later, macOS host |
| WASM | Emscripten 3.1.50 or later, `emcc` on PATH (`brew install emscripten` on macOS) |

## Build

```bash
./fetch_swisseph.sh      # downloads and checksums upstream sources
./build_android.sh       # arm64-v8a, armeabi-v7a, x86_64
./build_ios.sh           # arm64 device + simulator, produces an xcframework
./build_wasm.sh          # produces out/wasm/: jyotish_engine.mjs, .wasm and ephe/
```

Output lands in `native/out/`, which is gitignored.

## ABI coverage

All three Android ABIs must be built. A missing ABI does not fail loudly — it crashes at
runtime on the subset of devices using it, typically ones you do not own.

## Ephemeris data files

The `.se1` data files are large and are not committed. `fetch_swisseph.sh` retrieves
`sepl_18.se1` and `semo_18.se1` (planets and Moon, 1800–2399), pinned by SHA-256. The engine
rejects dates outside that range instead of silently using the lower-precision Moshier
fallback.

## The C shim

`shim/jyotish_shim.c` is the only native code of our own. It returns raw values — longitudes,
speeds, ascendant, cusps, ayanamsa, sunrise and sunset — and nothing derived.

## Licence reminder

Everything built here is AGPL-3.0. It may be linked into client-side applications only.
See `../docs/AGPL-BOUNDARY.md`.
