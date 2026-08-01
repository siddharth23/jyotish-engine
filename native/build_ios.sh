#!/usr/bin/env bash
# Builds Swiss Ephemeris as an xcframework for iOS device and simulator.
set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
  echo "ERROR: iOS builds require a macOS host." >&2
  exit 1
fi

OUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/out/ios"
MIN_IOS_VERSION="${MIN_IOS_VERSION:-13.0}"

mkdir -p "$OUT_DIR"

echo "Building for iOS (minimum ${MIN_IOS_VERSION})"
# TODO:
#   - Build arm64 for iphoneos
#   - Build arm64 + x86_64 for iphonesimulator
#   - Combine with xcodebuild -create-xcframework

echo "Not yet implemented."
exit 1
