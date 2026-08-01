# Contributing

Thanks for your interest. A few things worth knowing before you open a pull request.

## Licence

This project is AGPL-3.0-only. By contributing you agree your contribution is licensed under
the same terms. Do not submit code you do not have the right to license this way.

## Scope

This package computes astronomical and astrological facts and evaluates externally supplied
rule sets. It deliberately contains **no interpretation content and no product logic**.

Pull requests that add interpretive text, opinions about what a placement "means", or logic
specific to one application will be declined — not because they are wrong, but because they
belong in the consuming application, not here.

## The AGPL boundary

`docs/AGPL-BOUNDARY.md` explains why this code must remain callable only from client-side
contexts. Changes that make server-side execution easier or more likely (adding an HTTP
server, a daemon mode, a hosted API client) will not be accepted. This is a licensing
constraint, not a technical preference.

## Accuracy changes

Any change affecting numerical output must:

1. State which reference source you validated against (astro.com, JPL Horizons, or a named
   classical text for rule-based output).
2. Include or update vectors in `test/vectors/reference_births.json`.
3. Keep the Dart and WASM builds byte-identical in their output. CI enforces this.

An accuracy change that passes CI but silently shifts existing charts is the most damaging
kind of bug in this domain. If you are unsure whether something counts, open an issue first.

## Development

```bash
./native/fetch_swisseph.sh
./native/build_android.sh && ./native/build_wasm.sh
cd packages/dart && dart pub get && dart test
cd packages/wasm && npm install && npm test
```

## Commit messages

Conventional Commits: `feat:`, `fix:`, `docs:`, `test:`, `chore:`, `refactor:`.
Reference an issue where one exists.

## Reporting a calculation error

Open an issue with the full birth input (date, time, coordinates, timezone, ayanamsa,
house system), what the engine produced, what you expected, and your reference source.
Charts cannot be debugged without the exact inputs.
