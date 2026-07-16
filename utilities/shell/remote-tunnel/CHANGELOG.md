# Changelog — utilities/shell/remote-tunnel

## [Unreleased]
- [Accumulating changes since the last milestone tag]

## [m2-arch-docs] — 2026-07-16 — tag: `utilities-shell-remote-tunnel/m2-arch-docs`
Milestone summary: added NPL architecture and layout documentation (with summaries) describing the tool's structure for cross-project doc tooling.

### Added
- `docs/PROJ-ARCH.md` + `docs/PROJ-ARCH.summary.md` — architecture doc and summary
- `docs/PROJ-LAYOUT.md` + `docs/PROJ-LAYOUT.summary.md` — layout doc and summary

## [m1-initial-tooling] — 2026-06-14 — tag: `utilities-shell-remote-tunnel/m1-initial-tooling`
Milestone summary: initial import of the remote-tunnel utility package — autossh reverse tunnel and ngrok-based tunnel scripts with a Makefile installer — landed as a subtree, resynced once, then finished with a `.gitignore`.

### Added
- `revtunnel.sh` — persistent reverse tunnel via autossh (default forwards: remote 2222→local 22 ssh, remote 2023→local 2022 eternal terminal)
- `ngrok-nomachine.sh` — starts an ngrok TCP tunnel and pushes the public address to a remote host
- `ngrok-cron.sh` — cron guard that starts ngrok only when a remote flag file exists and ngrok isn't already running
- `Makefile` — `install`/`uninstall` targets symlinking scripts into `PREFIX` (default `~/bin`)
- `.gitignore` — ignores OS/editor cruft and local env files (`.DS_Store`, swap files, `.env`, `.envrc.local`)
