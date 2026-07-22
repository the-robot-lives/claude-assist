# Project Architecture — Summary

## Overview
Terminal utility running multiple isolated `claude-desktop` instances via bwrap; each named sandbox has its own `$HOME` (config, session, MCP config) under `~/sandboxes/claude-desktop-<name>`, sharing host display, audio, and D-Bus. Single self-contained bash script; no deps beyond bwrap + coreutils.

## Core Components
- `bin/claude-sandbox` — CLI dispatch, sandbox creation/seeding, bwrap launch, `claude://` URL routing
- bwrap launch block — ro host root, fresh writable HOME, isolated XDG_RUNTIME_DIR with display/audio/dbus sockets bound through, GPU passthrough
- `write_browser_wrapper()` — generates `sandboxed-browser` + `xdg-open`/`x-www-browser` shims into the sandbox's `~/.local/bin`
- Template seeding — new sandbox = full clone (incl. login) of template/oldest; strips Electron Singleton locks
- `claude://` router — host `x-scheme-handler/claude` desktop entry routes to pinned else last-launched sandbox, else host binary
- `Makefile` — `test` (bash -n), `install` → `~/.local/bin`; dispatched by repo `mk/subdirs.mk`

## Key Decisions
- bwrap over separate users/containers: light isolation while sharing live desktop sockets
- `--no-sandbox` deliberate: Chromium's setuid sandbox can't nest in bwrap; browser shims apply per-engine flags; snap/Flatpak browsers skipped
- xdg-open shims over `$BROWSER`: XFCE's exo-open bypasses `$BROWSER`; PATH-first shims intercept reliably
- Full-clone seeding includes login; empty sandbox for a different account
- Detached launch (setsid/nohup), per-sandbox logfile

## Ecosystem Fit
Under `utilities/agent/`; installs via `make install` or repo-wide `make install-utilities`. Does not use `share/k8-lib` or `.infra-config.yaml` — desktop-host tooling configured by env vars (CLAUDE_SANDBOX_ROOT, CLAUDE_DESKTOP_BIN, CLAUDE_SANDBOX_BROWSER, CLAUDE_SANDBOX_TEMPLATE).

## Runtime State
All mutable state under `$CLAUDE_SANDBOX_ROOT`: per-sandbox homes, `.last-launched`/`.pinned` routing markers, logs; plus host desktop entry `claude-sandbox-url.desktop` when the URL handler is installed.
