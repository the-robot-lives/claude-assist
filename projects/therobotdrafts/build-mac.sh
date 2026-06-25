#!/usr/bin/env bash
# Build the macOS standalone (.app) for The Robot Draft, headless.
# Auto-selects an installed Unity editor that has Mac Build Support, preferring the
# version pinned in ProjectSettings/ProjectVersion.txt.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB="/Applications/Unity/Hub/Editor"
PIN="$(awk -F': *' '/^m_EditorVersion:/{print $2}' "$PROJECT_DIR/ProjectSettings/ProjectVersion.txt")"

has_mac() { [ -d "$HUB/$1/Unity.app/Contents/PlaybackEngines/MacStandaloneSupport" ]; }

CHOSEN=""
if [ -n "${PIN:-}" ] && [ -d "$HUB/$PIN" ] && has_mac "$PIN"; then
  CHOSEN="$PIN"
else
  for v in $(ls "$HUB" 2>/dev/null | sort -rV); do
    if has_mac "$v"; then CHOSEN="$v"; break; fi
  done
fi

if [ -z "$CHOSEN" ]; then
  echo "ERROR: no installed Unity editor has Mac Build Support (MacStandaloneSupport)." >&2
  echo "  Fix: Unity Hub -> Installs -> (your editor) -> ... -> Add modules -> Mac Build Support." >&2
  echo "  Installed editors: $(ls "$HUB" 2>/dev/null | tr '\n' ' ')" >&2
  exit 1
fi

if [ "$CHOSEN" != "$PIN" ]; then
  echo "WARNING: pinned editor '$PIN' lacks Mac Build Support; building with '$CHOSEN' instead." >&2
  echo "         Opening in a different version may convert the project (ProjectVersion.txt)." >&2
fi

ED="$HUB/$CHOSEN/Unity.app/Contents/MacOS/Unity"
LOG="$PROJECT_DIR/Builds/build-macos.log"
mkdir -p "$PROJECT_DIR/Builds"
echo "Building macOS app with Unity $CHOSEN ... (log: $LOG)"
"$ED" -batchmode -nographics -quit \
  -projectPath "$PROJECT_DIR" \
  -executeMethod TheRobotDraft.EditorTools.BuildMac.Build \
  -logFile "$LOG"
echo "Done -> $PROJECT_DIR/Builds/macOS/$( printf '%s' 'The Robot Draft.app' )"
