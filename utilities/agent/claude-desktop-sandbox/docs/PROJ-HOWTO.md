# PROJ-HOWTO — claude-desktop-sandbox

Task-oriented guides for running multiple isolated `claude-desktop` instances.
See [PROJ-ARCH.md](PROJ-ARCH.md) for *why* it's built this way, [PROJ-LAYOUT.md](PROJ-LAYOUT.md) for *where things live*.

## How to: install claude-sandbox

**Goal:** get the `claude-sandbox` command on your PATH.
**Prereqs:** `bwrap` (bubblewrap) installed; `claude-desktop` installed at `/usr/lib/claude-desktop/claude-desktop` (or set `CLAUDE_DESKTOP_BIN`).

1. From this directory:
   ```bash
   make install       # -> ~/.local/bin/claude-sandbox
   ```
   Or repo-wide: `make install-utilities` from the monorepo root.

**Verify:** `command -v claude-sandbox` resolves, and `make test` prints `✓ syntax OK`.
**Gotchas:**
- `~/.local/bin` must be on `PATH` for the installed command to resolve.
- No `bwrap` binary → every launch fails immediately; install it via your distro's package manager (e.g. `apt install bubblewrap`).

## How to: launch an isolated claude-desktop instance

**Goal:** run a named `claude-desktop` with its own config/session, separate from your normal instance and any other sandbox.
**Prereqs:** installed (above).

1. ```bash
   claude-sandbox work
   ```
   This creates `~/sandboxes/claude-desktop-work/` (if new) and launches detached — the terminal returns immediately.
2. Open a specific URL in it at launch time:
   ```bash
   claude-sandbox work -- claude://code/new
   ```

**Verify:**
```bash
claude-sandbox --list                 # "work" should appear
tail -f ~/sandboxes/claude-desktop-work/tmp/claude-desktop.log
```
A `claude-desktop` window should appear on your existing display within a few seconds.
**Gotchas:**
- First launch of a brand-new sandbox is not seeded (empty `$HOME`) unless another sandbox already exists — see [howto/seed-a-new-sandbox.md](howto/seed-a-new-sandbox.md) if you want to skip re-login.
- Nothing appears and the log is empty → `claude-desktop` binary missing; check `CLAUDE_DESKTOP_BIN` points at a real executable.
- OAuth/login popup does nothing or errors → see [howto/fix-oauth-browser-issues.md](howto/fix-oauth-browser-issues.md).

## How to: list and remove sandboxes

**Goal:** see what sandboxes exist and delete one you no longer need.
**Prereqs:** installed.

1. ```bash
   claude-sandbox --list
   ```
2. ```bash
   claude-sandbox --remove client-a
   ```

**Verify:** the removed name no longer appears in `--list`; `~/sandboxes/claude-desktop-<name>` is gone.
**Gotchas:** `--remove` is `rm -rf` on that sandbox's entire `$HOME` — irreversible, no confirmation prompt. There's no "stop" command; closing the window or `pkill -f claude-desktop-<name>` ends the process, `--remove` deletes its data.

## How to: seed a new sandbox from an existing one (clone login + config)

Skip re-authenticating every time you spin up a new sandbox by cloning one that's already logged in.
→ *See [howto/seed-a-new-sandbox.md](howto/seed-a-new-sandbox.md)*

## How to: route claude:// deep links (OAuth callbacks) to the right sandbox

Make inbound `claude://` links from your system browser land in a specific sandbox instead of your host `claude-desktop`.
→ *See [howto/route-claude-deep-links.md](howto/route-claude-deep-links.md)*

## How to: fix OAuth/login browser issues inside a sandbox

The login popup hangs, errors, or picks a browser you didn't want.
→ *See [howto/fix-oauth-browser-issues.md](howto/fix-oauth-browser-issues.md)*

## How to: change where sandbox data lives or which claude-desktop binary is used

**Goal:** relocate sandbox homes, or point at a non-default `claude-desktop` install.
**Prereqs:** none beyond installed `claude-sandbox`.

1. Set before any invocation (persist in your shell rc if you want it permanent):
   ```bash
   export CLAUDE_SANDBOX_ROOT=/path/to/sandboxes    # default: ~/sandboxes
   export CLAUDE_DESKTOP_BIN=/opt/claude/claude-desktop  # default: /usr/lib/claude-desktop/claude-desktop
   ```
2. Launch as usual: `claude-sandbox work`.

**Verify:** `ls $CLAUDE_SANDBOX_ROOT` shows `claude-desktop-work/` at the new location.
**Gotchas:** these are read at launch time only — set them in the same shell/session before calling `claude-sandbox`, they aren't persisted anywhere by the tool itself. Switching `CLAUDE_SANDBOX_ROOT` mid-use makes previously created sandboxes invisible to `--list` until you switch back.

## How to: disable GPU passthrough (`/dev/dri`) for a sandbox

**Goal:** stop a sandbox from getting read-write access to the host GPU device, trading hardware acceleration for a tighter isolation boundary.
**Prereqs:** edit access to `bin/claude-sandbox` (there's no per-sandbox flag or env var for this — it's a script-wide change).

1. Open `bin/claude-sandbox` and find the GPU/DRI block:
   ```bash
   grep -n "GPU/DRI passthrough" -A3 bin/claude-sandbox
   ```
2. Comment out or delete the bind so no sandbox launched afterward gets `/dev/dri`:
   ```bash
   # GPU/DRI passthrough for hardware acceleration
   # if [ -d /dev/dri ]; then
   #   BWRAP_ARGS+=(--dev-bind /dev/dri /dev/dri)
   # fi
   ```
3. Re-run `make install` if you're using the installed copy at `~/.local/bin/claude-sandbox` rather than invoking `bin/claude-sandbox` directly.

**Verify:** launch a sandbox and confirm `/dev/dri` isn't visible inside it:
```bash
claude-sandbox gputest
# from another shell, once it's up:
ls /proc/$(pgrep -f claude-desktop-gputest | head -1)/root/dev/dri 2>&1   # expect "No such file or directory"
```
**Gotchas:**
- This is **global, not per-sandbox** — the check has no name/flag parameter, so editing it affects every sandbox launched from that copy of the script. Rendering falls back to software (slower, but still functional) once removed.
- Re-installing (`make install` / `make install-utilities`) overwrites `~/.local/bin/claude-sandbox` with the repo's `bin/claude-sandbox` — make the edit in the repo copy, not just the installed one, or a later install will silently restore GPU passthrough.
