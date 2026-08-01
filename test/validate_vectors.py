#!/usr/bin/env python3
"""Structural validation of the reference vector file.

This checks that vectors are well-formed and internally consistent. It does not
check astrological correctness -- that requires the built engine and an independent
reference source.
"""
from __future__ import annotations

import json
import pathlib
import sys

VECTOR_FILE = pathlib.Path(__file__).parent / "vectors" / "reference_births.json"

REQUIRED_FIELDS = {"id", "notes", "localDateTime", "ianaZone", "latitude", "longitude"}
KNOWN_AYANAMSA = {"lahiri", "raman", "krishnamurti", "faganBradley"}
KNOWN_HOUSE_SYSTEMS = {"wholeSign", "equal", "placidus", "koch"}


def main() -> int:
    if not VECTOR_FILE.exists():
        print(f"ERROR: {VECTOR_FILE} not found", file=sys.stderr)
        return 1

    data = json.loads(VECTOR_FILE.read_text(encoding="utf-8"))
    vectors = data.get("vectors")

    if not isinstance(vectors, list) or not vectors:
        print("ERROR: 'vectors' must be a non-empty list", file=sys.stderr)
        return 1

    errors: list[str] = []
    seen_ids: set[str] = set()

    for index, vector in enumerate(vectors):
        label = vector.get("id", f"index {index}")

        missing = REQUIRED_FIELDS - vector.keys()
        if missing:
            errors.append(f"{label}: missing {sorted(missing)}")

        vector_id = vector.get("id")
        if vector_id in seen_ids:
            errors.append(f"{label}: duplicate id")
        seen_ids.add(vector_id)

        if not vector.get("notes"):
            errors.append(f"{label}: 'notes' must explain what this vector guards")

        latitude = vector.get("latitude")
        if isinstance(latitude, (int, float)) and not -90 <= latitude <= 90:
            errors.append(f"{label}: latitude {latitude} out of range")

        longitude = vector.get("longitude")
        if isinstance(longitude, (int, float)) and not -180 <= longitude <= 180:
            errors.append(f"{label}: longitude {longitude} out of range")

        ayanamsa = vector.get("ayanamsa")
        if ayanamsa is not None and ayanamsa not in KNOWN_AYANAMSA:
            errors.append(f"{label}: unknown ayanamsa {ayanamsa!r}")

        for variant in vector.get("ayanamsaVariants", []):
            if variant not in KNOWN_AYANAMSA:
                errors.append(f"{label}: unknown ayanamsa variant {variant!r}")

        house_system = vector.get("houseSystem")
        if house_system is not None and house_system not in KNOWN_HOUSE_SYSTEMS:
            errors.append(f"{label}: unknown house system {house_system!r}")

        # An unambiguous vector must pin the expected offset -- that is the whole
        # point of these cases.
        if not vector.get("ambiguous") and vector.get("expectedUtcOffsetMinutes") is None:
            errors.append(f"{label}: expectedUtcOffsetMinutes must be set unless ambiguous")

    if errors:
        print(f"{len(errors)} problem(s) found:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    unverified = [v["id"] for v in vectors if not v.get("verifiedAgainst")]

    print(f"OK: {len(vectors)} vectors, all structurally valid.")
    if unverified:
        print(f"NOTE: {len(unverified)} vector(s) awaiting independent verification:")
        for vector_id in unverified:
            print(f"  - {vector_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
