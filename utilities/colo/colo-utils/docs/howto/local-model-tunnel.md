# How to: keep an SSH tunnel open to the colo local-model port

**Goal:** a persistent, auto-restarting reverse SSH tunnel from `noizu.server:3713` to your Mac's local model server, managed as a macOS system LaunchDaemon (survives reboots and reconnects on drop).
**Prereqs:** macOS (LaunchDaemons are macOS-only); sudo access; an SSH identity + `known_hosts` entry that already trusts the colo server non-interactively (`StrictHostKeyChecking=yes`, `BatchMode=yes` — no interactive prompts allowed).

## Enable the tunnel

```bash
colo-local-model-link on      # installs + starts the LaunchDaemon
```
or via Makefile:
```bash
make local-model-link-on
```

This installs `/Library/LaunchDaemons/com.keithbrings.colo-local-model-link.plist`, running:
```
ssh -NT -R 3713:localhost:3713 <ssh-user>@<ssh-hostname> ...
```
so a service on `noizu.server:3713` reaches back to `localhost:3713` on your Mac.

## Check status / logs

```bash
colo-local-model-link status   # launchctl print output
colo-local-model-link logs     # tail -100 of the log file
```

## Disable

```bash
colo-local-model-link off
```

**Verify:** `colo-local-model-link status` shows the job loaded and running; on `noizu.server`, `nc -zv localhost 3713` succeeds.

**Gotchas:**
- Fails immediately with "local home not found" or "SSH identity not found" → the tool hardcodes `LOCAL_MODEL_LINK_LOCAL_USER` (default `keithbrings`) to locate `~/.ssh`; override `LOCAL_MODEL_LINK_LOCAL_USER`/`LOCAL_MODEL_LINK_LOCAL_HOME` if your account differs.
- Runs `require_macos` first — this will refuse to run on Linux/other by design; there is no Linux equivalent shipped here.
- Not connecting: check `SSH_KNOWN_HOSTS` actually has an entry for `LOCAL_MODEL_LINK_SSH_HOSTNAME` (an IP, not the `SSH_HOST` alias) — `StrictHostKeyChecking=yes` will silently fail the tunnel otherwise; inspect via `colo-local-model-link logs`.
- All connection parameters (host, hostname/IP, port, user, remote/local port) are overridable via `LOCAL_MODEL_LINK_*` env vars — see `colo-local-model-link --help` for the full list and current defaults.
