#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
APP_NAME="Timestamp Inserter"
EXECUTABLE_NAME="TimestampInserter"
BUILD_DIR="$ROOT_DIR/.build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
VISIBLE_BUILD_DIR="$ROOT_DIR/Build"
VISIBLE_APP_DIR="$VISIBLE_BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
MODULE_CACHE_DIR="$BUILD_DIR/ModuleCache"

RESOURCES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$MACOS_DIR" "$MODULE_CACHE_DIR" "$VISIBLE_BUILD_DIR" "$RESOURCES_DIR"

swiftc \
  "$ROOT_DIR/Sources/TimestampInserter/main.swift" \
  -o "$MACOS_DIR/$EXECUTABLE_NAME" \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -framework AppKit \
  -framework Carbon \
  -framework ApplicationServices

cp "$ROOT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
chmod +x "$MACOS_DIR/$EXECUTABLE_NAME"

codesign --force --deep --sign - "$APP_DIR" >/dev/null
ditto "$APP_DIR" "$VISIBLE_APP_DIR"

echo "$VISIBLE_APP_DIR"
