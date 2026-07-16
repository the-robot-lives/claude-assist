# Project Architecture — Summary

## Overview

Self-contained bash utility package keeping a NAT'd local machine reachable
remotely via two strategies: a persistent autossh reverse SSH tunnel
(`revtunnel.sh`, default remote:2222→local:22 and remote:2023→local:2022) and
an on-demand ngrok TCP tunnel (`ngrok-nomachine.sh`) gated by a cron guard
(`ngrok-cron.sh`) that only starts it when a flag file exists on the remote.

## Core Components

- `revtunnel.sh` — persistent reverse tunnel; `autossh -M 0 -N`, SSH keepalive
  based liveness, repeatable `--forward` specs, key auth, BatchMode.
- `ngrok-nomachine.sh` — starts `ngrok tcp PORT`, polls local :4040 API for the
  public URL, pushes `host:port` to a file on the remote over ssh.
- `ngrok-cron.sh` — idempotent cron wrapper: remote flag file + `pgrep` dedupe,
  then delegates to `ngrok-nomachine.sh`.
- `Makefile` — symlink install/uninstall into `$(PREFIX)` (default `~/bin`).

## Control Flow

Reverse path: autossh with ExitOnForwardFailure and ServerAlive keepalives
restarts on failure. ngrok path: remote host is switch (flag file) and mailbox
(address file) — remote operator requests a tunnel and reads the current
ephemeral endpoint.

## Ecosystem Fit

Intentionally standalone: no `share/k8-lib`, not installed by repo-root
`make install-utilities` (own Makefile → `~/bin`), no `.infra-config.yaml`.
Deps: autossh, ngrok (authed), ssh, curl, python3.

## Key Decisions

- autossh `-M 0` with SSH keepalives over a monitor port or systemd unit.
- Flag-file activation keeps ephemeral/metered ngrok tunnels down by default.
- Address handoff via remote file instead of DNS/API.
- Symlink install for instant edits, clean uninstall.

## Known Constraints

Assumes ngrok API at 127.0.0.1:4040 and first tunnel in response (one managed
tunnel per host); unquoted remote paths (no spaces); ngrok/SSH creds are
host-level prerequisites.
