#!/usr/bin/env bash
# Fetches Swiss Ephemeris sources and ephemeris data files.
#
# Sources are not vendored in this repository. They are retrieved here so the
# upstream version in use is explicit and verifiable.
set -euo pipefail

SWISSEPH_VERSION="2.10.03"
SOURCE_URL="https://codeload.github.com/aloistr/swisseph/tar.gz/refs/tags/v${SWISSEPH_VERSION}"
SOURCE_SHA256="8c166796767a560691581575b6eb4b4383d849e542b16647dca2e0b127fb70b0"

# The data files are not part of the release tag, so they are pinned to a commit.
EPHE_COMMIT="9083a12d59e98034fb2337061481ac8800c16e64"
EPHE_BASE_URL="https://raw.githubusercontent.com/aloistr/swisseph/${EPHE_COMMIT}/ephe"

# Planets and Moon for 1800-2399 AD. Birth years outside that range are rejected by
# the engine rather than silently computed with a lower-precision fallback.
EPHE_FILES=(
  "sepl_18.se1 ca1393ceab3a44fbc895887cf789c68819ae6a1cbc9b22225872dbe4ccd99a66"
  "semo_18.se1 1ca07bd67c24374d77226180c20a4f9996cba013697894810518e7eb582ca4f7"
)

NATIVE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR_DIR="$NATIVE_DIR/vendor"
SOURCE_DIR="$VENDOR_DIR/swisseph-${SWISSEPH_VERSION}"
EPHE_DIR="$VENDOR_DIR/ephe"

echo "Swiss Ephemeris ${SWISSEPH_VERSION}"
echo "  Licence: AGPL-3.0 (this project uses the free edition)"
echo "  Upstream: https://www.astro.com/swisseph/"
echo

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

# Downloads $1 to $2 and fails unless its SHA-256 equals $3. An unverified download
# that later changed upstream would silently alter every chart the engine produces.
fetch_verified() {
  local url="$1" target="$2" expected="$3"
  if [[ -f "$target" && "$(sha256 "$target")" == "$expected" ]]; then
    echo "  ok (cached)  $(basename "$target")"
    return
  fi
  curl --fail --silent --show-error --location --output "$target.part" "$url"
  local actual
  actual="$(sha256 "$target.part")"
  if [[ "$actual" != "$expected" ]]; then
    rm -f "$target.part"
    echo "ERROR: checksum mismatch for $(basename "$target")" >&2
    echo "  expected $expected" >&2
    echo "  actual   $actual" >&2
    exit 1
  fi
  mv "$target.part" "$target"
  echo "  ok           $(basename "$target")"
}

mkdir -p "$VENDOR_DIR" "$EPHE_DIR"

echo "Sources"
tarball="$VENDOR_DIR/swisseph-${SWISSEPH_VERSION}.tar.gz"
fetch_verified "$SOURCE_URL" "$tarball" "$SOURCE_SHA256"
rm -rf "$SOURCE_DIR"
tar -xzf "$tarball" -C "$VENDOR_DIR"

echo "Ephemeris data"
for entry in "${EPHE_FILES[@]}"; do
  read -r name checksum <<<"$entry"
  fetch_verified "$EPHE_BASE_URL/$name" "$EPHE_DIR/$name" "$checksum"
done

echo
echo "Done. Sources in native/vendor/, data files in native/vendor/ephe/."
