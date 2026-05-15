#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
APP_NAME="Timestamp Inserter"
APP_PATH="$ROOT_DIR/TimestampInserter/Build/$APP_NAME.app"
DIST_DIR="$ROOT_DIR/dist"
ZIP_PATH="$DIST_DIR/Timestamp-Inserter.zip"

"$ROOT_DIR/build.sh"

mkdir -p "$DIST_DIR"
rm -f "$ZIP_PATH"

ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "$ZIP_PATH"
