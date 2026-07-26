#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Run terragrunt/tofu with a kubectl port-forward to the in-cluster MinIO S3
# API, bypassing Cloudflare Access on https://minio.noizu.com.
#
# Why: every stack's S3 state backend hardcodes `endpoints = { s3 = ... }`.
# Cloudflare Access answers `tofu init` with a 302 HTML login page, so the AWS
# SDK blows up parsing it:
#
#   Failed to get existing workspaces: operation error S3: ListObjectsV2,
#   https response error StatusCode: 302 ... XML syntax error ... <hr> closed by </body>
#
# Setting AWS_ENDPOINT_URL_S3 does NOT fix this — an explicit `endpoints` in the
# backend block beats the SDK env var. The endpoint itself has to change.
#
# Usage:
#   ./scripts/tg-minio.sh <dir> <terragrunt args...>
#   ./scripts/tg-minio.sh cloudflare/zones/therobotknows.com init
#   ./scripts/tg-minio.sh cloudflare/zones/therobotknows.com plan
#   ./scripts/tg-minio.sh kubernetes/infra plan
#
#   # or from inside a stack directory:
#   cd terraform/cloudflare/zones/therobotknows.com && ../../../scripts/tg-minio.sh . plan
#
# NOTE — cached backends:
#   Terraform caches the backend config in .terraform/terraform.tfstate. A stack
#   previously initialized against https://minio.noizu.com will refuse to init
#   against the port-forward until you re-run with -reconfigure:
#
#     ./scripts/tg-minio.sh <dir> init -reconfigure
#
#   The same applies in reverse when you go back to the public endpoint. This
#   script deliberately does NOT force -reconfigure for you.
#
# Environment:
#   MINIO_LOCAL_PORT   local port for the forward          (default 9000)
#   MINIO_NAMESPACE    namespace holding the MinIO service (default infra)
#   AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
#                      honored if already exported; otherwise sourced from dc
#
# Exports, for the wrapped command:
#   TG_MINIO_ENDPOINT        http://127.0.0.1:<port>  — read by the generated
#                            backends in cloudflare/zones/_trl.hcl & _noizu.hcl
#   TG_MINIO_BACKEND_CONFIG  path to an HCL override file — appended as
#                            -backend-config=<file> on `init` by terraform/root.hcl,
#                            for stacks with a checked-in backend.tf/provider.tf
#
# Credential values are never printed.
# ---------------------------------------------------------------------------

set -euo pipefail

TF_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

LOCAL_PORT="${MINIO_LOCAL_PORT:-9000}"
NAMESPACE="${MINIO_NAMESPACE:-infra}"
SERVICE="svc/minio-service"
REMOTE_PORT="9000"

PF_PID=""
OVERRIDE_DIR=""

cleanup() {
  if [[ -n "$PF_PID" ]]; then
    kill "$PF_PID" 2>/dev/null || true
    wait "$PF_PID" 2>/dev/null || true
  fi
  [[ -n "$OVERRIDE_DIR" ]] && rm -rf "$OVERRIDE_DIR"
  return 0
}
trap cleanup EXIT

# --- Arguments -------------------------------------------------------------

if [[ $# -lt 2 ]]; then
  echo "usage: $(basename "$0") <stack-dir> <terragrunt args...>" >&2
  echo "   eg: $(basename "$0") cloudflare/zones/therobotknows.com plan" >&2
  exit 64
fi

STACK_ARG="$1"
shift

if [[ -d "$STACK_ARG" ]]; then
  STACK_DIR="$(cd "$STACK_ARG" && pwd)"
elif [[ -d "$TF_ROOT/$STACK_ARG" ]]; then
  STACK_DIR="$(cd "$TF_ROOT/$STACK_ARG" && pwd)"
else
  echo "✗ No such stack directory: $STACK_ARG (also tried $TF_ROOT/$STACK_ARG)" >&2
  exit 66
fi

command -v kubectl >/dev/null 2>&1 || { echo "✗ kubectl not on PATH" >&2; exit 69; }
command -v terragrunt >/dev/null 2>&1 || { echo "✗ terragrunt not on PATH" >&2; exit 69; }

# --- Credentials (from dc unless already exported) --------------------------
# `dc get ... --reveal --raw` writes the value to stdout only; capture into a
# variable so nothing lands on the terminal or in the log.

if [[ -z "${AWS_ACCESS_KEY_ID:-}" || -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  command -v dc >/dev/null 2>&1 || { echo "✗ dc not on PATH and AWS_* not exported" >&2; exit 69; }
  echo "→ Sourcing MinIO root credentials from dc"
  AWS_ACCESS_KEY_ID="$(dc get platform minio.root_user --reveal --raw 2>/dev/null)"
  AWS_SECRET_ACCESS_KEY="$(dc get platform minio.root_password --reveal --raw 2>/dev/null)"
fi

if [[ -z "${AWS_ACCESS_KEY_ID:-}" || -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  echo "✗ MinIO credentials are empty (dc platform minio.root_user / minio.root_password)" >&2
  exit 78
fi
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY

# --- Port-forward ----------------------------------------------------------

if curl -sf -o /dev/null --max-time 2 "http://127.0.0.1:${LOCAL_PORT}/minio/health/live" 2>/dev/null; then
  echo "→ MinIO already reachable on 127.0.0.1:${LOCAL_PORT}; reusing it"
else
  echo "→ Starting port-forward ${NAMESPACE}/${SERVICE}:${REMOTE_PORT} → 127.0.0.1:${LOCAL_PORT}"
  kubectl port-forward -n "$NAMESPACE" "$SERVICE" "${LOCAL_PORT}:${REMOTE_PORT}" >/dev/null 2>&1 &
  PF_PID=$!

  ready=false
  for _ in $(seq 1 30); do
    if ! kill -0 "$PF_PID" 2>/dev/null; then
      echo "✗ Port-forward died on startup (is ${LOCAL_PORT} already bound?)" >&2
      exit 75
    fi
    if curl -sf -o /dev/null --max-time 2 "http://127.0.0.1:${LOCAL_PORT}/minio/health/live" 2>/dev/null; then
      ready=true
      break
    fi
    sleep 1
  done

  if [[ "$ready" != true ]]; then
    echo "✗ MinIO did not become healthy on 127.0.0.1:${LOCAL_PORT} within 30s" >&2
    exit 75
  fi
fi

# --- Backend override ------------------------------------------------------

export TG_MINIO_ENDPOINT="http://127.0.0.1:${LOCAL_PORT}"

OVERRIDE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/tg-minio.XXXXXX")"
TG_MINIO_BACKEND_CONFIG="${OVERRIDE_DIR}/minio-endpoint.hcl"
cat > "$TG_MINIO_BACKEND_CONFIG" <<EOF
endpoints = { s3 = "${TG_MINIO_ENDPOINT}" }
EOF
export TG_MINIO_BACKEND_CONFIG

echo "→ TG_MINIO_ENDPOINT=${TG_MINIO_ENDPOINT}"
echo "→ AWS credentials: loaded (values suppressed)"
echo "→ Stack: ${STACK_DIR}"
echo "→ Running: terragrunt $*"

cd "$STACK_DIR"
terragrunt "$@"
