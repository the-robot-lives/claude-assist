# fstab-mounter — How To

Task-oriented guides for the things you'll actually do with this tool. For *what it is*, see
[PROJ-ARCH.md](PROJ-ARCH.md); for *where files live*, see [PROJ-LAYOUT.md](PROJ-LAYOUT.md).

All commands below run on the target Mac, from this directory (`utilities/osx/fstab/`).

## How to: install fstab-remount and mount your first volume

**Goal:** get a custom volume (APFS) mounting at a fixed path on every boot.
**Prereqs:** sudo access on the Mac; the target volume already exists (formatted, visible in Disk Utility).

1. Install the daemon and config stub:
   ```bash
   sudo make install
   ```
2. Get the volume's UUID:
   ```bash
   diskutil info /Volumes/YourVolume | grep "Volume UUID"
   ```
3. Edit `/etc/osx-fstab` (created from `osx-fstab.stub` on first install) and add a line:
   ```
   uuid=<UUID>  label=YourVolume  disk=-  /Users/you/YourVolume  apfs  rw,auto,owners  0  0
   ```
4. Apply immediately (or just reboot):
   ```bash
   sudo launchctl kickstart system/com.keithbrings.fstab-remount
   ```

**Verify:**
```bash
make status                       # daemon loaded?
mount | grep YourVolume           # mounted at expected path?
sudo tail -20 /var/log/fstab-remount.log   # look for "OK" or "MOUNT" line
```
**Gotchas:**
- Label/mountpoint containing spaces: literal spaces or `\040` escapes both work, but use 2+ spaces between *fields* so the parser doesn't misread them — see the format comment at the top of `osx-fstab.stub`.
- `make install` needs non-interactive sudo (a sudo timestamp already cached, or passwordless sudo); otherwise it prints the manual `sudo make install` command instead of failing.
- Nothing mounted after boot: give it a few seconds — the script sleeps 3s for disk enumeration before it starts.

## How to: mount an NTFS volume read-write

**Goal:** get read-write access to an NTFS-formatted external drive, persisted across reboots.
**Prereqs:** fstab-remount installed (see above); Homebrew installed.

1. Install the NTFS rw dependencies (FUSE-T + ntfs-3g):
   ```bash
   sudo make install-ntfs
   ```
2. Confirm they're present:
   ```bash
   make check-ntfs
   ```
3. Add an `ntfs` entry to `/etc/osx-fstab`:
   ```
   uuid=<UUID>  label=BackupDrive  disk=-  /Volumes/BackupDrive  ntfs  rw,auto  0  0
   ```
4. Apply:
   ```bash
   sudo launchctl kickstart system/com.keithbrings.fstab-remount
   ```

