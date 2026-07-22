#!/usr/bin/env bash
# Live / offline structural eval report for demos.
# Usage:
#   scripts/live-eval-report.sh              # structural-only on existing demo outputs
#   scripts/live-eval-report.sh --generate   # also run generate (costs API $)
#   TYPE=image scripts/live-eval-report.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT_DIR="${OUT_DIR:-tmp/live-eval/reports}"
mkdir -p "$OUT_DIR"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
REPORT="$OUT_DIR/report-$STAMP.md"
TYPE_FILTER="${TYPE:-}"

BIN="${BIN:-./target/debug/generate-media-prompt}"
if [[ ! -x "$BIN" ]]; then
  if command -v cargo >/dev/null 2>&1; then
    cargo build -q
  fi
fi

GENERATE=0
for arg in "$@"; do
  case "$arg" in
    --generate) GENERATE=1 ;;
    --help|-h)
      sed -n '2,8p' "$0"
      exit 0
      ;;
  esac
done

echo "# media-tool live/structural eval report" >"$REPORT"
echo "" >>"$REPORT"
echo "Generated: $STAMP UTC" >>"$REPORT"
echo "" >>"$REPORT"
echo "| Prompt | Type | Output | Structural notes |" >>"$REPORT"
echo "|--------|------|--------|------------------|" >>"$REPORT"

shopt -s nullglob
count=0
pass=0

for prompt in demos/*/*.media.prompt; do
  dir="$(dirname "$prompt")"
  type_key="$(basename "$dir")"
  if [[ -n "$TYPE_FILTER" && "$type_key" != "$TYPE_FILTER" ]]; then
    continue
  fi

  stem="$(basename "$prompt" .media.prompt)"
  if [[ "$GENERATE" -eq 1 ]]; then
    echo ">> generate $prompt"
    "$BIN" --force --no-eval "$prompt" || true
  fi

  # Find any existing output beside prompt
  outputs=()
  for ext in png webp jpg jpeg svg mp4 webm mp3 wav html tsx ts md mmd puml; do
    f="$dir/$stem.$ext"
    if [[ -f "$f" ]]; then
      outputs+=("$f")
    fi
  done

  if [[ ${#outputs[@]} -eq 0 ]]; then
    echo "| \`$stem\` | $type_key | — | no output |" >>"$REPORT"
    count=$((count + 1))
    continue
  fi

  for out in "${outputs[@]}"; do
    note="present ($(wc -c <"$out" | tr -d ' ') bytes)"
    # Light structural probes when ffprobe exists
    if command -v ffprobe >/dev/null 2>&1; then
      case "$out" in
        *.mp3|*.wav|*.mp4|*.webm|*.mov)
          dur="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$out" 2>/dev/null || true)"
          if [[ -n "$dur" ]]; then
            note="duration=${dur}s; $note"
            pass=$((pass + 1))
          fi
          ;;
      esac
    else
      pass=$((pass + 1))
    fi
    echo "| \`$stem\` | $type_key | \`$(basename "$out")\` | $note |" >>"$REPORT"
    count=$((count + 1))
  done
done

echo "" >>"$REPORT"
echo "Rows: $count (duration probes counted in pass heuristic: $pass)" >>"$REPORT"
echo "Report: $REPORT"
cat "$REPORT"
