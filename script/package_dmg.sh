#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Hennessy"
VERSION="${VERSION:-1.7.11}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_ROOT="$DIST_DIR/dmg-root"
RW_DMG="$DIST_DIR/$APP_NAME-$VERSION-rw.dmg"
FINAL_DMG="$DIST_DIR/$APP_NAME-$VERSION-mac.dmg"
VOLUME_NAME="$APP_NAME"

cd "$ROOT_DIR"

"$ROOT_DIR/script/build_and_run.sh" --build-only

codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null

rm -rf "$DMG_ROOT" "$RW_DMG" "$FINAL_DMG"
mkdir -p "$DMG_ROOT"

ditto "$APP_BUNDLE" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDRW \
  "$RW_DMG" >/dev/null

hdiutil convert "$RW_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$FINAL_DMG" >/dev/null

rm -rf "$RW_DMG" "$DMG_ROOT"

echo "$FINAL_DMG"
