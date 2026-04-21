#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_files=(
  "$ROOT_DIR/lib/firebase_options_dev.dart"
  "$ROOT_DIR/lib/firebase_options_prod.dart"
  "$ROOT_DIR/android/app/src/dev/google-services.json"
  "$ROOT_DIR/android/app/src/prod/google-services.json"
  "$ROOT_DIR/ios/Runner/Firebase/dev/GoogleService-Info.plist"
  "$ROOT_DIR/ios/Runner/Firebase/prod/GoogleService-Info.plist"
)

missing=0
echo "Checking Firebase environment files..."

for file in "${required_files[@]}"; do
  if [[ -f "$file" ]]; then
    echo "OK   $file"
  else
    echo "MISS $file"
    missing=1
  fi
done

if [[ $missing -ne 0 ]]; then
  echo ""
  echo "Firebase env check failed: missing required file(s)."
  exit 1
fi

echo ""
echo "Firebase env check passed."