**Verify:** `mount | grep BackupDrive` should show the ntfs-3g mount, not `read-only`.
**Gotchas:**
- This uses **FUSE-T** (kext-less), not macFUSE — no kernel extension approval dialog needed.
- Don't use `mount-ntfs-rw.sh` for new setups — it's the legacy one-off script (hardcoded to a single volume, uses Apple's experimental native NTFS write support). The `ntfs` fstype in `osx-fstab` supersedes it.
- Want per-volume `uid=`/`gid=`/`umask=`? Add them straight into the options field, e.g. `rw,auto,uid=501,gid=20,umask=022` — they pass through to ntfs-3g.

## How to: mount an NTFS volume read-only (no extra deps)

**Goal:** browse an NTFS drive without installing FUSE-T/ntfs-3g.
**Prereqs:** fstab-remount installed.

1. Add an `ntfs-ro` entry instead of `ntfs`:
   ```
   uuid=<UUID>  label=BackupDrive  disk=-  /Volumes/BackupDrive  ntfs-ro  ro,auto  0  0
   ```
2. Apply: `sudo launchctl kickstart system/com.keithbrings.fstab-remount`

**Verify:** `mount | grep BackupDrive` shows `mount_ntfs`, read-only.
**Gotchas:** this is macOS's native NTFS driver — zero Homebrew deps, but write access is not possible; switch to the `ntfs` fstype (previous guide) if you need rw.

## How to: apply an `/etc/osx-fstab` edit without rebooting

**Goal:** pick up a config change immediately.
**Prereqs:** fstab-remount installed.

1. ```bash
   sudo launchctl kickstart system/com.keithbrings.fstab-remount
   ```
2. Check what happened:
   ```bash
   make status
   sudo tail -30 /var/log/fstab-remount.log
   ```

**Verify:** log shows one of `OK` / `MOVE` / `MOUNT` / `REMOUNT` per entry, not `FAIL`.
**Gotchas:** if a volume shows `FAIL`, confirm its UUID/label/disk still resolves via `diskutil info <identifier>` — volumes recreated after a reformat get a new UUID.

## How to: troubleshoot a volume that won't mount where expected

**Goal:** diagnose why an entry in `/etc/osx-fstab` didn't take effect.
**Prereqs:** fstab-remount installed.

1. Read the log — each line is prefixed by what happened (`OK`, `MOVE`, `MOUNT`, `REMOUNT`, `VERIFY`, `NTFS`, `FAIL`, `OWN`, `WARN` — see [PROJ-ARCH.md](PROJ-ARCH.md#logging) for the full table):
   ```bash
   sudo tail -50 /var/log/fstab-remount.log
   ```
2. Manually confirm the identifier resolves, in fallback order UUID → label → disk:
   ```bash
   diskutil info <uuid-or-label-or-disk>
   ```
3. Re-run the daemon on demand rather than waiting for a reboot:
   ```bash
   sudo launchctl kickstart system/com.keithbrings.fstab-remount
   ```

**Verify:** entry's line in the log changes from `FAIL` to `OK`/`MOUNT`.
**Gotchas:**
- `FAIL` on an `ntfs` entry usually means ntfs-3g isn't installed — the log line says so explicitly (`ntfs-3g not found at ... install with: brew install ntfs-3g`).
- FUSE-T (`ntfs`) mounts don't show up in `diskutil list` — the script cross-checks `mount(8)` instead; do the same when checking manually.

## How to: recover after a volume's UUID changes (e.g. after reformatting)

**Goal:** get a volume mounting again at its declared path after its UUID changed (typically from a reformat).
**Prereqs:** fstab-remount installed; the volume visible in Disk Utility with its new UUID.

1. Confirm this is actually a UUID mismatch — the log shows `FAIL` with the old UUID, and looking it up comes back empty:
   ```bash
   sudo tail -20 /var/log/fstab-remount.log | grep FAIL
   diskutil info <old-uuid>          # empty/error confirms the UUID no longer exists
   ```
2. Get the volume's new UUID:
   ```bash
   diskutil info /Volumes/YourVolume | grep "Volume UUID"
   ```
3. Edit `/etc/osx-fstab` and replace the stale `uuid=` value on that volume's line with the new one.
4. Apply immediately rather than waiting for the next boot:
   ```bash
   sudo launchctl kickstart system/com.keithbrings.fstab-remount
   ```

**Verify:** `sudo tail -20 /var/log/fstab-remount.log` shows `OK`/`MOUNT` for the entry instead of `FAIL`.
**Gotchas:**
- If the entry's `label=` still matches the reformatted volume's name, this step isn't needed at all — the script's fallback chain (UUID → label → disk) already falls through to the label and mounts correctly. Only UUID-only entries (`label=-`) whose volume gets reformatted need manual editing.
- A reformat changes the UUID but not necessarily the label — check `diskutil info` output for both before assuming you need to edit anything.

## How to: uninstall fstab-remount

**Goal:** remove the daemon and binary without touching your `/etc/osx-fstab` config.
**Prereqs:** sudo access.

1. ```bash
   sudo make uninstall
   ```

**Verify:** `make status` reports "Not loaded".
**Gotchas:** `/etc/osx-fstab` is deliberately left in place — delete it manually if you want a clean slate before reinstalling.
