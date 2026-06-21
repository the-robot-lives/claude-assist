#!/usr/bin/env bash
# push-subtrees.sh
# Push local subtree changes back to their upstream remotes.
#
# Usage:
#   ./push-subtrees.sh [folder] [options]
#
#   folder                A path or directory to push. The subtree is looked up
#                         from the folder:
#                           - exact subtree prefix          (projects/NoizuPromptLingo)
#                           - a file/subdir inside a subtree (projects/NoizuPromptLingo/frontend)
#                           - a parent dir of many subtrees  (projects, 3rd-party, utilities/k8)
#                         With no folder, ALL subtrees are candidates.
#
# Options:
#   -i, --interactive     Toggle on/off screen to pick which repos to push
#                         (fzf: TAB toggles, ENTER confirms; plain fallback otherwise).
#       --include <glob>  Keep only subtrees whose prefix matches the glob (repeatable).
#       --exclude <glob>  Drop subtrees whose prefix matches the glob (repeatable).
#   -b, --branch <name>   Push ALL selected subtrees to this branch instead of each
#                         subtree's configured branch. The branch is created on the
#                         remote if it does not exist (e.g. --branch mono-repo-dev).
#   -l, --list            List resolved candidates and exit (no push).
#   -n, --dry-run         Show what would be pushed without pushing.
#   -h, --help            Show this help.
#
# Examples:
#   ./push-subtrees.sh                              # push everything
#   ./push-subtrees.sh projects/NoizuPromptLingo    # push one subtree (folder lookup)
#   ./push-subtrees.sh projects/NoizuPromptLingo/frontend/src   # subdir -> same subtree
#   ./push-subtrees.sh 3rd-party                     # all 3rd-party subtrees
#   ./push-subtrees.sh --include 'utilities/*' --exclude '*zellij*'
#   ./push-subtrees.sh -i                            # interactive toggle over all
#   ./push-subtrees.sh projects -i                   # interactive toggle within projects/
#   ./push-subtrees.sh --branch mono-repo-dev        # push/create mono-repo-dev on every remote
set -euo pipefail

# --- Subtree registry: "prefix|remote|branch" -------------------------------
SUBTREES=(
  # 3rd-party
  "3rd-party/bottlecrm|bottlecrm|master"
  "3rd-party/chartdb|noizu-forks-chartdb|main"
  # "3rd-party/clickhouse|noizu-forks-clickhouse|master"   # TODO: no such remote + dir absent
  "3rd-party/directus|noizu-forks-directus|main"
  "3rd-party/drawio|noizu-forks-drawio|dev"
  "3rd-party/excalidraw|noizu-forks-excalidraw|master"
  "3rd-party/excalidraw-room|noizu-forks-excalidraw-room|master"
  "3rd-party/kroki|noizu-forks-kroki|main"
  "3rd-party/mermaid-live-editor|noizu-forks-mermaid-live-editor|develop"
  "3rd-party/mydraft-server2|noizu-forks-mydraft-server2|main"
  "3rd-party/n8n|noizu-forks-n8n|master"
  "3rd-party/penpot|noizu-forks-penpot|develop"
  "3rd-party/plantuml|noizu-forks-plantuml|master"
  "3rd-party/plantuml-server|noizu-forks-plantuml-server|master"
  "3rd-party/terraform-provider-signoz|noizu-forks-terraform-provider-signoz|main"
  "3rd-party/webstudio|noizu-forks-webstudio|main"
  "3rd-party/zellij|noizu-forks-zellij|main"

  # components
  "components/start-app|start-app|main"
  "components/styleguide|styleguide|main"

  # libs
  "libs/elixir-mcp|elixir-mcp|main"
  "libs/scaffolding/core|scaffolding-core|master"
  "libs/scaffolding/entities|scaffolding-entities|master"

  # share
  "share/k8-lib|k8-lib|main"

  # skills
  "skills|skills|main"

  # projects
  "projects/aifighter.com|aifighter-dot-com|main"
  "projects/bladeofeternity.com|bladeofeternity-dot-com|main"
  "projects/bloggerscompete.com|bloggerscompete-dot-com|main"
  "projects/bookmarkflow.com|bookmarkflow-dot-com|main"
  "projects/codefre.sh|codefre-dot-sh|main"
  "projects/derobot.is|derobot-dot-is|main"
  "projects/game-workshop|game-workshop|main"
  "projects/gamesborn.com|gamesborn-dot-com|main"
  "projects/genai.dev|genai-dot-dev|main"
  "projects/gotta.cc|gotta-dot-cc|main"
  "projects/infra.noizu.com|infra-noizu-com|main"
  "projects/intellectparadox.ai|intellectparadox-dot-ai|main"
  "projects/interactive-pdf|interactive-pdf|main"
  "projects/iotgo.io|iotgo-dot-io|main"
  "projects/jailbreakingsite.com|jailbreakingsite-dot-com|main"
  "projects/kopigajj|kopigajj|main"
  "projects/mcp-host|mcp-host|main"
  "projects/meat-brains.therobotlives.com|meat-brains-therobotlives-dot-com|main"
  "projects/mockup-mcp|mockup-mcp|main"
  "projects/noizu.com|noizu-dot-com|main"
  "projects/NoizuPromptLingo|noizu-prompt-lingo|main"
  "projects/noizurpg.com|noizurpg-dot-com|main"
  "projects/robots-unite.com|robots-unite-dot-com|main"
  "projects/rokos-coin|rokos-coin|main"
  "projects/therobotbrowses|therobotbrowses|main"
  "projects/therobotknows.com|therobotknows-dot-com|main"
  "projects/therobotlives.com|therobotlives-dot-com|main"
  "projects/therobotmakes.com|therobotmakes-dot-com|main"
  "projects/therobotpaints|therobotpaints|main"
  "projects/therobotplans.com|therobotplans-dot-com|main"
  "projects/therobotremembers|therobotremembers|main"
  "projects/therobotsrise.com|therobotsrise-dot-com|main"
  "projects/theWaitcher|the-waitcher|main"
  "projects/vibeucation.com|vibeucation-dot-com|main"
  "projects/tobornalp.com|tobornalp|main"

  # utilities/agent
  "utilities/agent/claude-assist|claude-assist|main"
  "utilities/agent/dangerously-safe|dangerously-safe|main"
  "utilities/agent/mallm|mallm|main"
  "utilities/agent/media-tool|media-tool|main"
  "utilities/agent/run-claude|run-claude|main"            # TODO: repo 404

  # utilities/colo
  "utilities/colo/colo-utils|colo-utils|main"

  # utilities/database
  "utilities/database/database-utils|database-utils|main"

  # utilities/k8
  "utilities/k8/cluster-utils|cluster-utils|main"
  "utilities/k8/docker-utils|docker-utils|main"
  "utilities/k8/helm-utils|helm-utils|main"
  "utilities/k8/infra-utils|infra-utils|main"
  "utilities/k8/secret-utils|secret-utils|main"
  "utilities/k8/staging-utils|staging-utils|main"

  # utilities/osx
  "utilities/osx/fstab|fstab|main"
  "utilities/osx/queue-populator|queue-populator|main"

  # utilities/shell
  "utilities/shell/auto-sudo|auto-sudo|main"
  "utilities/shell/direnv-config|direnv-config|main"
  "utilities/shell/github-utils|github-utils|main"
  "utilities/shell/make-repo|make-repo|main"
  "utilities/shell/misc-git-utils|misc-git-utils|main"
  "utilities/shell/remote-tunnel|remote-tunnel|main"
  "utilities/shell/secret-bucket|secret-bucket|main"
  "utilities/shell/tabbing-on|tabbing-on|main"            # TODO: repo 404
  "utilities/shell/zellij|zellij-util|main"

  # utilities/terraform
  "utilities/terraform/terraform-utils|terraform-utils|main"
)

