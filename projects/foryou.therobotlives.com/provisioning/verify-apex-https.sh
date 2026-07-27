#!/usr/bin/env bash
# verify-apex-https.sh — live gate for cutover portfolio apex sites
# Drives real HTTPS against public hosts (TLS verify ON). Exit 0 only if all 200 + ssl_verify_result=0.
set -euo pipefail
HOSTS=(
  therobotlives.com
  codefre.sh
  aifighter.com
  jailbreakingsite.com
  iotgo.io
  robots-unite.com
  noizurpg.com
  gotta.cc
  noizu.com
)
fail=0
echo "=== apex HTTPS (TLS verify ON) ==="
for h in "${HOSTS[@]}"; do
  url="https://${h}"
  out=$(curl -sS -L --max-time 30 -o /dev/null -w '%{http_code} %{ssl_verify_result}' "$url" 2>&1) || out="000 1"
  code=${out%% *}; ssl=${out##* }
  if [[ "$code" == "200" && "$ssl" == "0" ]]; then
    echo "  PASS  $url -> $code ssl=$ssl"
  else
    echo "  FAIL  $url -> $code ssl=$ssl"
    fail=1
  fi
done
if [[ $fail -eq 0 ]]; then
  echo "OVERALL: ALL PASS"
  exit 0
else
  echo "OVERALL: FAILURES"
  exit 1
fi
