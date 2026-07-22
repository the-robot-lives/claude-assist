# Project Layout

Terminal utility package: launches multiple isolated `claude-desktop` instances
via `bwrap`, each with its own `$HOME` (config, session/cookies, MCP config)
under `~/sandboxes/claude-desktop-<name>`, while sharing display, audio, and
D-Bus with the host. Also handles inbound `claude://` URL routing (OAuth
callbacks / deep links) and sandbox seeding from a template.

```
claude-desktop-sandbox/
├── bin/                        # Executable scripts
│   └── claude-sandbox          #   Single self-contained bash script (~364 lines):
│                               #   sandbox create/launch (bwrap), --list/--remove,
│                               #   template seeding (--from), browser wrapper +
│                               #   xdg-open shims for OAuth, claude:// URL handler
│                               #   (--install-url-handler, --pin/--unpin, --open-url)
├── docs/                       # Documentation
│   ├── PROJ-LAYOUT.md          #   This file
│   └── PROJ-LAYOUT.summary.md  #   Tree-only companion (keep in sync)
├── Makefile                    # test (bash -n), install/uninstall → ~/.local/bin;
│                               # dispatched by ../../mk/subdirs.mk
└── README.md                   # Start here — install, usage, browser/OAuth notes
```

## Key Files Requiring Setup

| File / Var | Action |
|------------|--------|
| `bin/claude-sandbox` | Install via `make install` (→ `~/.local/bin/claude-sandbox`) or repo-wide `make install-utilities` |
| `CLAUDE_SANDBOX_ROOT` | Optional env — sandbox homes location (default `~/sandboxes`) |
| `CLAUDE_DESKTOP_BIN` | Optional env — path to claude-desktop binary (default `/usr/lib/claude-desktop/claude-desktop`) |
| `CLAUDE_SANDBOX_BROWSER` | Optional env — force a specific browser for OAuth flows |
| `CLAUDE_SANDBOX_TEMPLATE` | Optional env — default template sandbox for seeding new ones |

## Runtime Data (outside repo, gitignore-equivalent)

Not part of the package, created at runtime under `$CLAUDE_SANDBOX_ROOT`
(default `~/sandboxes`): `claude-desktop-<name>/` per-sandbox homes,
`.last-launched`, `.pinned`, and per-sandbox logs at
`claude-desktop-<name>/tmp/claude-desktop.log`.
