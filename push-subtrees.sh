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
  "3rd-party/bottlecrm|bottlecrm|mono-repo-dev"
  "3rd-party/chartdb|noizu-forks-chartdb|mono-repo-dev"
  "3rd-party/codex|noizu-forks-codex|mono-repo-dev"
  # "3rd-party/clickhouse|noizu-forks-clickhouse|mono-repo-dev"   # TODO: no such remote + dir absent
  "3rd-party/directus|noizu-forks-directus|mono-repo-dev"
  "3rd-party/drawio|noizu-forks-drawio|mono-repo-dev"
  "3rd-party/excalidraw|noizu-forks-excalidraw|mono-repo-dev"
  "3rd-party/excalidraw-room|noizu-forks-excalidraw-room|mono-repo-dev"
  "3rd-party/kroki|noizu-forks-kroki|mono-repo-dev"
  "3rd-party/llama.cpp|llama-cpp|master"
  "3rd-party/mermaid-live-editor|noizu-forks-mermaid-live-editor|mono-repo-dev"
  "3rd-party/mydraft-server2|noizu-forks-mydraft-server2|mono-repo-dev"
  "3rd-party/n8n|noizu-forks-n8n|mono-repo-dev"
  "3rd-party/penpot|noizu-forks-penpot|mono-repo-dev"
  "3rd-party/plantuml|noizu-forks-plantuml|mono-repo-dev"
  "3rd-party/plantuml-server|noizu-forks-plantuml-server|mono-repo-dev"
  "3rd-party/terraform-provider-signoz|noizu-forks-terraform-provider-signoz|mono-repo-dev"
  "3rd-party/webstudio|noizu-forks-webstudio|mono-repo-dev"
  "3rd-party/zellij|noizu-forks-zellij|mono-repo-dev"

  # components
  "components/start-app|start-app|mono-repo-dev"
  "components/styleguide|styleguide|mono-repo-dev"

  # libs
  "libs/elixir-mcp|elixir-mcp|mono-repo-dev"
  "libs/scaffolding/core|scaffolding-core|mono-repo-dev"
  "libs/scaffolding/entities|scaffolding-entities|mono-repo-dev"

  # libs/ai (genai / LLM Elixir libs)
  "libs/ai/genai|genai|mono-repo-dev"
  "libs/ai/genai_local|genai-local|mono-repo-dev"
  "libs/ai/ex_llama|ex_llama|mono-repo-dev"
  "libs/ai/elixir-weaviate|elixir-weaviate|mono-repo-dev"

  # share
  "share/k8-lib|k8-lib|mono-repo-dev"

  # skills
  "skills|skills|mono-repo-dev"

  # projects
  "projects/aifighter.com|aifighter-dot-com|mono-repo-dev"
  "projects/bladeofeternity.com|bladeofeternity-dot-com|mono-repo-dev"
  "projects/bloggerscompete.com|bloggerscompete-dot-com|mono-repo-dev"
  "projects/bookmarkflow.com|bookmarkflow-dot-com|mono-repo-dev"
  "projects/codefre.sh|codefre-dot-sh|mono-repo-dev"
  "projects/derobot.is|derobot-dot-is|mono-repo-dev"
  "projects/game-workshop|game-workshop|mono-repo-dev"
  "projects/gamesborn.com|gamesborn-dot-com|mono-repo-dev"
  "projects/genai.dev|genai-dot-dev|mono-repo-dev"
  "projects/gotta.cc|gotta-dot-cc|mono-repo-dev"
  "projects/infra.noizu.com|infra-noizu-com|mono-repo-dev"
  "projects/intellectparadox.ai|intellectparadox-dot-ai|mono-repo-dev"
  "projects/interactive-pdf|interactive-pdf|mono-repo-dev"
  "projects/iotgo.io|iotgo-dot-io|mono-repo-dev"
  "projects/jailbreakingsite.com|jailbreakingsite-dot-com|mono-repo-dev"
  "projects/kopigajj|kopigajj|mono-repo-dev"
  "projects/mcp-host|mcp-host|mono-repo-dev"
  "projects/meat-brains.therobotlives.com|meat-brains-therobotlives-dot-com|mono-repo-dev"
  "projects/mockup-mcp|mockup-mcp|mono-repo-dev"
  "projects/noizu.com|noizu-dot-com|mono-repo-dev"
  "projects/NoizuPromptLingo|noizu-prompt-lingo|mono-repo-dev"
  "projects/noizurpg.com|noizurpg-dot-com|mono-repo-dev"
  "projects/robots-unite.com|robots-unite-dot-com|mono-repo-dev"
  "projects/rokos-coin|rokos-coin|mono-repo-dev"
  "projects/therobotbrowses|therobotbrowses|mono-repo-dev"
  "projects/therobotgguf|robo-gguf|mono-repo-dev"
  "projects/therobotknows.com|therobotknows-dot-com|mono-repo-dev"
  "projects/therobotlives.com|therobotlives-dot-com|mono-repo-dev"
  "projects/therobotmakes.com|therobotmakes-dot-com|mono-repo-dev"
  "projects/therobotpaints|therobotpaints|mono-repo-dev"
  # therobotplans.com RETIRED 2026-06-21: renamed to projects/tobornalp.com (below).
  # "projects/therobotplans.com|therobotplans-dot-com|mono-repo-dev"
  "projects/therobotremembers|therobotremembers|mono-repo-dev"
  "projects/therobotsrise.com|therobotsrise-dot-com|mono-repo-dev"
  "projects/theWaitcher|the-waitcher|mono-repo-dev"
  "projects/vibeucation.com|vibeucation-dot-com|mono-repo-dev"
  # snapshot method: this path's history contains an old symlink commit, so `git subtree
  # push` can't split it. Pushes HEAD's folder tree as a single commit instead.
  "projects/tobornalp.com|tobornalp|mono-repo-dev|snapshot"

  # utilities/agent
  "utilities/agent/claude-assist|claude-assist|mono-repo-dev"
  "utilities/agent/dangerously-safe|dangerously-safe|mono-repo-dev"
  "utilities/agent/mallm|mallm|mono-repo-dev"
  "utilities/agent/media-tool|media-tool|mono-repo-dev"
  "utilities/agent/run-claude|run-claude|mono-repo-dev"            # TODO: repo 404

  # utilities/colo
  "utilities/colo/colo-utils|colo-utils|mono-repo-dev"

  # utilities/database
  "utilities/database/database-utils|database-utils|mono-repo-dev"

  # utilities/k8
  "utilities/k8/cluster-utils|cluster-utils|mono-repo-dev"
  "utilities/k8/docker-utils|docker-utils|mono-repo-dev"
  "utilities/k8/helm-utils|helm-utils|mono-repo-dev"
  "utilities/k8/infra-utils|infra-utils|mono-repo-dev"
  "utilities/k8/secret-utils|secret-utils|mono-repo-dev"
  "utilities/k8/staging-utils|staging-utils|mono-repo-dev"

  # utilities/osx
  "utilities/osx/fstab|fstab|mono-repo-dev"
  "utilities/osx/queue-populator|queue-populator|mono-repo-dev"

  # utilities/shell
  "utilities/shell/auto-sudo|auto-sudo|mono-repo-dev"
  "utilities/shell/direnv-config|direnv-config|mono-repo-dev"
  "utilities/shell/github-utils|github-utils|mono-repo-dev"
  "utilities/shell/make-repo|make-repo|mono-repo-dev"
  "utilities/shell/misc-git-utils|misc-git-utils|mono-repo-dev"
  "utilities/shell/remote-tunnel|remote-tunnel|mono-repo-dev"
  "utilities/shell/secret-bucket|secret-bucket|mono-repo-dev"
  "utilities/shell/tabbing-on|tabbing-on|mono-repo-dev"            # TODO: repo 404
  "utilities/shell/zellij|zellij-util|mono-repo-dev"

  # utilities/terraform
  "utilities/terraform/terraform-utils|terraform-utils|mono-repo-dev"
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
FAILED=()

