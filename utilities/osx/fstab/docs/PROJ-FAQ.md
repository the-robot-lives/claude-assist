# fstab-mounter — FAQ

Anticipated why/when/compared-to-what questions. For *what it is*, see [PROJ-ARCH.md](PROJ-ARCH.md);
for *how to do it*, see [PROJ-HOWTO.md](PROJ-HOWTO.md).

## Motivation

### Why would I need this instead of just using Disk Utility / Finder auto-mount?

Because macOS forgets where you want non-boot volumes mounted, and forgets it doesn't have write access to NTFS at all. Finder auto-mounts external volumes to `/Volumes/<name>`, not a path of your choosing, and that path can drift if the volume gets a new default name. macOS's native NTFS driver is also read-only, permanently, no setting flips it to rw. `fstab-remount` runs at boot as root, forces each declared volume to a fixed path, and (for NTFS) forces rw via ntfs-3g. If you're happy with default `/Volumes/*` mount points and never touch NTFS, you don't need this.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-install-fstab-remount-and-mount-your-first-volume) to install it.*

### Why is this a LaunchDaemon and not a login item or LaunchAgent?

Because it has to run as root before any user logs in. Custom mount points under `/Users/...` or ownership changes (`enableOwnership`) require root, and a LaunchAgent only starts after a user session exists — too late for volumes you want present the moment the machine is usable (e.g. before other daemons/services that read from them start). See [PROJ-ARCH.md](PROJ-ARCH.md#key-design-decisions).

### Why not just add entries to macOS's real `/etc/fstab`?

Because Apple's own `/etc/fstab` support for non-boot APFS volumes is unreliable and, for anything beyond the boot volume, effectively unsupported — entries are frequently ignored or fought by diskutil's auto-mount behavior. `/etc/osx-fstab` (this tool's own config, note the different filename) sidesteps that by actively managing mount state itself via `diskutil`/`ntfs-3g` rather than asking the kernel's mount table to behave like Linux's.

## Fit

### When is this the wrong tool for my situation?

If you only ever plug in Time Machine or vendor-formatted drives you're fine leaving alone, or if you never need a *fixed* path per volume — you don't need this. It's built for a small number of persistent, hand-declared volumes (backup drives, shared data disks, dev scratch volumes) that must land at the same path every boot. It is not a general-purpose disk manager, doesn't discover volumes automatically, and doesn't handle network mounts (SMB/NFS/AFP) — those already have their own macOS mechanisms (`/etc/auto_master`, login-item mounting).

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#place-in-the-noizu-utilities-ecosystem) for how it's scoped relative to the rest of `utilities/`.*

### Does this work on Apple Silicon / recent macOS versions?

Yes for the APFS path (pure `diskutil`, no kernel extensions, so no Apple Silicon security-policy friction). The NTFS rw path depends on FUSE-T, a third-party kext-less FUSE implementation — it works on current macOS/Apple Silicon but is a moving external dependency you're trusting, not something Apple ships or supports. If FUSE-T breaks on a future macOS release, only NTFS rw is affected; `ntfs-ro` (native) and APFS handling are unaffected.

## Comparison

### `ntfs` vs `ntfs-ro` — which fstype should I actually use?

Use `ntfs-ro` unless you specifically need to write to the volume. `ntfs-ro` uses macOS's built-in native NTFS driver: zero extra installs, zero moving parts, but permanently read-only. `ntfs` mounts rw via ntfs-3g + FUSE-T, which means installing and trusting a third-party FUSE stack — worth it only when you actually write to the drive.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-mount-an-ntfs-volume-read-write) and [the read-only guide](PROJ-HOWTO.md#how-to-mount-an-ntfs-volume-read-only-no-extra-deps).*

### `osx-fstab.stub`/`ntfs` fstype vs `mount-ntfs-rw.sh` — why are there two ways to get NTFS rw?

`mount-ntfs-rw.sh` is legacy and superseded — it predates `ntfs` fstype support in the main script, is hardcoded to a single volume, and relies on Apple's experimental native NTFS write support rather than ntfs-3g. New setups should use the `ntfs` fstype in `/etc/osx-fstab` instead; the standalone script is kept only for one-off/back-compat use, not recommended for new configs.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-mount-an-ntfs-volume-read-write), which calls this out explicitly as a gotcha.*

### How is this different from the Linux/k8s tools elsewhere in `utilities/`?

It isn't part of that ecosystem at all. It doesn't use `share/k8-lib`, isn't installed by `make install-utilities`, and has no `.infra-config.yaml` entry — it's a standalone macOS-host tool that happens to live in this monorepo for version-control convenience alongside everything else.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#place-in-the-noizu-utilities-ecosystem).*

## Capability

### Can it recover if a volume's UUID changes (e.g. after reformatting)?

Not automatically — you have to update `/etc/osx-fstab` with the new UUID yourself. The script's fallback chain (UUID → label → disk) means a reformat that keeps the same *label* will still resolve and mount correctly without an edit; only a UUID-only entry whose volume gets reformatted needs manual attention. A `FAIL` log line and a `diskutil info <identifier>` that comes back empty for the old UUID are the diagnostic signal.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-troubleshoot-a-volume-that-wont-mount-where-expected).*

### Can I apply a config change without rebooting?

Yes — `sudo launchctl kickstart system/com.keithbrings.fstab-remount` re-runs the script on demand; a reboot is never required to pick up an `/etc/osx-fstab` edit.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-apply-an-etcosx-fstab-edit-without-rebooting).*

### Can mountpoints or labels contain spaces?

Yes, since the m3 parser rewrite (2026-06-20) — the parser extracts `uuid=`/`label=`/`disk=` tagged fields via regex and the trailing fstype/options/mountpoint fields via right-anchored awk parsing, so multi-word values no longer misalign. Use 2+ spaces between *fields* (not within a value) so the parser can still tell fields apart; `\040` octal escapes are also decoded. Before m3, space-containing values silently broke field alignment.

## Caveats

### What's the security cost of the NTFS rw path?

You're trusting a third-party, non-Apple FUSE implementation (FUSE-T) and ntfs-3g running with root-mounted access to a filesystem, instead of Apple's own (read-only) driver. That's a materially larger trust surface than the APFS path, which uses only `diskutil`/`bash`/`mkdir` shipped by Apple. If you don't need write access, `ntfs-ro` avoids this entirely.

### What happens if `make install` runs where sudo isn't cached and isn't passwordless?

It doesn't fail silently and it doesn't hang waiting for a password — it degrades gracefully and prints the manual `sudo make install` command for you to run yourself. Safe to invoke from automation/CI-style contexts where an interactive password prompt would otherwise stall.

### What happens on a volume that never mounts — does the daemon retry indefinitely or give up?

It runs once at boot (`RunAtLoad`) after a fixed 3-second delay for disk enumeration, then stops — it does not poll or retry on its own afterward. If a slow-to-enumerate external drive isn't ready within that window, the entry fails that run and you need `sudo launchctl kickstart ...` to retry manually (see the apply-without-rebooting guide). There's no built-in backoff/retry loop.

## Trust

### Does this send any data anywhere, or touch anything outside the target Mac?

No. Everything is local: it reads `/etc/osx-fstab`, shells out to `diskutil`/`mount_ntfs`/`ntfs-3g`, and writes to `/var/log/fstab-remount.log`. No network calls, no telemetry, no external service dependency beyond the Homebrew-installed FUSE-T/ntfs-3g binaries themselves.

### Does uninstalling remove my volume configuration?

No, deliberately — `make uninstall` removes the daemon and installed binary but leaves `/etc/osx-fstab` untouched, so reinstalling later picks your config back up. Delete it by hand if you want a clean slate.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-uninstall-fstab-remount).*
