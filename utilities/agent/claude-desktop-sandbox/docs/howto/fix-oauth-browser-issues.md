## How to: fix OAuth/login browser issues inside a sandbox

**Goal:** get the login popup a sandboxed `claude-desktop` opens to actually launch and complete successfully.
**Prereqs:** a launched sandbox (`claude-sandbox <name>`).

### Symptom: `sandboxed-browser: no usable browser found on PATH`

The sandbox only sees browsers installed under `/usr` or `/opt` (its `$HOME` is remapped, so host `~/.local/bin` browsers like a user-installed `zen` aren't visible), and it deliberately skips snap- and Flatpak-packaged browsers (their own bubblewrap/AppArmor confinement can't nest inside this one).

1. Install a native (deb/rpm, non-snap) Chromium-family browser, e.g.:
   ```bash
   sudo apt install chromium    # ensure this is the deb package, not the snap stub
   ```
   Vivaldi and Brave's official `.deb` packages also work well.
2. Or point at a specific binary directly:
   ```bash
   export CLAUDE_SANDBOX_BROWSER=/opt/vivaldi/vivaldi
   claude-sandbox work
   ```

**Verify:** trigger the login flow again; a browser window opens instead of the sandbox log showing the "no usable browser" error.

### Symptom: login opens the wrong browser, or one you didn't expect

Default preference order is `vivaldi` → `chromium`/`brave-browser`/`google-chrome` → `librewolf`/`firefox` → `qutebrowser`/`falkon`. To force a specific one:
```bash
export CLAUDE_SANDBOX_BROWSER=firefox   # name on PATH, or an absolute path
claude-sandbox work
```
Set this before launching — it's read once at launch time, not hot-reloaded into a running sandbox.

### Symptom: the popup opens but crashes/hangs instead of loading

This is Chromium's own setuid sandbox trying (and failing) to nest inside `bwrap`'s namespace. `claude-sandbox` already adds `--no-sandbox` (Chromium-family) or `QTWEBENGINE_DISABLE_SANDBOX=1` (QtWebEngine) automatically via the generated wrapper — if you're still seeing this, confirm the browser you're forcing via `CLAUDE_SANDBOX_BROWSER` isn't bypassing that wrapper (it must be invoked as `sandboxed-browser`, not launched directly).

**Gotchas:**
- Firefox/LibreWolf (Gecko) need no special flag and aren't affected by this class of issue at all — if you keep hitting sandbox-nesting problems, switching to one sidesteps it entirely.
- These wrapper scripts (`sandboxed-browser`, `xdg-open`, `x-www-browser`) are regenerated into `~/sandboxes/claude-desktop-<name>/home/.local/bin/` on every launch — don't hand-edit them, edit `bin/claude-sandbox`'s `write_browser_wrapper()` instead if a fix needs to be permanent.
