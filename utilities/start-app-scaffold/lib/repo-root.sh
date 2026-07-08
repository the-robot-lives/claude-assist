#!/usr/bin/env bash
# repo-root.sh — Shared repo-root resolver for start-app-scaffold tools.
#
# These tools run both in-repo (utilities/start-app-scaffold/bin/*) and
# installed standalone to ~/.local/bin (via `make install`). Walking up from
# the script's own SCRIPT_DIR only finds the monorepo's .git when the script
# still lives inside it — once installed to ~/.local/bin there is no .git
# above it, and the old per-script loop silently bottomed out at "/".
#
# Resolution order:
#   1. $INFRA_ROOT, if it names a real git repo root
#   2. Walk up from the calling script's own directory (in-repo invocation)
#   3. Walk up from $PWD (installed alias, run from inside the repo)
# Never falls back to "/" — exits with a clear error instead.

_start_app_scaffold_walk_up_for_git() {
  local dir="$1"
  while [[ -n "$dir" && "$dir" != "/" ]]; do
    [[ -d "$dir/.git" ]] && { printf '%s\n' "$dir"; return 0; }
    dir="$(dirname "$dir")"
  done
  return 1
}

resolve_repo_root() {
  local caller_dir="${1:?resolve_repo_root requires the calling script directory}"
  local root

  if [[ -n "${INFRA_ROOT:-}" && -d "${INFRA_ROOT}/.git" ]]; then
    printf '%s\n' "$INFRA_ROOT"
    return 0
  fi

  if root="$(_start_app_scaffold_walk_up_for_git "$caller_dir")"; then
    printf '%s\n' "$root"
    return 0
  fi

  if root="$(_start_app_scaffold_walk_up_for_git "$PWD")"; then
    printf '%s\n' "$root"
    return 0
  fi

  echo "Error: could not resolve the noizu-infra repo root." >&2
  echo "  Not found via \$INFRA_ROOT, walking up from $caller_dir, or walking up from \$PWD ($PWD)." >&2
  echo "  Fix: run from inside the repo, or set INFRA_ROOT=/path/to/noizu-infra" >&2
  return 1
}
