# claude-desktop-sandbox

Run multiple isolated instances of `claude-desktop` side by side, each with its
own config, session/cookies, and MCP server config — using `bwrap` (the same
sandboxing mechanism Flatpak uses) rather than separate Linux users.

Each named sandbox gets a fresh `$HOME` under `~/sandboxes/claude-desktop-<name>`,
so `~/.config/Claude`, `~/.config/claude`, etc. resolve independently per
instance. The host's Wayland/X11 display, PipeWire/PulseAudio sockets, and
D-Bus session bus are shared through so windows render, audio works, and
notifications/tray behave normally.

## Install

```bash
make install       # -> ~/.local/bin/claude-sandbox
```

Or via the repo-wide `make install-utilities` from the monorepo root.

## Usage

```bash
claude-sandbox work                       # launch/create sandbox "work"
claude-sandbox client-a                   # launch/create sandbox "client-a"
claude-sandbox work -- claude://code/new  # pass extra claude-desktop args
claude-sandbox client-b --from work       # seed a new sandbox from "work"

claude-sandbox --list                     # list existing sandboxes
claude-sandbox --remove client-a          # delete a sandbox's data (irreversible)

# Inbound claude:// routing (e.g. OAuth callbacks / deep links)
claude-sandbox --install-url-handler      # register a host claude:// handler
claude-sandbox --pin work                 # force claude:// links to "work"
claude-sandbox --unpin                    # back to last-launched (default)
claude-sandbox --uninstall-url-handler    # remove the host handler
```

Each invocation launches fully detached (`setsid`/`nohup`) and returns
immediately — the terminal is never blocked. Output goes to
`~/sandboxes/claude-desktop-<name>/tmp/claude-desktop.log` instead of stdout.

## Notes

- Runs `claude-desktop --no-sandbox` inside the bwrap container. Chromium's own
  setuid sandbox (`chrome-sandbox`) can't nest cleanly inside another
  mount/user-namespace sandbox without extra privileges; `bwrap` already
  provides the filesystem/process isolation between instances, so Chromium's
  redundant layer is disabled deliberately, not accidentally.
- OAuth/login flows that shell out to an external browser (via `xdg-open`)
  go through a generated `~/.local/bin/sandboxed-browser` wrapper (inside the
  sandbox's isolated `$HOME`), plus `xdg-open`/`x-www-browser` shims that
  intercept the call (XFCE's `xdg-open`→`exo-open` otherwise bypasses
  `$BROWSER`). The wrapper picks a browser that can actually run inside bwrap and
  launches it with the right flag per engine: Chromium-family (Vivaldi, Chromium,
  Brave, Chrome) with `--no-sandbox`; QtWebEngine (qutebrowser, falkon) with
  `QTWEBENGINE_DISABLE_SANDBOX=1`; Gecko (Firefox, LibreWolf) with nothing.
  Default preference order: `vivaldi` → `chromium`/`brave-browser`/`google-chrome`
  → `librewolf`/`firefox` → `qutebrowser`/`falkon`. **Snap and Flatpak browsers
  are skipped** — their own bubblewrap/AppArmor confinement can't nest inside
  bwrap (so a snap-only `chromium` won't work; install a native deb or use
  Vivaldi/Brave). Only browsers under `/usr` or `/opt` are visible — host
  `~/.local/bin` browsers (e.g. `zen`) are not, since `$HOME` is remapped. Set
  `CLAUDE_SANDBOX_BROWSER` (name or absolute path) to force a specific browser.
- **Seeding new sandboxes.** A brand-new sandbox is seeded with a *full clone*
  (config, MCP setup, **and login/session**) of a template sandbox — the one
  named by `--from <name>` / `$CLAUDE_SANDBOX_TEMPLATE`, else the oldest existing
  sandbox. The very first sandbox starts empty. Electron single-instance locks
  (`Singleton*`) are stripped from the clone. Because the login is copied,
  seeded sandboxes start authenticated as the *same* account as the template;
  use a fresh (empty) sandbox when you want a different account. Clone from an
  *idle* template — copying a running one can capture in-flight session state.
- **Inbound `claude://` routing.** When a Chromium-family browser is already
  running on the host, the sandbox's browser forwards the OAuth tab to that host
  browser, so the returning `claude://` callback is handled by the *host's*
  protocol handler. `claude-sandbox --install-url-handler` registers a host
  handler (`x-scheme-handler/claude`) that forwards such links into the
  **last-launched** sandbox by default, or a `--pin <name>` sandbox if set. This
  overrides the system-wide claude handler; if no sandbox is resolvable it falls
  back to the host `claude-desktop`. Remove it with `--uninstall-url-handler`
  (then reset the default with `xdg-mime default <your-claude>.desktop
  x-scheme-handler/claude`). Deep links that arrive *inside* a sandbox are routed
  to that sandbox's own `claude-desktop` by the generated `xdg-open` shim.
- Each sandbox has its own isolated `$HOME`. A seeded sandbox inherits the
  template's login; an unseeded (first/empty) sandbox completes the OAuth flow
  on its own, once.
- GPU passthrough (`/dev/dri`) is shared read-write; if you don't want a given
  sandbox to touch the GPU, drop that block from `bin/claude-sandbox`.
- Set `CLAUDE_SANDBOX_ROOT` to change where sandbox homes live (default
  `~/sandboxes`), or `CLAUDE_DESKTOP_BIN` if the binary isn't at
  `/usr/lib/claude-desktop/claude-desktop`.
