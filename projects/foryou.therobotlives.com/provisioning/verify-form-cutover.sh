#!/usr/bin/env bash
# verify-form-cutover.sh
#
# Structural gate for listmonk → foryou portfolio signup cutover.
# Drives the REAL form source files (not reimplemented stubs): each path below
# is the shipped waitlist/contact component; we assert endpoint, public_slug,
# and that email is nested under `values` when a values envelope is used.
#
# Usage (from monorepo root):
#   ./projects/foryou.therobotlives.com/provisioning/verify-form-cutover.sh
#
# Exit 0 only when every cutover form matches the provisioning table in README.md.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"

# path|expected_public_slug
FORMS=(
  "projects/therobotlives.com/app/frontend/src/app/waitlist-form.tsx|therobotlives-waitlist"
  "projects/codefre.sh/app/frontend/src/components/waitlist-form.tsx|codefresh-waitlist"
  "projects/codefre.sh/web/src/app/waitlist-form.tsx|codefresh-waitlist"
  "projects/gotta.cc/app/frontend/src/app/waitlist-form.tsx|gotta-cc-waitlist"
  "projects/aifighter.com/app/frontend/src/components/WaitlistForm.tsx|aifighter-waitlist"
  "projects/robots-unite.com/web/app/waitlist-form.tsx|robots-unite-waitlist"
  "projects/jailbreakingsite.com/app/frontend/src/app/waitlist-form.tsx|jailbreaking-waitlist"
  "projects/noizurpg.com/web/src/app/waitlist-form.tsx|noizurpg-waitlist"
  "projects/iotgo.io/app/frontend/src/app/waitlist-form.tsx|iotgo-waitlist"
  "projects/noizu.com/app/frontend/src/components/ContactModal.tsx|noizu-contact"
)

FORYOU_HOST="foryou.therobotlives.com"
API_PATH_RE='/api/v1/public/lists/.+/signups'
failures=0

pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s — %s\n' "$1" "$2"; failures=$((failures + 1)); }

echo "=== listmonk residual scan (form/app source under projects/) ==="
listmonk_hits="$(
  rg -n --glob '!**/node_modules/**' --glob '!**/_build/**' --glob '!**/deps/**' --glob '!**/.next/**' \
    -g '*.{ts,tsx,js,jsx,ex,exs,html}' \
    -e 'listmonk\.noizu\.com' -e '/api/public/subscription' \
    projects/ 2>/dev/null || true
)"
# Allow hits only inside foryou import/backfill/docs (not form POSTs).
# Any hit in a waitlist/contact form path is fatal; otherwise report raw hits.
if [[ -n "$listmonk_hits" ]]; then
  form_hits="$(echo "$listmonk_hits" | rg -i 'waitlist|contact|subscription' || true)"
  if [[ -n "$form_hits" ]]; then
    echo "$form_hits"
    fail "listmonk-audit" "signup/contact form paths still reference listmonk"
  else
    echo "(non-form residual hits present; not treated as cutover failure)"
    echo "$listmonk_hits" | head -20
    pass "listmonk-audit (no form POSTs)"
  fi
else
  pass "listmonk-audit (zero hits)"
fi

echo ""
echo "=== per-form foryou slug + body shape ==="

for entry in "${FORMS[@]}"; do
  path="${entry%%|*}"
  expected_slug="${entry##*|}"
  label="$path → $expected_slug"

  if [[ ! -f "$path" ]]; then
    fail "$label" "file missing"
    continue
  fi

  content="$(cat "$path")"

  if ! grep -qF "$FORYOU_HOST" <<<"$content"; then
    fail "$label" "missing host $FORYOU_HOST"
    continue
  fi

  if ! grep -Eq "$API_PATH_RE" <<<"$content"; then
    fail "$label" "missing /api/v1/public/lists/.../signups URL shape"
    continue
  fi

  if ! grep -qF "\"$expected_slug\"" <<<"$content"; then
    fail "$label" "expected public_slug string \"$expected_slug\" not found"
    continue
  fi

  # Body contract: when a values envelope is used, email must be assigned into it
  # (inline `values: { email }` OR `values.email = ...` before JSON.stringify({ values })).
  if grep -q 'values:' <<<"$content" || grep -q 'values,' <<<"$content"; then
    if grep -Eq 'values:\s*\{\s*email' <<<"$content" \
      || grep -Eq 'values\.email\s*=' <<<"$content"; then
      :
    else
      fail "$label" "values envelope present but email not nested under values"
      continue
    fi
  else
    # top-level-only email without values is allowed by the API, but cutover forms
    # are expected to use the values envelope for consistency.
    fail "$label" "no values envelope in signup body"
    continue
  fi

  if grep -qE 'listmonk\.noizu\.com|/api/public/subscription' <<<"$content"; then
    fail "$label" "still posts to listmonk"
    continue
  fi

  pass "$label"
done

echo ""
if [[ "$failures" -eq 0 ]]; then
  echo "OVERALL: ALL PASS ($(( ${#FORMS[@]} )) forms + listmonk audit)"
  exit 0
else
  echo "OVERALL: $failures FAILURE(S)"
  exit 1
fi
