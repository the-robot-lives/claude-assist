# PROJ-HOWTO.md

Task-oriented guides for `remote-tunnel`. See [PROJ-ARCH.md](PROJ-ARCH.md) for
*why* it's built this way and [PROJ-LAYOUT.md](PROJ-LAYOUT.md) for *where*
things live. This doc stays on *how*.

## How to: install the tunnel scripts

**Goal:** get `revtunnel.sh`, `ngrok-nomachine.sh`, `ngrok-cron.sh` on your
`PATH` as symlinks back to this repo, so edits here take effect immediately.

**Prereqs:** `~/bin` (or your chosen `PREFIX`) on `$PATH`; `autossh` and/or
`ngrok` installed for whichever strategy you use.

1. From this directory:
   ```bash
   make install
   ```
2. To install elsewhere:
   ```bash
   make install PREFIX=/usr/local/bin
   ```

**Verify:**
```bash
which revtunnel.sh ngrok-nomachine.sh ngrok-cron.sh
```
Each should resolve to a symlink pointing back into this repo checkout.

**Gotchas:**
- `make install` doesn't add `PREFIX` to `$PATH` for you — add `export
  PATH="$HOME/bin:$PATH"` to your shell rc if `~/bin` isn't already on it.
- `make uninstall` only removes the symlinks it created; it won't touch a
  same-named binary that predates it.

## How to: publish my SSH access on a remote host I control

**Goal:** make a NAT'd/firewalled local machine's SSH (and Eternal Terminal)
reachable by connecting outbound to a remote host you already have an account
on — no port-forwarding on your router needed.

**Prereqs:** `autossh` installed locally; an SSH key that can log into
`REMOTE_USER@REMOTE` (default `~/.ssh/id_ed25519`); that remote's `sshd`
allows `GatewayPorts` if you want the forwarded port reachable from *other*
hosts, not just `localhost` on the remote.

1. Run it in the foreground to confirm the forward works:
   ```bash
   revtunnel.sh --remote bastion.example.com --user keith
   ```
   This forwards remote `2222`→local `22` and remote `2023`→local `2022`
   (Eternal Terminal) by default.
2. From the remote host, connect back through the tunnel:
   ```bash
   ssh -p 2222 localme@localhost
   ```
3. For a real deployment, run it under a supervisor (systemd user unit, tmux,
   or `nohup … &`) so it survives logout — `autossh` already handles
   reconnect/backoff, you just need the process kept alive across reboots.

**Verify:** the `ssh -p 2222` command in step 2 lands you on the local
machine.

**Gotchas:**
- `--remote` is the only truly required flag; everything else has a default.
- If the tunnel exits immediately, check `ExitOnForwardFailure=yes` is firing
  because the remote port is already bound (another tunnel, or a leftover
  process) — free the port or pick a different `--forward` spec.
- `BatchMode=yes` means it will never prompt for a passphrase — use an
  unencrypted key or an `ssh-agent` with the key already loaded.

## How to: forward additional or different ports

**Goal:** expose more than the default SSH/Eternal-Terminal pair, or remap
the remote-side ports.

**Prereqs:** same as the basic reverse tunnel above.

1. Repeat `--forward` for each `REMOTE_PORT:LOCAL_HOST:LOCAL_PORT` you need,
   which replaces (not adds to) the built-in defaults:
   ```bash
   revtunnel.sh --remote bastion.example.com \
     --forward 2222:localhost:22 \
     --forward 8080:localhost:3000
   ```

**Verify:** `ssh -p 8080 <anything>` or `curl` against the remote host on the
forwarded port reaches the corresponding local service.

**Gotchas:** passing any `--forward` drops the two defaults entirely — include
`2222:localhost:22` explicitly if you still want SSH access alongside your
custom forward.

## How to: expose a local service publicly on demand via ngrok

**Goal:** get a throwaway public `host:port` for a local TCP service (e.g.
NoMachine on 4000) and hand that address to a remote party by writing it to a
file on a host they can read.

**Prereqs:** `ngrok` installed and authenticated (`ngrok config add-authtoken
…`) locally; SSH access to write `--remote-out` on the remote host.

1. ```bash
   ngrok-nomachine.sh --remote bastion.example.com \
     --port 4000 --remote-out /home/shared/tunnel-addr.txt
   ```
2. The script kills any prior `ngrok tcp 4000`, starts a fresh tunnel, polls
   `127.0.0.1:4040` for up to 20s for the public URL, then writes the bare
   `host:port` (no `tcp://` prefix) to the remote file and prints it locally.

**Verify:** the printed address and the remote file's contents match; `nc -zv
<printed-host> <printed-port>` succeeds from a third machine.

**Gotchas:**
- If ngrok has more than one active tunnel, the script only picks the first
  entry from the API response — free-tier accounts are normally limited to
  one anyway.
- Remote paths with spaces are not supported (`--remote-out` is interpolated
  unquoted into the remote shell command).
- If it exits with `ngrok failed to start`, check `/tmp/ngrok.log` for auth or
  quota errors.

## How to: let a remote host request the ngrok tunnel on its own schedule

**Goal:** keep the ngrok tunnel down (saving your metered minutes) until a
remote party signals they need it, and avoid starting duplicates.

**Prereqs:** the ngrok prereqs above; a cron entry (or systemd timer) on the
local machine.

1. Add a cron line polling every minute or so:
   ```cron
   * * * * * /home/keithbrings/bin/ngrok-cron.sh --remote bastion.example.com \
     --flag /home/shared/want-tunnel --remote-out /home/shared/tunnel-addr.txt \
     >> /tmp/ngrok-cron.log 2>&1
   ```
2. From the remote side, request access by creating the flag file:
   ```bash
   ssh bastion.example.com 'touch /home/shared/want-tunnel'
   ```
3. Next cron tick, the script sees the flag over SSH, confirms no `ngrok tcp
   4000` is already running, and delegates to `ngrok-nomachine.sh`.

**Verify:** `tail /tmp/ngrok-cron.log`, or check `/home/shared/tunnel-addr.txt`
gets written within one polling interval of creating the flag file.

**Gotchas:**
- The guard only checks for a *running process*, not tunnel health — a hung
  ngrok process blocks retries until it's killed.
- Remove the flag file yourself when done; `ngrok-cron.sh` never deletes it,
  so it will keep confirming "already running" and do nothing further once a
  tunnel exists.
- `--flag`/`--remote-out` share the same unquoted-path limitation noted above.
