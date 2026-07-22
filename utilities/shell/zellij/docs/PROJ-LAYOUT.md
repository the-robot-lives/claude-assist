# Project Layout

Zellij terminal-workspace utilities: launchers that open zellij sessions/tabs
with Claude Code (or Codex) queued in split panes per project directory,
plus a shared dev layout. Installed via `make install` to `~/.local/bin`
(scripts) and `~/.config/zellij/layouts` (layouts).

```
zellij/
├── bin/                        # Executable launchers → ~/.local/bin
│   ├── zj-claude               #   Session w/ claude prefilled per selected dir (fzf picker, workspace YAML, --cerebras/--zai shorthands)
│   ├── zj-codex                #   Same as zj-claude but queues codex instead
│   ├── zj-panes                #   Split the CURRENT tab into claude | nvim | shell panes
│   ├── zj-tab                  #   Add one claude dev tab to current session (or start one)
│   └── zj-spawn                #   Generic: session w/ a tab (or 4x4 pane grid) per selected subdir, arbitrary command
├── layouts/                    # Zellij KDL layouts → ~/.config/zellij/layouts
│   └── claude-dev.kdl          #   Standard dev layout: claude (left) | nvim (right) | shell (bottom)
├── docs/                       # Project documentation
│   ├── PROJ-LAYOUT.md          #   This file
│   └── PROJ-LAYOUT.summary.md  #   Tree-only companion for tools/agents
├── .gitignore                  # Ignores swap files, .env, .envrc.local
└── Makefile                    # `make install` → copies bin/* and layouts/*.kdl; compile/test are no-ops
```

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `Makefile` | Run `make install` (or repo-root `make install-utilities`) to install scripts + layouts |

## Notes

- Scripts share a common pattern: pick directories (fzf or workspace YAML), generate a layout, launch/extend a zellij session.
- `zj-claude` / `zj-codex` / `zj-panes` / `zj-tab` support `--claude-command` / `--codex-command` overrides and a `--start-app` floating preview pane.
- No external lib dependency (does not use `share/k8-lib`); requires `zellij`, `fzf`, and optionally `nvim`.
