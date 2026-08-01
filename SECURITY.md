# Security Policy

## Reporting a vulnerability

Please do not open a public issue for security vulnerabilities.

Use GitHub's private vulnerability reporting on this repository, or contact the maintainer
directly. Expect an acknowledgement within 72 hours.

## Scope

This package performs numerical computation and parses JSON rule sets. The realistic risk
surface is:

- Memory safety in the native Swiss Ephemeris bindings (FFI boundary)
- Malformed rule sets causing unbounded computation or crashes
- Path traversal in ephemeris file loading

## Out of scope

- Astrological accuracy disputes — open a normal issue
- Vulnerabilities in upstream Swiss Ephemeris — report to Astrodienst
