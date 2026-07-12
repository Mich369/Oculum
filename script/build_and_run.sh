#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="oculum"
BUNDLE_ID="com.mich.oculum"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/build/macos/Build/Products/Release/$APP_NAME.app"

cd "$ROOT_DIR"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

flutter config --enable-macos-desktop >/dev/null
flutter pub get
flutter build macos

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    echo "Debug mode: building a debug macOS app for lldb."
    flutter build macos --debug
    DEBUG_BUNDLE="$ROOT_DIR/build/macos/Build/Products/Debug/$APP_NAME.app"
    lldb -- "$DEBUG_BUNDLE/Contents/MacOS/$APP_NAME"
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
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
