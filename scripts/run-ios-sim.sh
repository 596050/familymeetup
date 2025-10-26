#!/usr/bin/env bash
set -euo pipefail

PROJECT="FamilyMeet.xcodeproj"
SCHEME="FamilyMeet"
BUNDLE_ID="com.familymeet.app"

if ! command -v xcodebuild >/dev/null 2>&1 || ! command -v xcrun >/dev/null 2>&1; then
  echo "Xcode command-line tools are required. Open Xcode once to install them."
  exit 1
fi

DEVICE_NAME=${1:-}
if [[ -z "$DEVICE_NAME" ]]; then
  DEVICE_NAME=$(xcrun simctl list devices available | sed -nE 's/.*(iPhone (15 Pro Max|15 Pro|15|14 Pro Max|14 Pro|14|13 Pro|13)).*\(([-0-9A-F]+)\).*/\1/p' | head -n1 || true)
  [[ -z "$DEVICE_NAME" ]] && DEVICE_NAME="iPhone 15 Pro"
fi

UDID=$(xcrun simctl list devices available | grep -E "$DEVICE_NAME \(" | head -n1 | sed -nE 's/.*\(([0-9A-F-]+)\).*/\1/p' || true)
if [[ -z "$UDID" ]]; then
  echo "No available simulator named '$DEVICE_NAME' was found. Open Xcode > Settings > Platforms to install simulators."
  exit 1
fi

echo "Booting $DEVICE_NAME ($UDID) if needed..."
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || xcrun simctl boot "$UDID" >/dev/null 2>&1 || true

echo "Resolving build settings..."
BUILD_SETTINGS=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug -sdk iphonesimulator -destination "platform=iOS Simulator,id=$UDID" -showBuildSettings 2>/dev/null)
TARGET_BUILD_DIR=$(echo "$BUILD_SETTINGS" | sed -nE 's/ *TARGET_BUILD_DIR = (.*)/\1/p' | tail -n1)
FULL_PRODUCT_NAME=$(echo "$BUILD_SETTINGS" | sed -nE 's/ *FULL_PRODUCT_NAME = (.*)/\1/p' | tail -n1)

echo "Building $SCHEME for $DEVICE_NAME..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug -sdk iphonesimulator -destination "platform=iOS Simulator,id=$UDID" -quiet build

APP_PATH="$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME"

echo "Installing app..."
xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$APP_PATH"

echo "Launching app..."
# Pass any extra KEY=VALUE args as --env to simctl launch
ENV_ARGS=()
shift || true
for kv in "$@"; do
  if [[ "$kv" == *"="* ]]; then
    ENV_ARGS+=(--env "$kv")
  fi
done
if [[ ${#ENV_ARGS[@]} -gt 0 ]]; then
  xcrun simctl launch "${ENV_ARGS[@]}" "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
else
  xcrun simctl launch "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
fi
open -a Simulator || true

echo "Done. Launched $SCHEME on $DEVICE_NAME ($UDID)."
