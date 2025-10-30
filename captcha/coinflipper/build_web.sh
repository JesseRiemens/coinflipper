#!/usr/bin/env bash
set -euo pipefail

BASE_HREF="${1:-/coinflipper/app/}"

echo "== Flutter Web Build (Bash) =="
command -v flutter >/dev/null 2>&1 || { echo >&2 "flutter not found in PATH"; exit 1; }

echo "Building with base href: $BASE_HREF"
flutter build web --release --base-href "$BASE_HREF" --no-web-resources-cdn --no-wasm-dry-run

TARGET_DIR="../app"
echo "Ensuring target directory exists: $TARGET_DIR"
mkdir -p "$TARGET_DIR"

echo "Syncing build/web to $TARGET_DIR"
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete build/web/ "$TARGET_DIR"/
else
  # Delete removed files in target (simple approach)
  find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  cp -r build/web/. "$TARGET_DIR"/
fi

echo "Done. Output in $TARGET_DIR"
