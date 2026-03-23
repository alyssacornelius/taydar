#!/bin/sh
set -eu

ROOT_DIR=$(git rev-parse --show-toplevel)
cd "$ROOT_DIR"

CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR)
if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

if ! printf '%s\n' "$CHANGED_FILES" | grep -Eq '\.(swift|pbxproj|xcscheme|xcworkspacedata)$'; then
  exit 0
fi

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "error: swiftlint is required for commits in this repository." >&2
  echo "Install it with: brew install swiftlint" >&2
  exit 1
fi

echo "Running SwiftLint..."
swiftlint lint --strict

echo "Running Xcode compile check..."
xcodebuild \
  -project taydar.xcodeproj \
  -scheme taydar \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  -quiet \
  build
