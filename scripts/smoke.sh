#!/usr/bin/env bash
set -euo pipefail

DEVICE_NAME=${1:-"iPhone 17"}

./scripts/run-ios-sim.sh "$DEVICE_NAME" FM_STATE_NAME=state FM_AUTO_ADVANCE=1 FM_RESET_DEFAULTS=1

UDID=$(xcrun simctl list devices available | grep -E "$DEVICE_NAME \(" | head -n1 | sed -nE 's/.*\(([0-9A-F-]+)\).*/\1/p' || true)
mkdir -p screenshots
# Give the app time to launch and auto-advance to the info step
sleep 5
xcrun simctl io "$UDID" screenshot screenshots/onboarding_info.png
echo "Screenshot saved to screenshots/onboarding_info.png"
