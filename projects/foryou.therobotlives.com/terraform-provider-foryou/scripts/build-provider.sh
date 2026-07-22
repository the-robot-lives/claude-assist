#!/usr/bin/env bash
# Build terraform-provider-foryou and install it into the local OpenTofu
# filesystem mirror so `provisioning/terraform/` can resolve `noizu/foryou`.
#
# ~/.terraformrc already declares:
#   filesystem_mirror { path = "~/.local/share/terraform/plugins"; include = ["noizu/foryou"] }
#
# The mirror layout OpenTofu expects (default registry host is
# registry.opentofu.org) is:
#   <mirror>/registry.opentofu.org/noizu/foryou/<version>/<os>_<arch>/terraform-provider-foryou
#
# Usage: scripts/build-provider.sh   (run from anywhere; paths are absolute)
set -euo pipefail

VERSION="0.1.0"
NAMESPACE="noizu"
TYPE="foryou"
REGISTRY="registry.opentofu.org"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROVIDER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Resolve go: prefer PATH, fall back to the asdf-pinned toolchain (.tool-versions).
GO_BIN="$(command -v go || true)"
if [[ -z "${GO_BIN}" ]]; then
  GO_VERSION="$(awk '/^golang /{print $2}' "${PROVIDER_DIR}/.tool-versions" 2>/dev/null || true)"
  CANDIDATE="${HOME}/.config/asdf/installs/golang/${GO_VERSION}/go/bin/go"
  if [[ -n "${GO_VERSION}" && -x "${CANDIDATE}" ]]; then
    GO_BIN="${CANDIDATE}"
  fi
fi
if [[ -z "${GO_BIN}" ]]; then
  echo "error: could not locate a 'go' binary (checked PATH and asdf)." >&2
  exit 1
fi

OS="$("${GO_BIN}" env GOOS)"
ARCH="$("${GO_BIN}" env GOARCH)"
MIRROR="${HOME}/.local/share/terraform/plugins"
DEST_DIR="${MIRROR}/${REGISTRY}/${NAMESPACE}/${TYPE}/${VERSION}/${OS}_${ARCH}"
BIN_NAME="terraform-provider-${TYPE}"

echo "Building ${BIN_NAME} v${VERSION} (${OS}/${ARCH}) with ${GO_BIN}"
mkdir -p "${DEST_DIR}"
( cd "${PROVIDER_DIR}" && "${GO_BIN}" build -ldflags "-X main.version=${VERSION}" -o "${DEST_DIR}/${BIN_NAME}" . )

echo "Installed → ${DEST_DIR}/${BIN_NAME}"