# --- Arg parsing ------------------------------------------------------------
FOLDER=""
INTERACTIVE=0
LIST_ONLY=0
DRY_RUN=0
BRANCH_OVERRIDE=""
INCLUDES=()
EXCLUDES=()

usage() { sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--interactive) INTERACTIVE=1; shift ;;
    -l|--list)        LIST_ONLY=1; shift ;;
    -n|--dry-run)     DRY_RUN=1; shift ;;
    --include)        INCLUDES+=("$2"); shift 2 ;;
    --exclude)        EXCLUDES+=("$2"); shift 2 ;;
    -b|--branch)      BRANCH_OVERRIDE="$2"; shift 2 ;;
    -h|--help)        usage; exit 0 ;;
    -*)               echo "Unknown option: $1" >&2; usage; exit 2 ;;
    *)
      if [[ -n "$FOLDER" ]]; then
        echo "Only one folder may be specified (got '$FOLDER' and '$1')" >&2; exit 2
      fi
      FOLDER="$1"; shift ;;
  esac
done

# Normalize folder: strip leading ./ and trailing slash
if [[ -n "$FOLDER" ]]; then
  FOLDER="${FOLDER#./}"
  FOLDER="${FOLDER%/}"
fi

# --- Resolve candidate subtrees --------------------------------------------
# folder match: exact prefix, file/subdir inside a subtree, or parent dir of subtrees.
folder_matches() {
  local prefix="$1"
  [[ -z "$FOLDER" ]] && return 0
  [[ "$prefix" == "$FOLDER" ]] && return 0            # exact subtree
  [[ "$FOLDER" == "$prefix/"* ]] && return 0          # folder is inside subtree
  [[ "$prefix" == "$FOLDER/"* ]] && return 0          # folder is parent of subtree(s)
  return 1
}

