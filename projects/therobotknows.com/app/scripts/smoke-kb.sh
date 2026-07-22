#!/usr/bin/env bash
# Post-deploy smoke: auth + universe create + entry + graph + generation
# Usage: BASE_URL=https://staging.example.com ./scripts/smoke-kb.sh
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8089}"
EMAIL="${SMOKE_EMAIL:-smoke-$(date +%s)@example.com}"
PASSWORD="${SMOKE_PASSWORD:-password12345}"

echo "== health =="
curl -sf "$BASE_URL/health" | head -c 200
echo

echo "== register =="
REG=$(curl -sf -X POST "$BASE_URL/api/v1/auth/register" \
  -H 'Content-Type: application/json' \
  -d "{\"user\":{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"user_name\":\"smoke\"}}")
TOKEN=$(echo "$REG" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))")
if [[ -z "$TOKEN" ]]; then
  echo "register failed: $REG" >&2
  exit 1
fi

auth() { curl -sf -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "$@"; }

echo "== create universe =="
UNI=$(auth -X POST "$BASE_URL/api/v1/universes" \
  -d "{\"universe\":{\"name\":\"Smoke Universe\",\"slug\":\"smoke-$(date +%s)\"}}")
UID=$(echo "$UNI" | python3 -c "import sys,json; print(json.load(sys.stdin)['universe']['id'])")

echo "== create entry =="
ENT=$(auth -X POST "$BASE_URL/api/v1/universes/$UID/entries" \
  -d '{"entry":{"type":"character","title":"Smoke Hero","body":"A test entry."}}')
EID=$(echo "$ENT" | python3 -c "import sys,json; print(json.load(sys.stdin)['entry']['id'])")

echo "== graph =="
auth "$BASE_URL/api/v1/universes/$UID/graph" | head -c 200
echo

echo "== consistency run =="
auth -X POST "$BASE_URL/api/v1/universes/$UID/consistency/run" | head -c 200
echo

echo "== generation =="
auth -X POST "$BASE_URL/api/v1/universes/$UID/generations" \
  -d "{\"generation\":{\"prompt\":\"Write a rumor\",\"entry_type\":\"event\",\"source_entry_ids\":[\"$EID\"]}}" \
  | head -c 300
echo

echo "SMOKE OK universe=$UID entry=$EID"
