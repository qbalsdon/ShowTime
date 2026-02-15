#!/usr/bin/env sh

# Build ShowTime.framework for the running simulator and copy it into Fwk/.
# Usage: ./build.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

BOOTED_UDID=$(xcrun simctl list devices | grep -E 'Booted' | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -1)
if [ -z "$BOOTED_UDID" ]; then
  echo "No booted simulator found. Start a simulator and run this script again."
  exit 1
fi

echo "Building for booted simulator ($BOOTED_UDID)..."
xcodebuild -scheme ShowTime \
  -destination "platform=iOS Simulator,id=$BOOTED_UDID" \
  -derivedDataPath "$SCRIPT_DIR/build" \
  -quiet

FRAMEWORK_SRC="$SCRIPT_DIR/build/Build/Products/Debug-iphonesimulator/PackageFrameworks/ShowTime.framework"
if [ ! -d "$FRAMEWORK_SRC" ]; then
  echo "Build succeeded but framework not found at $FRAMEWORK_SRC"
  exit 1
fi

mkdir -p "$SCRIPT_DIR/Fwk"
rm -rf "$SCRIPT_DIR/Fwk/ShowTime.framework"
cp -R "$FRAMEWORK_SRC" "$SCRIPT_DIR/Fwk/"

FWK_PATH="$SCRIPT_DIR/Fwk/ShowTime.framework/ShowTime"
xcrun simctl spawn booted launchctl setenv DYLD_INSERT_LIBRARIES "$FWK_PATH"
xcrun simctl spawn booted launchctl stop com.apple.SpringBoard

echo "Done. ShowTime.framework copied to Fwk/ and simulator env set."
