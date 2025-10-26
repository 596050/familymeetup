#!/usr/bin/env bash
set -euo pipefail

SCHEME="FamilyMeet"
PROJECT="FamilyMeet.xcodeproj"
DEST=${1:-"platform=iOS Simulator,name=iPhone 17"}
OUTDIR="build"
XCRESULT="$OUTDIR/TestResults.xcresult"
EXPORTDIR="$OUTDIR/xcresult-export"
SCREENSHOT_DIR="screenshots"

rm -rf "$OUTDIR" "$SCREENSHOT_DIR"
mkdir -p "$OUTDIR" "$SCREENSHOT_DIR"

echo "Running UI tests on $DEST..."
xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "$DEST" \
  -resultBundlePath "$XCRESULT" \
  | tee "$OUTDIR/xcodebuild.log" || true

echo "Exporting attachments..."
xcrun xcresulttool export --legacy --type directory --path "$XCRESULT" --output-path "$EXPORTDIR"

echo "Collecting screenshots..."
find "$EXPORTDIR" -type f -name "*.png" -print -exec cp {} "$SCREENSHOT_DIR" \;

echo "Done. Screenshots at: $SCREENSHOT_DIR"
