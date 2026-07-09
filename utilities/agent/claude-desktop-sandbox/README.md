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

claude-sandbox --list                     # list existing sandboxes
claude-sandbox --remove client-a          # delete a sandbox's data (irreversible)
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
  sandbox's isolated `$HOME`) that execs the host's default Chromium-based
  browser with `--no-sandbox` too, for the same reason. Set
  `CLAUDE_SANDBOX_BROWSER` to force a specific browser command if the
  auto-detected one (brave-browser/google-chrome/chromium(-browser)/firefox/
  x-www-browser, in that order) isn't the one you want.
- Each sandbox has its own isolated `$HOME`, so it also has its own login —
  expect to complete the OAuth flow once per sandbox, not just once overall.
- GPU passthrough (`/dev/dri`) is shared read-write; if you don't want a given
  sandbox to touch the GPU, drop that block from `bin/claude-sandbox`.
- Set `CLAUDE_SANDBOX_ROOT` to change where sandbox homes live (default
  `~/sandboxes`), or `CLAUDE_DESKTOP_BIN` if the binary isn't at
  `/usr/lib/claude-desktop/claude-desktop`.
