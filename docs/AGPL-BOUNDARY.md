# The AGPL Boundary

**Status:** Accepted
**Date:** 2026-08-01
**Applies to:** `jyotish-engine` (this repository) and any consuming application

---

## Summary

Swiss Ephemeris is used here under the **GNU AGPL-3.0**, not the paid Professional licence.
AGPL-3.0 section 13 requires that users who interact with the software *over a network* be
offered its complete corresponding source.

To use this engine inside a commercial product without placing that entire product under
AGPL, the engine runs **client-side only**. No server-side component may link to, bundle,
embed, or invoke it.

---

## The problem

The obvious architecture — a backend service that computes charts and returns them to clients
over HTTP — triggers AGPL section 13. Under that design, every user of the product is a
"user interacting over a network" with AGPL software, and the operator must offer them the
complete source of the work. In a commercial product that means the order system, payment
logic, business rules and proprietary content all become disclosable.

This is not a marginal interpretation. It is the intended and well-understood effect of the
AGPL network clause, and it is precisely why Astrodienst offers a paid alternative.

## The decision

Swiss Ephemeris and everything that links to it live in this repository, which is public and
AGPL-3.0. It executes only in contexts the end user controls:

| Context | Mechanism | Runs where |
|---|---|---|
| Mobile application | Dart FFI, statically linked | On the user's device |
| Web console | WebAssembly, loaded in the page | In the user's browser |

Consuming applications compute charts locally and transmit **results** — plain JSON data —
to their own backend. Data is not a derivative work of the program that produced it.

## What this means in practice

**Permitted:**

- Bundling this package into a mobile app whose source is published under AGPL-3.0
- Loading the WASM build in a browser page
- Sending computed chart JSON to any backend, proprietary or otherwise
- Storing, rendering, transforming and selling access to those results

**Not permitted without placing the consuming service under AGPL:**

- Importing this package into a server process
- Running the WASM build under Node.js or any other server runtime
- Wrapping it in an internal HTTP, gRPC or queue-consuming service
- Invoking the native binaries from a backend job or worker
- Shipping it inside a container image that runs server-side

## Enforcement

The consuming repository runs a CI check (`scripts/check_agpl_boundary.sh`) that fails the
build if server-side code references this package or any Swiss Ephemeris symbol. It is a
blunt instrument — a grep — and it is not a substitute for understanding the rule. It exists
to catch the accidental import at 2am, not to define the boundary.

## Consequences

*Positive*

- No licence fee.
- Chart computation is free, instant, and offline; no ephemeris service to run or scale.
- Birth data need never leave the device for computation purposes.
- The published package is a genuine contribution and carries no competitive information.

*Negative*

- The engine wrapper is public. It contains no business logic, so the practical cost is low.
- The backend can never compute a chart. Any server-side need — batch recalculation, a
  migration, an admin repair tool — requires either a client round-trip or a separately
  licensed implementation.
- Rectification and ayanamsa changes must be performed in a client context.
- Every future engineer must understand this. It is not intuitive and it is easy to breach.

## Alternatives considered

**Swiss Ephemeris Professional licence — CHF 750 one-off.** Removes the constraint entirely
and permits server-side computation. Rejected here in favour of the free edition, but it
remains the simpler option and the cost is modest relative to the engineering care this
boundary demands. Revisit if server-side computation ever becomes genuinely necessary.

**A permissively licensed engine** (Astronomy Engine, Skyfield with JPL ephemerides, both
MIT or public domain). No disclosure obligation at all, but the sidereal and Vedic layers —
ayanamsa handling, divisional charts, dasha computation — would need to be implemented from
scratch and validated independently.

**Open-sourcing the whole platform.** Viable for some businesses. Rejected because the
interpretation rule sets and content are the product's differentiation.

## Review

This document must be reviewed by a software-licensing lawyer before any public launch.
Nothing here is legal advice. The reasoning is sound and conventional, but the consequence of
being wrong is disclosure of the entire commercial codebase, and that warrants a professional
opinion rather than a confident engineer.
