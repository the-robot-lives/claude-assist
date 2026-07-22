## How to: make a repeatable multi-repo workspace

**Goal:** define a fixed set of directories and launch options once in a YAML file, then reopen the same multi-repo session with one command instead of re-picking in `fzf` every time.
**Prereqs:** `yq` on `PATH` (required only for `--workspace`); `zj-claude` or `zj-codex` installed.

1. Write a workspace file:
   ```yaml
   # projects.yaml
   directories:
     - ~/Github/project-a
     - ~/Github/project-b
     - /absolute/path/to/project-c

   # Optional session name (overridden by --session)
   session: my-workspace

   # Optional agent args (overridden by --claude-args / --codex-args)
   claude_args: "--resume"

   # Optional overrides (all overridden by matching CLI flags)
   claude_command: "run-claude with cerebras-pro"
   claude_message: "/init"
   start_app: "npm run dev"
   command: "make watch"
   ```
2. Launch from it, skipping the picker entirely:
   ```bash
   zj-claude --workspace projects.yaml
   ```
3. `zj-codex` reads the same directory/`session`/`start_app`/`command` keys, with `codex_args`/`codex_command`/`codex_message` in place of the `claude_*` keys.

**Verify:** run with `--dry-run` first —
```bash
zj-claude --workspace projects.yaml --dry-run
```
— and check the printed `Session:` and `Directories:` list matches the YAML before actually launching.

**Gotchas:**
- CLI flags always win over YAML keys, which win over built-in defaults (e.g. `zj-claude -w projects.yaml --session other` uses `other`, not `my-workspace`). This lets you keep one workspace file and override just the session name per run.
- A directory listed in `directories:` that doesn't exist is skipped with a `Warning: directory does not exist, skipping: <path>` on stderr — the run continues with whatever resolved, it does not abort.
- Without `yq` installed, `--workspace` fails fast with `Error: yq not found in PATH (required for --workspace)` — the interactive `fzf` path doesn't need `yq` at all.
- `~` in a workspace-file path is expanded manually by the script (not by the shell, since it's inside a YAML string) — write `~/Github/x`, not `$HOME/Github/x`.
