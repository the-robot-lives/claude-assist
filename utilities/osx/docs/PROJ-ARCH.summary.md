# utilities/osx — Architecture Summary

Grouping directory for standalone macOS-host utilities in the Noizu monorepo; not an app
itself. Only artifact at this level is a 5-line fan-out Makefile (`SUBDIRS := fstab
queue-populator`) that includes the shared `utilities/mk/subdirs.mk`, which forwards
build/compile/test/install/clean to children, probing `.PHONY` targets so absent targets
skip gracefully (`build` falls back to `compile`); children no-op on non-Darwin hosts.

## Children
- **fstab/** — root LaunchDaemon giving macOS Linux-style `/etc/fstab` for APFS/NTFS
  (NTFS rw via ntfs-3g + FUSE-T); sudo Makefile installs to `/usr/local/bin` +
  `/Library/LaunchDaemons`. See `fstab/docs/PROJ-ARCH.summary.md`.
- **queue-populator/** — Swift 6 menu bar app: wake-phrase voice memos → Apple Speech →
  LLM classification → JSONL queue, plus 4 BlackHole-derived virtual mics; install.sh →
  `/Applications` + launchd LaunchAgent. See `queue-populator/docs/PROJ-ARCH.summary.md`.

## Ecosystem Fit
Children deliberately bypass repo deploy conventions: no `share/k8-lib`, no
`~/.local/bin` / `make install-utilities`, no `.infra-config.yaml` — each installs onto
the macOS host via its own mechanism. Privilege split: fstab runs as root at boot
(LaunchDaemon), queue-populator as the login user (LaunchAgent). A PipeWire-based Linux
port of queue-populator exists elsewhere in the repo.
