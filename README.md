# jyotish-engine

Sidereal (Vedic) astrological calculation engine — Dart FFI bindings and a WebAssembly build
around [Swiss Ephemeris](https://www.astro.com/swisseph/), plus a generic, data-driven rule
evaluator.

**This package is deliberately free of business logic.** It computes astronomical and
astrological facts and evaluates externally supplied rule sets. It does not contain
interpretation content, product logic, or anything specific to a particular application.

[![CI](https://github.com/YOUR-GITHUB-USERNAME/jyotish-engine/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR-GITHUB-USERNAME/jyotish-engine/actions/workflows/ci.yml)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](LICENSE)

---

## Why this repository exists

Swiss Ephemeris is dual-licensed: a paid Professional licence, or the **GNU AGPL-3.0**.
This project uses the AGPL edition, which means any software that incorporates it must
itself be released under a compatible licence.

To use it in a commercial product without open-sourcing that entire product, the engine is
isolated here and executed **client-side only** — in mobile apps via Dart FFI, and in browsers
via WebAssembly. No server-side component ever links to, bundles, or calls this code.

That boundary is the whole point of this repository. It is documented in
[`docs/AGPL-BOUNDARY.md`](docs/AGPL-BOUNDARY.md) and enforced in CI. **Read it before
integrating this package into anything.**

---

## What it computes

| Area | Detail |
|---|---|
| Positions | Nine grahas including Rahu/Ketu (mean and true node), sidereal longitude, latitude, speed |
| Dignity | Exaltation, debilitation, own sign, combustion, retrogression |
| Nakshatras | Nakshatra, pada, and lord for every body |
| Houses | Whole sign (default), Placidus, Koch, Equal |
| Ayanamsa | Lahiri/Chitrapaksha (default), Raman, Krishnamurti, Fagan-Bradley |
| Divisionals | D1, D2, D3, D7, D9, D10, D12 |
| Dashas | Vimshottari — mahadasha, antardasha, pratyantardasha |
| Panchang | Tithi, nakshatra, yoga, karana, vara, sunrise/sunset |
| Transits | Current positions relative to a natal chart |
| Rules | Generic evaluator for externally supplied JSON rule sets |

---

## Repository layout

```
packages/dart/     Dart package with FFI bindings          → mobile apps
packages/wasm/     TypeScript wrapper over a WASM build    → browsers
packages/rules/    Rule-set JSON schema and evaluator spec
native/            Build scripts for iOS, Android and WASM targets
test/vectors/      Reference births with expected output (golden master)
docs/              Architecture, AGPL boundary, accuracy methodology
```

---

## Getting started

Swiss Ephemeris sources are **not vendored** in this repository. Fetch them first:

```bash
./native/fetch_swisseph.sh          # downloads and verifies upstream sources
./native/build_android.sh           # arm64-v8a, armeabi-v7a, x86_64
./native/build_ios.sh               # arm64 device + simulator
./native/build_wasm.sh              # requires Emscripten
```

Then:

```bash
cd packages/dart && dart pub get && dart test
cd packages/wasm && npm install && npm test
```

See [`native/README.md`](native/README.md) for toolchain prerequisites.

---

## Accuracy

Correctness is verified against a golden-master suite of reference births in
`test/vectors/reference_births.json`, covering the cases where astrology software
most often fails silently:

- Historical DST transitions (German double summer time 1945–1949; the 1950–1979 gap)
- Pre-1955 Indian time offsets (+05:30 vs Calcutta's +05:53:20)
- High-latitude births where some house systems degenerate
- Pre-1900 births
- Ayanamsa boundary conditions

**The Dart and WASM builds must produce identical output for every vector.** CI fails on any
divergence. A chart that differs between platforms is a correctness bug, not a rounding
difference. See [`docs/ACCURACY.md`](docs/ACCURACY.md).

---

## Licence

AGPL-3.0-only. See [`LICENSE`](LICENSE).

If you deploy software that incorporates this package and users interact with it over a
network, AGPL section 13 requires you to offer those users the corresponding source. Consult
[`docs/AGPL-BOUNDARY.md`](docs/AGPL-BOUNDARY.md) and, if a commercial product is involved,
a lawyer.

Third-party components and their licences are listed in [`NOTICE`](NOTICE).
