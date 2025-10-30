#!/usr/bin/env bash
set -euo pipefail

BASE_HREF="${1:-/captcha/coinflipper/output/}"

echo "== Flutter Web Build (Bash) =="
command -v flutter >/dev/null 2>&1 || { echo >&2 "flutter not found in PATH"; exit 1; }

echo "Building with base href: $BASE_HREF"
flutter build web --release --base-href "$BASE_HREF" --no-web-resources-cdn --no-wasm-dry-run

echo "Ensuring output directory exists"
mkdir -p output

echo "Syncing build/web to output"
# Use rsync if available for better performance, fallback to cp -r
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete build/web/ output/
else
  # Delete removed files (simple approach)
  find output -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  cp -r build/web/. output/
fi

echo "Done. Output in ./output"