passes_filters() {
  local prefix="$1" pat
  if [[ ${#INCLUDES[@]} -gt 0 ]]; then
    local hit=0
    for pat in "${INCLUDES[@]}"; do [[ "$prefix" == $pat ]] && hit=1 && break; done
    [[ $hit -eq 1 ]] || return 1
  fi
  if [[ ${#EXCLUDES[@]} -gt 0 ]]; then
    for pat in "${EXCLUDES[@]}"; do [[ "$prefix" == $pat ]] && return 1; done
  fi
  return 0
}

CANDIDATES=()
for entry in "${SUBTREES[@]}"; do
  prefix="${entry%%|*}"
  folder_matches "$prefix" || continue
  passes_filters "$prefix" || continue
  CANDIDATES+=("$entry")
done

if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
  echo "No subtrees matched." >&2
  [[ -n "$FOLDER" ]] && echo "  folder:  $FOLDER" >&2
  [[ ${#INCLUDES[@]} -gt 0 ]] && echo "  include: ${INCLUDES[*]}" >&2
  [[ ${#EXCLUDES[@]} -gt 0 ]] && echo "  exclude: ${EXCLUDES[*]}" >&2
  exit 1
fi

# Effective branch for an entry: --branch override wins, else the configured branch.
eff_branch() {
  if [[ -n "$BRANCH_OVERRIDE" ]]; then printf '%s' "$BRANCH_OVERRIDE"
  else cut -d'|' -f3 <<<"$1"; fi
}

# --- Interactive toggle screen ---------------------------------------------
# Presents the candidate set; user toggles which repos to push.
interactive_select() {
  local -n _out="$1"; shift
  local cands=("$@") chosen=()

  if command -v fzf >/dev/null 2>&1; then
    local lines
    lines=$(
      for e in "${cands[@]}"; do
        printf '%s\t→ %s/%s\n' "${e%%|*}" "$(cut -d'|' -f2 <<<"$e")" "$(eff_branch "$e")"
      done
    )
    local picked
    picked=$(printf '%s\n' "$lines" | fzf --multi --no-sort \
      --delimiter='\t' --with-nth=1,2 \
      --height=90% --border --cycle \
      --header=$'TAB toggle  •  CTRL-A all  •  CTRL-D none  •  ENTER push selected  •  ESC cancel' \
      --bind 'ctrl-a:select-all' --bind 'ctrl-d:deselect-all' \
      --prompt='push> ') || true
    [[ -z "$picked" ]] && { _out=(); return 0; }
    while IFS=$'\t' read -r prefix _; do
      for e in "${cands[@]}"; do [[ "${e%%|*}" == "$prefix" ]] && chosen+=("$e"); done
    done <<<"$picked"
  else
    # Plain fallback: numbered toggle.
    echo "Select repos to push (space-separated numbers, 'a'=all, 'q'=cancel):" >&2
    local i=1
    for e in "${cands[@]}"; do
      printf '  %2d) %-45s → %s/%s\n' "$i" "${e%%|*}" \
        "$(cut -d'|' -f2 <<<"$e")" "$(eff_branch "$e")" >&2
      ((i++))
    done
    local reply; read -r -p "> " reply
    case "$reply" in
      q|Q|"") _out=(); return 0 ;;
      a|A)    chosen=("${cands[@]}") ;;
      *)      for n in $reply; do
                [[ "$n" =~ ^[0-9]+$ ]] && (( n>=1 && n<=${#cands[@]} )) && chosen+=("${cands[$((n-1))]}")
              done ;;
    esac
  fi
  _out=("${chosen[@]}")
}

if [[ $INTERACTIVE -eq 1 ]]; then
  SELECTED=()
  interactive_select SELECTED "${CANDIDATES[@]}"
  if [[ ${#SELECTED[@]} -eq 0 ]]; then
    echo "Nothing selected — aborting." >&2
    exit 0
  fi
  CANDIDATES=("${SELECTED[@]}")
fi

# --- List-only --------------------------------------------------------------
if [[ $LIST_ONLY -eq 1 ]]; then
  printf '%-48s %-38s %s\n' "PREFIX" "REMOTE" "BRANCH"
  for e in "${CANDIDATES[@]}"; do
    printf '%-48s %-38s %s\n' "${e%%|*}" "$(cut -d'|' -f2 <<<"$e")" "$(eff_branch "$e")"
  done
  exit 0
fi

# --- Push -------------------------------------------------------------------
push_subtree() {
  local prefix="$1" remote="$2" branch="$3"
  if [[ ! -d "$prefix" ]]; then
    echo "SKIP  $prefix (directory not found)"
    return
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY   $prefix → $remote/$branch"
    return
  fi
  echo "PUSH  $prefix → $remote/$branch"
  git subtree push --prefix="$prefix" "$remote" "$branch"
}

for e in "${CANDIDATES[@]}"; do
  IFS='|' read -r prefix remote branch <<<"$e"
  [[ -n "$BRANCH_OVERRIDE" ]] && branch="$BRANCH_OVERRIDE"
  push_subtree "$prefix" "$remote" "$branch"
done

echo ""
_target=""
[[ -n "$BRANCH_OVERRIDE" ]] && _target=" → branch '$BRANCH_OVERRIDE'"
if [[ $DRY_RUN -eq 1 ]]; then
  echo "=== Dry run complete (${#CANDIDATES[@]} subtree(s)$_target) ==="
else
  echo "=== Subtree push complete (${#CANDIDATES[@]} subtree(s)$_target) ==="
fi