# Snapshot push: send HEAD's tree for $prefix to the remote branch as a single commit.
# Used for prefixes whose history can't be split by git subtree (e.g. an old symlink
# commit lives in the path's history).
push_snapshot() {
  local prefix="$1" remote="$2" branch="$3" tree commit tip tiptree
  if ! tree=$(git rev-parse -q --verify "HEAD:${prefix}" 2>/dev/null) \
     || [[ "$(git cat-file -t "$tree" 2>/dev/null)" != "tree" ]]; then
    echo "SKIP  $prefix (snapshot: HEAD:$prefix is not a committed tree — commit the folder first)"
    return
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY   $prefix → $remote/$branch (snapshot, tree $tree)"
    return
  fi
  # Parent the snapshot on the current remote tip so the push fast-forwards;
  # if the tip already has this exact tree, there's nothing to do.
  tip=$(git ls-remote "$remote" "refs/heads/${branch}" 2>/dev/null | awk '{print $1}')
  if [[ -n "$tip" ]]; then
    git fetch -q "$remote" "refs/heads/${branch}" 2>/dev/null || true
    tiptree=$(git cat-file -p "$tip" 2>/dev/null | awk '/^tree /{print $2; exit}')
    if [[ "$tiptree" == "$tree" ]]; then
      echo "OK    $prefix → $remote/$branch (snapshot already up to date)"
      return
    fi
  fi
  echo "PUSH  $prefix → $remote/$branch (snapshot)"
  if [[ -n "$tip" ]]; then
    commit=$(git commit-tree "$tree" -p "$tip" -m "snapshot: $prefix → $remote/$branch")
  else
    commit=$(git commit-tree "$tree" -m "snapshot: $prefix → $remote/$branch")
  fi
  if ! git push "$remote" "${commit}:refs/heads/${branch}"; then
    echo "FAIL  $prefix → $remote/$branch (snapshot)"
    FAILED+=("$prefix")
  fi
}

