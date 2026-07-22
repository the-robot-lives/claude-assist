#!/usr/bin/env bash
# Provision the per-site foryou Lists that back the listmonk → foryou cutover.
# Idempotent by slug: creates the List if absent, otherwise PATCHes it. Attributes
# upsert by slug server-side. See README.md for the full manifest + prerequisites.
#
#   export FORYOU_API_KEY=...        # management / system key (required)
#   export FORYOU_PROJECT_ID=...     # UUID of the owning foryou Project (required)
#   export FORYOU_BASE_URL=https://foryou.therobotlives.com   # optional (default)
#   ./provision-lists.sh             # DRY RUN — prints intended calls only
#   ./provision-lists.sh --apply     # actually create/update
set -euo pipefail

BASE_URL="${FORYOU_BASE_URL:-https://foryou.therobotlives.com}"
MGMT="${BASE_URL%/}/api/v1/management/lists"
APPLY=0
[[ "${1:-}" == "--apply" ]] && APPLY=1

if [[ -z "${FORYOU_API_KEY:-}" || -z "${FORYOU_PROJECT_ID:-}" ]]; then
  echo "ERROR: set FORYOU_API_KEY and FORYOU_PROJECT_ID (see README.md)" >&2
  exit 1
fi
command -v jq >/dev/null || { echo "ERROR: jq required" >&2; exit 1; }

EMAIL_ATTR='[{"slug":"email","name":"Email","type":"email","required":true,"is_identity":true,"sort_order":0}]'

CONTACT_ATTR='[
  {"slug":"email","name":"Email","type":"email","required":true,"is_identity":true,"sort_order":0},
  {"slug":"name","name":"Name","type":"string","required":false,"sort_order":1},
  {"slug":"company","name":"Company","type":"string","required":false,"sort_order":2},
  {"slug":"project_type","name":"Project type","type":"select","required":false,"options":["Consulting","Product/App","AI/ML","Infrastructure","Collaboration","Other"],"sort_order":3},
  {"slug":"budget_range","name":"Budget range","type":"select","required":false,"options":["<$10k","$10–50k","$50–100k","$100k+","Not sure"],"sort_order":4},
  {"slug":"timeline","name":"Timeline","type":"select","required":false,"options":["ASAP","1–3 months","3–6 months","6+ months","Exploring"],"sort_order":5},
  {"slug":"inquiry","name":"Inquiry","type":"text","required":false,"sort_order":6}
]'

# rows: slug|name|kind|opt_in_mode|attributes-json
LISTS=(
  "therobotlives-waitlist|The Robot Lives — Waitlist|waitlist|double|$EMAIL_ATTR"
  "codefresh-waitlist|CodeFre.sh — Waitlist|waitlist|double|$EMAIL_ATTR"
  "gotta-cc-waitlist|Gotta.cc — Waitlist|waitlist|double|$EMAIL_ATTR"
  "aifighter-waitlist|AI Fighter — Waitlist|waitlist|double|$EMAIL_ATTR"
  "robots-unite-waitlist|Robots Unite — Waitlist|waitlist|double|$EMAIL_ATTR"
  "jailbreaking-waitlist|Jailbreaking Site — Waitlist|waitlist|double|$EMAIL_ATTR"
  "noizurpg-waitlist|Noizu RPG — Waitlist|waitlist|double|$EMAIL_ATTR"
  "iotgo-waitlist|IoTGo — Waitlist|waitlist|double|$EMAIL_ATTR"
  "noizu-contact|Noizu.com — Contact|contact|single|$CONTACT_ATTR"
)

# Look up an existing list id by public_slug within the project.
existing_id() {
  local slug="$1"
  curl -fsS -H "Authorization: $FORYOU_API_KEY" \
    "$MGMT?project_id=$FORYOU_PROJECT_ID" 2>/dev/null \
    | jq -r --arg s "$slug" '.lists[]? | select(.public_slug==$s) | .id' | head -n1
}

for row in "${LISTS[@]}"; do
  IFS='|' read -r slug name kind optin attrs <<<"$row"
  payload=$(jq -n \
    --arg pid "$FORYOU_PROJECT_ID" --arg slug "$slug" --arg name "$name" \
    --arg kind "$kind" --arg optin "$optin" --argjson attrs "$attrs" \
    '{list:{project_id:$pid, slug:$slug, public_slug:$slug, name:$name, kind:$kind,
            status:"active", settings:{opt_in_mode:$optin}, attributes:$attrs}}')

  id=""
  [[ $APPLY -eq 1 ]] && id=$(existing_id "$slug" || true)

  if [[ -n "$id" ]]; then
    echo ">> PATCH $slug (id=$id)"
    [[ $APPLY -eq 1 ]] && curl -fsS -X PATCH -H "Authorization: $FORYOU_API_KEY" \
      -H "Content-Type: application/json" -d "$payload" "$MGMT/$id" >/dev/null && echo "   updated"
  else
    echo ">> POST  $slug (create)"
    if [[ $APPLY -eq 1 ]]; then
      curl -fsS -X POST -H "Authorization: $FORYOU_API_KEY" \
        -H "Content-Type: application/json" -d "$payload" "$MGMT" >/dev/null && echo "   created"
    else
      echo "   [dry-run] payload: $(echo "$payload" | jq -c .)"
    fi
  fi
done

echo "Done. $([[ $APPLY -eq 0 ]] && echo '(dry run — re-run with --apply)')"
