# fstab-mounter — How To (Summary)

Task list only — see [PROJ-HOWTO.md](PROJ-HOWTO.md) for full steps.

- **Install fstab-remount and mount your first volume** — get a custom APFS volume mounting at a fixed path on every boot.
- **Mount an NTFS volume read-write** — get read-write access to an NTFS-formatted external drive, persisted across reboots.
- **Mount an NTFS volume read-only (no extra deps)** — browse an NTFS drive without installing FUSE-T/ntfs-3g.
- **Apply an `/etc/osx-fstab` edit without rebooting** — pick up a config change immediately.
- **Troubleshoot a volume that won't mount where expected** — diagnose why an entry in `/etc/osx-fstab` didn't take effect.
- **Recover after a volume's UUID changes (e.g. after reformatting)** — get a volume mounting again at its declared path after its UUID changed.
- **Uninstall fstab-remount** — remove the daemon and binary without touching your `/etc/osx-fstab` config.
