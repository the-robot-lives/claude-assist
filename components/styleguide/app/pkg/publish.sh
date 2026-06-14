#!/usr/bin/env bash
# Publish (or pack) @noizu/styleguide to Verdaccio (https://npm.noizu.com).
# Copies engine source into pkg/ for npm, rewrites @styleguide-engine/ to relative paths.
#
# Usage:
#   ./publish.sh           # build + npm publish
#   ./publish.sh pack      # build + npm pack (local tarball, no publish) — used for pre-publish testing
set -euo pipefail

cd "$(dirname "$0")"
ENGINE_SRC="../src"
ACTION="${1:-publish}"

# Every barrel that references engine source via ../../src/ must be rewritten to
# ../dist/engine-src/ at publish time, then restored. Keep this list in sync with src/*.ts.
BARREL_FILES=(
  src/components.ts src/viewer.ts src/css-gen.ts src/types.ts src/index.ts
  src/demos.ts src/layout.ts src/providers.ts src/primitives.ts
  src/showcases.ts src/sections.ts src/viewers.ts
)

restore_barrels() {
  sed -i '' 's|../dist/engine-src/|../../src/|g' "${BARREL_FILES[@]}" 2>/dev/null || true
}

echo "=== Preparing package ==="

# Clean previous build
rm -rf dist/engine-src

# Copy engine source into package-local directory
mkdir -p dist/engine-src
cp -r "$ENGINE_SRC/components" dist/engine-src/components
cp -r "$ENGINE_SRC/lib" dist/engine-src/lib
cp -r "$ENGINE_SRC/config" dist/engine-src/config

echo "Copied engine source to dist/engine-src/"

# Rewrite @styleguide-engine/ imports to relative paths inside the copied source
# e.g. @styleguide-engine/lib/types → relative path to lib/types
find dist/engine-src -name '*.ts' -o -name '*.tsx' | while read f; do
  # Calculate the relative path from this file back to dist/engine-src/
  dir=$(dirname "$f")
  rel=$(python3 -c "import os.path; print(os.path.relpath('dist/engine-src', '$dir'))")
  sed -i '' "s|@styleguide-engine/|${rel}/|g" "$f"
done

echo "Rewrote @styleguide-engine/ to relative paths in dist/"

# Rewrite barrel exports to point at dist/engine-src/ instead of ../../src/.
# Always restore them afterwards, even if publish/pack fails midway.
trap restore_barrels EXIT
sed -i '' 's|../../src/|../dist/engine-src/|g' "${BARREL_FILES[@]}"

echo "Rewrote barrel exports"
echo ""

if [ "$ACTION" = "pack" ]; then
  echo "=== Packing (local tarball, no publish) ==="
  npm pack
  echo ""
  echo "Done. Packed @noizu/styleguide tarball (not published)."
else
  echo "=== Publishing ==="
  npm publish
  echo ""
  echo "Done. Published @noizu/styleguide to Verdaccio (https://npm.noizu.com)."
fi

# restore_barrels runs automatically via the EXIT trap.