push_subtree() {
  local prefix="$1" remote="$2" branch="$3" method="${4:-subtree}"
  if [[ "$method" == "snapshot" ]]; then
    push_snapshot "$prefix" "$remote" "$branch"
    return
  fi
  # A symlinked prefix is a blob, not a tree — git subtree split cannot handle it
  # (fatal: "tree entry is of type blob"). Skip rather than abort the whole run.
  if [[ -L "$prefix" ]]; then
    echo "SKIP  $prefix (symlink → $(readlink "$prefix"); not a real subtree)"
    return
  fi
  if [[ ! -d "$prefix" ]]; then
    echo "SKIP  $prefix (directory not found)"
    return
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY   $prefix → $remote/$branch"
    return
  fi
  echo "PUSH  $prefix → $remote/$branch"
  # Don't let one failing subtree abort the batch (set -e is on).
  if ! git subtree push --prefix="$prefix" "$remote" "$branch"; then
    echo "FAIL  $prefix → $remote/$branch"
    FAILED+=("$prefix")
  fi
}

for e in "${CANDIDATES[@]}"; do
  IFS='|' read -r prefix remote branch method <<<"$e"
  [[ -n "$BRANCH_OVERRIDE" ]] && branch="$BRANCH_OVERRIDE"
  push_subtree "$prefix" "$remote" "$branch" "$method"
done

echo ""
_target=""
[[ -n "$BRANCH_OVERRIDE" ]] && _target=" → branch '$BRANCH_OVERRIDE'"
if [[ $DRY_RUN -eq 1 ]]; then
  echo "=== Dry run complete (${#CANDIDATES[@]} subtree(s)$_target) ==="
else
  echo "=== Subtree push complete (${#CANDIDATES[@]} subtree(s)$_target) ==="
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo ""
  echo "!!! ${#FAILED[@]} subtree(s) FAILED to push:"
  printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi
