#!/usr/bin/env bash
# pull-subtree.sh
# Pull remote subtree updates into the monorepo.
#
# Usage:
#   ./pull-subtree.sh [folder] [options]
#
#   folder                A path or directory to pull. The subtree is looked up
#                         from the folder:
#                           - exact subtree prefix           (projects/NoizuPromptLingo)
#                           - a file/subdir inside a subtree (projects/NoizuPromptLingo/frontend)
#                           - a parent dir of many subtrees  (projects, 3rd-party, utilities/k8)
#                         With no folder, ALL subtrees are candidates.
#
# Options:
#   -i, --interactive     Toggle on/off screen to pick which repos to pull
#                         (fzf: TAB toggles, ENTER confirms; plain fallback otherwise).
#       --include <glob>  Keep only subtrees whose prefix matches the glob (repeatable).
#       --exclude <glob>  Drop subtrees whose prefix matches the glob (repeatable).
#   -b, --branch <name>   Pull ALL selected subtrees from this branch instead of each
#                         subtree's configured branch.
#       --allow-dirty     Allow pulling with tracked working tree changes present.
#   -l, --list            List resolved candidates and exit (no pull).
#   -n, --dry-run         Show what would be pulled without pulling.
#   -h, --help            Show this help.
#
# Examples:
#   ./pull-subtree.sh                              # pull everything
#   ./pull-subtree.sh projects/NoizuPromptLingo    # pull one subtree (folder lookup)
#   ./pull-subtree.sh projects/NoizuPromptLingo/frontend/src   # subdir -> same subtree
#   ./pull-subtree.sh 3rd-party                     # all 3rd-party subtrees
#   ./pull-subtree.sh --include 'utilities/*' --exclude '*zellij*'
#   ./pull-subtree.sh -i                            # interactive toggle over all
#   ./pull-subtree.sh projects -i                   # interactive toggle within projects/
#   ./pull-subtree.sh --branch main                 # pull every selected subtree from main
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY_SCRIPT="${SCRIPT_DIR}/push-subtrees.sh"

FOLDER=""
INTERACTIVE=0
LIST_ONLY=0
DRY_RUN=0
ALLOW_DIRTY=0
BRANCH_OVERRIDE=""
INCLUDES=()
EXCLUDES=()

usage() { sed -n '2,43p' "$0" | sed 's/^# \{0,1\}//'; }

die() {
  echo "$*" >&2
  exit 2
}

need_value() {
  [[ $# -ge 2 ]] || die "Missing value for $1"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--interactive) INTERACTIVE=1; shift ;;
    -l|--list)        LIST_ONLY=1; shift ;;
    -n|--dry-run)     DRY_RUN=1; shift ;;
    --allow-dirty)    ALLOW_DIRTY=1; shift ;;
    --include)        need_value "$@"; INCLUDES+=("$2"); shift 2 ;;
    --exclude)        need_value "$@"; EXCLUDES+=("$2"); shift 2 ;;
    -b|--branch)      need_value "$@"; BRANCH_OVERRIDE="$2"; shift 2 ;;
    -h|--help)        usage; exit 0 ;;
    -*)               echo "Unknown option: $1" >&2; usage; exit 2 ;;
    *)
      if [[ -n "$FOLDER" ]]; then
        echo "Only one folder may be specified (got '$FOLDER' and '$1')" >&2
        exit 2
      fi
      FOLDER="$1"; shift ;;
  esac
done

if [[ -n "$FOLDER" ]]; then
  FOLDER="${FOLDER#./}"
  FOLDER="${FOLDER%/}"
fi

