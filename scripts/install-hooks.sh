#!/bin/sh
set -eu

ROOT_DIR=$(git rev-parse --show-toplevel)
cd "$ROOT_DIR"

git config core.hooksPath .githooks
chmod +x .githooks/pre-commit scripts/pre-commit.sh scripts/install-hooks.sh

echo "Configured git hooks path to .githooks"
echo "Pre-commit hook is now active for this clone."
