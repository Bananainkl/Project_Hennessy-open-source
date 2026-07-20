#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Hennessy"
BUNDLE_ID="com.local.Hennessy"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
APP_BUILD="$(tr -d '[:space:]' < "$ROOT_DIR/BUILD_NUMBER")"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON="$ROOT_DIR/Assets/AppIcon/Hennessy.icns"
APP_TOOLS="$ROOT_DIR/Assets/Tools"

cd "$ROOT_DIR"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build
BIN_PATH="$(swift build --show-bin-path)"
BUILD_BINARY="$BIN_PATH/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

if [[ -f "$APP_ICON" ]]; then
  cp "$APP_ICON" "$APP_RESOURCES/Hennessy.icns"
fi

if [[ -d "$APP_TOOLS" ]]; then
  mkdir -p "$APP_RESOURCES/Tools"
  ditto "$APP_TOOLS" "$APP_RESOURCES/Tools"
  chmod -R a+rX "$APP_RESOURCES/Tools"
  find "$APP_RESOURCES/Tools" -type f \( -name "yt-dlp" -o -name "ffmpeg" \) -exec chmod 755 {} \;
fi

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_BUILD</string>
  <key>CFBundleIconFile</key>
  <string>Hennessy</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSDocumentsFolderUsageDescription</key>
  <string>Hennessy 需要读取或保存你选择的媒体文件。</string>
  <key>NSDownloadsFolderUsageDescription</key>
  <string>Hennessy 需要把下载完成的媒体保存到你选择的下载目录。</string>
  <key>NSDesktopFolderUsageDescription</key>
  <string>Hennessy 仅在你选择桌面作为保存目录时访问桌面文件。</string>
</dict>
</plist>
PLIST

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  --build-only|build-only)
    exit 0
    ;;
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
