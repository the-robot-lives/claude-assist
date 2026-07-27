#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# validate-hcl.sh — real terragrunt HCL validation for the cloudflare tree
# ---------------------------------------------------------------------------
# Discovers every unit by locating terragrunt.hcl under terraform/cloudflare
# (excluding .terragrunt-cache and origin-certs*), then runs:
#
#   terragrunt hcl validate
#
# against each unit directory. Static only — no init/plan, no MinIO, no
# Cloudflare API.
#
# Usage (from anywhere):
#   ./terraform/cloudflare/scripts/validate-hcl.sh
#   ./terraform/cloudflare/scripts/validate-hcl.sh /path/to/terraform/cloudflare
#
# Exit: 0 if every discovered unit passes; non-zero otherwise.
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_TREE="$(cd "${SCRIPT_DIR}/.." && pwd)"
TREE="${1:-$DEFAULT_TREE}"

if [[ ! -d "$TREE" ]]; then
  echo "ERROR: cloudflare tree not found: $TREE" >&2
  exit 2
fi

if ! command -v terragrunt >/dev/null 2>&1; then
  echo "ERROR: terragrunt not found on PATH" >&2
  exit 2
fi

# Discover unit dirs from terragrunt.hcl (not a hard-coded allow-list).
# Skip caches and origin-certs* (plain tofu stacks, no terragrunt unit).
UNIT_LIST="$(
  find "$TREE" -type f -name 'terragrunt.hcl' \
    ! -path '*/.terragrunt-cache/*' \
    ! -path '*/.terraform/*' \
    ! -path '*/origin-certs/*' \
    ! -path '*/origin-certs-*/*' \
    | LC_ALL=C sort
)"

if [[ -z "$UNIT_LIST" ]]; then
  echo "ERROR: no terragrunt.hcl units found under $TREE" >&2
  exit 2
fi

unit_count=0
pass_count=0
fail_count=0
failed_units=""

echo "=== cloudflare terragrunt HCL validate ==="
echo "tree:   $TREE"
echo "binary: $(command -v terragrunt) ($(terragrunt --version 2>/dev/null | head -1))"
# Count first for the header
while IFS= read -r _f; do
  [[ -n "$_f" ]] || continue
  unit_count=$((unit_count + 1))
done <<<"$UNIT_LIST"
echo "units:  ${unit_count} (discovered via terragrunt.hcl)"
echo

while IFS= read -r unit_file; do
  [[ -n "$unit_file" ]] || continue
  unit="$(dirname "$unit_file")"
  rel="${unit#"$TREE"/}"
  [[ "$rel" == "$unit" ]] && rel="$unit"

  # Capture output so the summary stays readable; re-print on failure.
  # --log-level error keeps success quiet; still real hcl validate (no init/plan).
  set +e
  out="$(
    terragrunt hcl validate \
      --non-interactive \
      --no-color \
      --no-tips \
      --log-level error \
      --working-dir "$unit" 2>&1
  )"
  rc=$?
  set -e

  if [[ $rc -eq 0 ]]; then
    echo "PASS  $rel"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL  $rel"
    fail_count=$((fail_count + 1))
    if [[ -z "$failed_units" ]]; then
      failed_units="$rel"
    else
      failed_units="${failed_units}
${rel}"
    fi
    if [[ -n "$out" ]]; then
      while IFS= read -r line; do
        printf '      %s\n' "$line"
      done <<<"$out"
    fi
  fi
done <<<"$UNIT_LIST"

echo
echo "=== summary ==="
echo "validated: ${unit_count}"
echo "passed:    ${pass_count}"
echo "failed:    ${fail_count}"

if [[ $fail_count -gt 0 ]]; then
  echo
  echo "FAILED units:"
  while IFS= read -r u; do
    [[ -n "$u" ]] || continue
    echo "  - $u"
  done <<<"$failed_units"
  echo
  echo "RESULT: FAIL"
  exit 1
fi

echo
echo "RESULT: PASS"
exit 0
