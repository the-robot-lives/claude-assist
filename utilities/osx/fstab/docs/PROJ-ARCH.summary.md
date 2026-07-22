# fstab-mounter — Architecture Summary

## Overview
macOS LaunchDaemon providing Linux-style `/etc/fstab` behavior for APFS and NTFS volumes. Reads `/etc/osx-fstab` at boot and ensures volumes are mounted at declared paths, including NTFS read-write via ntfs-3g + FUSE-T.

## Ecosystem Fit
Standalone macOS-host utility in the Noizu monorepo. Does not use k8-lib, `make install-utilities`, or `.infra-config.yaml` — installs via its own sudo Makefile to `/usr/local/bin` and `/Library/LaunchDaemons`.

## Components
- **fstab-remount** — Bash mount script (UUID → label → disk fallback chain; apfs / ntfs / ntfs-ro dispatch)
- **LaunchDaemon plist** — Runs script once at boot as root, logs to `/var/log/fstab-remount.log`
- **osx-fstab.stub** — Config template installed to `/etc/osx-fstab`
- **Makefile** — install / uninstall / status / logs / install-ntfs / check-ntfs targets
- **mount-ntfs-rw.sh** — legacy one-off NTFS rw helper (superseded by `ntfs` fstype)

## Config Format
One line per volume: `uuid=<UUID> label=<Label> disk=<device> <mountpoint> <fstype> <options> 0 0`. Fstypes: `apfs`, `ntfs` (rw, needs fuse-t + ntfs-3g), `ntfs-ro` (native). Options: `noauto` (skip), `owners`, ntfs `uid=/gid=/umask=` passthrough. Spaces allowed in labels/mountpoints (right-anchored parsing, `\040` escapes). Env: `OSX_FSTAB`, `NTFS_3G_BIN`.

## Resolution Strategy
Tries UUID, then label, then disk — first `diskutil info` match wins. Correct volumes are skipped; wrong-path volumes are force-unmounted and remounted; NTFS volumes stuck read-only are remounted rw. FUSE-T mounts (invisible to diskutil) detected via `mount(8)`; NTFS rw mounts verified post-mount.

## Key Decisions
- LaunchDaemon (not Agent) — needs root before user login
- 3s boot delay for external disk enumeration
- Zero third-party deps for APFS path; FUSE-T (kext-less) + ntfs-3g only for NTFS rw
- `make install` skips gracefully when non-interactive sudo unavailable
