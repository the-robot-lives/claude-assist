# Project Layout

Terminal utility package: scripts for exposing a local machine to remote hosts via
reverse SSH tunnels (autossh) and ngrok TCP tunnels (e.g. for NoMachine/SSH access
behind NAT). Flat layout — no `bin/` or `lib/` subfolders; scripts symlink into
`$PREFIX` (default `~/bin`) via the Makefile.

```
remote-tunnel/
├── docs/                       # Documentation
│   ├── PROJ-LAYOUT.md          #   This file
│   └── PROJ-LAYOUT.summary.md  #   Quick-reference tree (kept in sync)
├── .gitignore                  # Ignores editor swap files, .env, .envrc.local
├── Makefile                    # install/uninstall — symlinks scripts to $(PREFIX) (default ~/bin)
├── ngrok-cron.sh               # Cron guard: starts ngrok tunnel only when a flag file exists on remote
├── ngrok-nomachine.sh          # Starts ngrok TCP tunnel, pushes public address to a remote host file
└── revtunnel.sh                # Persistent reverse SSH tunnel via autossh (default: remote 2222→local 22, 2023→2022)
```

## Scripts

| Script | Purpose | Key options |
|--------|---------|-------------|
| `revtunnel.sh` | Persistent reverse tunnel via autossh | `--remote`, `--user`, `--key`, `--forward REMOTE:HOST:LOCAL` (repeatable) |
| `ngrok-nomachine.sh` | Start ngrok TCP tunnel; write public address to a file on remote | `--remote`, `--port` (default 4000), `--remote-out` |
| `ngrok-cron.sh` | Cron-safe wrapper: start ngrok only if remote flag file exists and ngrok not already running | `--remote`, `--flag`, `--port`, `--remote-out` |

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `.env` / `.envrc.local` | Optional local overrides (gitignored) |
| ngrok credentials | ngrok must be installed and authed on the host |
| SSH key | `revtunnel.sh` defaults to `~/.ssh/id_ed25519`; override with `--key` |

## Install

```bash
make install            # symlink scripts into ~/bin
make PREFIX=~/.local/bin install
make uninstall
```
