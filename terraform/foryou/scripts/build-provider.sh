#!/usr/bin/env bash
# Build the foryou Terraform provider and drop it where tofu/terragrunt find it
# via the dev_overrides filesystem mirror in ~/.terraformrc.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PROVIDER_DIR="$REPO_ROOT/projects/foryou.therobotlives.com/terraform-provider-foryou"
PLUGIN_DIR="${HOME}/.local/share/terraform/plugins"
# filesystem_mirror unpacked layout (so `tofu init` resolves noizu/foryou
# locally without a registry query).
VERSION="0.1.0"
TARGET="$(go env GOOS)_$(go env GOARCH)"
MIRROR_DIR="$PLUGIN_DIR/registry.opentofu.org/noizu/foryou/$VERSION/$TARGET"

if [[ ! -d "$PROVIDER_DIR" ]]; then
  echo "❌  Provider source not found: $PROVIDER_DIR" >&2
  exit 1
fi

mkdir -p "$PLUGIN_DIR"
cd "$PROVIDER_DIR"

echo "==> go mod tidy"
go mod tidy

echo "==> building terraform-provider-foryou → mirror"
mkdir -p "$MIRROR_DIR"
go build -o "$MIRROR_DIR/terraform-provider-foryou" .

echo "✅  Built → $MIRROR_DIR/terraform-provider-foryou"
echo "    ~/.terraformrc uses filesystem_mirror at $PLUGIN_DIR (noizu/foryou included)."
