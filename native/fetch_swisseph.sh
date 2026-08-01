#!/usr/bin/env bash
# Fetches Swiss Ephemeris sources and ephemeris data files.
#
# Sources are not vendored in this repository. They are retrieved here so the
# upstream version in use is explicit and verifiable.
set -euo pipefail

SWISSEPH_VERSION="${SWISSEPH_VERSION:-2.10.03}"
VENDOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/vendor"

mkdir -p "$VENDOR_DIR"

echo "Swiss Ephemeris ${SWISSEPH_VERSION}"
echo
echo "  Licence: AGPL-3.0 (this project uses the free edition)"
echo "  Upstream: https://www.astro.com/swisseph/"
echo
echo "  A paid Professional licence is also available from Astrodienst and does not"
echo "  carry the AGPL source-disclosure obligation. See ../docs/AGPL-BOUNDARY.md"
echo "  before deciding which edition your project should use."
echo

# TODO: implement retrieval and checksum verification.
#   - Fetch the source tarball for $SWISSEPH_VERSION into $VENDOR_DIR
#   - Verify against a pinned SHA-256 recorded in this repository
#   - Fetch the .se1 ephemeris data files for the supported date range
#
# Pinning the checksum is not optional: an unverified download that later
# changes upstream would silently alter every chart the engine produces.

echo "Not yet implemented. See the TODO in this script."
exit 1
