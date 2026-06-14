#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
rm -rf .cache
npx tsx src/scripts/generate-css.ts
echo "CSS regenerated."