resolve_candidates() {
  [[ -x "$REGISTRY_SCRIPT" ]] || die "Registry script is not executable: $REGISTRY_SCRIPT"

  local args=() output line prefix remote branch
  [[ -n "$FOLDER" ]] && args+=("$FOLDER")
  for line in "${INCLUDES[@]}"; do args+=(--include "$line"); done
  for line in "${EXCLUDES[@]}"; do args+=(--exclude "$line"); done
  [[ -n "$BRANCH_OVERRIDE" ]] && args+=(--branch "$BRANCH_OVERRIDE")
  args+=(--list)

  if ! output=$("$REGISTRY_SCRIPT" "${args[@]}"); then
    echo "Failed to resolve subtree candidates through $REGISTRY_SCRIPT" >&2
    exit 1
  fi

  CANDIDATES=()
  while read -r prefix remote branch _; do
    [[ -z "${prefix:-}" || "$prefix" == "PREFIX" ]] && continue
    CANDIDATES+=("$prefix|$remote|$branch")
  done <<<"$output"

  [[ ${#CANDIDATES[@]} -gt 0 ]] || die "No subtrees matched."
}

interactive_select() {
  local -n _out="$1"; shift
  local cands=("$@") chosen=()

  if command -v fzf >/dev/null 2>&1; then
    local lines
    lines=$(
      for e in "${cands[@]}"; do
        IFS='|' read -r prefix remote branch <<<"$e"
        printf '%s\t<- %s/%s\n' "$prefix" "$remote" "$branch"
      done
    )
    local picked
    picked=$(printf '%s\n' "$lines" | fzf --multi --no-sort \
      --delimiter='\t' --with-nth=1,2 \
      --height=90% --border --cycle \
      --header=$'TAB toggle  |  CTRL-A all  |  CTRL-D none  |  ENTER pull selected  |  ESC cancel' \
      --bind 'ctrl-a:select-all' --bind 'ctrl-d:deselect-all' \
      --prompt='pull> ') || true
    [[ -z "$picked" ]] && { _out=(); return 0; }
    while IFS=$'\t' read -r prefix _; do
      for e in "${cands[@]}"; do [[ "${e%%|*}" == "$prefix" ]] && chosen+=("$e"); done
    done <<<"$picked"
  else
    echo "Select repos to pull (space-separated numbers, 'a'=all, 'q'=cancel):" >&2
    local i=1 prefix remote branch reply n
    for e in "${cands[@]}"; do
      IFS='|' read -r prefix remote branch <<<"$e"
      printf '  %2d) %-45s <- %s/%s\n' "$i" "$prefix" "$remote" "$branch" >&2
      ((i++))
    done
    read -r -p "> " reply
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

require_clean_worktree() {
  [[ $ALLOW_DIRTY -eq 1 || $DRY_RUN -eq 1 || $LIST_ONLY -eq 1 ]] && return 0

  if ! git diff --quiet --ignore-submodules -- || ! git diff --cached --quiet --ignore-submodules --; then
    echo "Working tree has uncommitted tracked changes." >&2
    echo "Commit/stash them first, or rerun with --allow-dirty if you accept merge risk." >&2
    exit 2
  fi
}

resolve_candidates

if [[ $INTERACTIVE -eq 1 ]]; then
  SELECTED=()
  interactive_select SELECTED "${CANDIDATES[@]}"
  if [[ ${#SELECTED[@]} -eq 0 ]]; then
    echo "Nothing selected - aborting." >&2
    exit 0
  fi
  CANDIDATES=("${SELECTED[@]}")
fi

if [[ $LIST_ONLY -eq 1 ]]; then
  printf '%-48s %-38s %s\n' "PREFIX" "REMOTE" "BRANCH"
  for e in "${CANDIDATES[@]}"; do
    IFS='|' read -r prefix remote branch <<<"$e"
    printf '%-48s %-38s %s\n' "$prefix" "$remote" "$branch"
  done
  exit 0
fi

require_clean_worktree

FAILED=()

pull_subtree() {
  local prefix="$1" remote="$2" branch="$3"

  if [[ -L "$prefix" ]]; then
    echo "SKIP  $prefix (symlink -> $(readlink "$prefix"); not a real subtree)"
    return
  fi
  if [[ ! -d "$prefix" ]]; then
    echo "FAIL  $prefix (directory not found)"
    FAILED+=("$prefix")
    return
  fi
  if ! git remote get-url "$remote" >/dev/null 2>&1; then
    echo "FAIL  $prefix <- $remote/$branch (remote not configured)"
    FAILED+=("$prefix")
    return
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY   $prefix <- $remote/$branch (--squash)"
    return
  fi

  echo "PULL  $prefix <- $remote/$branch"
  if ! git subtree pull --prefix="$prefix" "$remote" "$branch" --squash; then
    echo "FAIL  $prefix <- $remote/$branch"
    FAILED+=("$prefix")
  fi
}

for e in "${CANDIDATES[@]}"; do
  IFS='|' read -r prefix remote branch <<<"$e"
  pull_subtree "$prefix" "$remote" "$branch"
done

echo ""
_target=""
[[ -n "$BRANCH_OVERRIDE" ]] && _target=" <- branch '$BRANCH_OVERRIDE'"
if [[ $DRY_RUN -eq 1 ]]; then
  echo "=== Dry run complete (${#CANDIDATES[@]} subtree(s)$_target) ==="
else
  echo "=== Subtree pull complete (${#CANDIDATES[@]} subtree(s)$_target) ==="
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo ""
  echo "!!! ${#FAILED[@]} subtree(s) FAILED to pull:"
  printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi
