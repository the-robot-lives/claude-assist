#!/usr/bin/env bash
# Build the foryou Terraform provider and drop it where tofu/terragrunt find it
# via the dev_overrides filesystem mirror in ~/.terraformrc.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
PROVIDER_DIR="$REPO_ROOT/3rd-party/terraform-provider-foryou"
PLUGIN_DIR="${HOME}/.local/share/terraform/plugins"

if [[ ! -d "$PROVIDER_DIR" ]]; then
  echo "❌  Provider source not found: $PROVIDER_DIR" >&2
  exit 1
fi

mkdir -p "$PLUGIN_DIR"
cd "$PROVIDER_DIR"

echo "==> go mod tidy"
go mod tidy

echo "==> building terraform-provider-foryou → $PLUGIN_DIR"
go build -o "$PLUGIN_DIR/terraform-provider-foryou" .

echo "✅  Built. Ensure ~/.terraformrc has:"
echo "    dev_overrides { \"noizu/foryou\" = \"$PLUGIN_DIR\" }"
echo "    (then `terragrunt init` will warn about dev_overrides; plan/apply still work)"
