# How-To Guides — Summary

Companion index for [PROJ-HOWTO.md](PROJ-HOWTO.md). Task list + one-line outcomes only.

- **Install the launchers** — get `zj-*` scripts on `PATH` and `claude-dev.kdl` into zellij's layout dir via `make install`.
- **Open a dev session for one or more project directories** — `zj-claude`/`zj-codex` launch a session with one tab per picked dir: agent prefilled, nvim, shell.
- **Make a repeatable multi-repo workspace** — define dirs + launch options once in YAML, replay with `--workspace`. → [howto/workspace-yaml.md](howto/workspace-yaml.md)
- **Use a non-default AI provider (Cerebras / Z.AI)** — `--cerebras`/`--zai` shorthands, or `--claude-command` for a full override.
- **Preview a layout before it opens a real session** — `--dry-run` on `zj-claude`/`zj-codex`/`zj-tab` prints the KDL and resolved dirs without launching.
- **Add a dev tab or floating dev-server pane to a session already running** — `zj-tab` (new tab, works in or out of a session) vs `zj-panes` (splits your current tab, must be run inside one).
- **Run an arbitrary command across many project directories** — `zj-spawn` fans out any shell command per subdir, one-tab-per-dir or a packed `--pane` grid. → [howto/bulk-command-fanout.md](howto/bulk-command-fanout.md)
- **Use the static layout directly with zellij (no wrapper script)** — `zellij -n claude-dev` or `new-tab --layout claude-dev` for the same pane shape without prefill/batching.
