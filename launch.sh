#!/usr/bin/env sh

# Launch an app on the iOS simulator (with ShowTime injected) or a connected device.
#
# Usage: ./launch.sh <UDID> <bundle_id> [sim|device]
#   UDID:    simulator device ("booted" or a UDID) or physical device (UDID or "connected")
#   bundle_id: app bundle identifier (e.g. com.spotify.client)
#   sim|device: optional; "sim" = simulator (default), "device" = real device
#
# Simulator (injects ShowTime.framework):
#   ./launch.sh booted com.spotify.client
#   ./launch.sh booted com.spotify.client sim
#
# Real device (no injection; iOS does not allow DYLD_INSERT_LIBRARIES on device):
#   ./launch.sh connected com.spotify.client device
#   ./launch.sh C05A91BB-CB9F-5467-976E-E632FEE56C67 com.spotify.client device

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK_PATH="${FRAMEWORK_PATH:-${SCRIPT_DIR}/Fwk/ShowTime.framework/ShowTime}"

UDID="${1:?Usage: $0 <UDID> <bundle_id> [sim|device]}"
BUNDLE_ID="${2:?Usage: $0 <UDID> <bundle_id> [sim|device]}"
TARGET="${3:-sim}"

if [ "$TARGET" = "device" ]; then
  DEVICE_ID="$UDID"
  if [ "$UDID" = "connected" ] || [ "$UDID" = "device" ]; then
    DEVICE_ID=$(xcrun devicectl list devices 2>/dev/null | grep 'connected' | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -1)
    [ -z "$DEVICE_ID" ] && { echo "No connected device found. Run: xcrun devicectl list devices"; exit 1; }
  fi
  xcrun devicectl device process launch --device "$DEVICE_ID" --terminate-existing "$BUNDLE_ID"
else
  export SIMCTL_CHILD_DYLD_INSERT_LIBRARIES="$FRAMEWORK_PATH"
  xcrun simctl launch "$UDID" "$BUNDLE_ID"
fi
