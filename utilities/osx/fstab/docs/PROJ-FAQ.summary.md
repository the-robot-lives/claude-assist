# fstab-mounter — FAQ Summary

Question index only. Full answers in [PROJ-FAQ.md](PROJ-FAQ.md).

## Motivation
- Why would I need this instead of just using Disk Utility / Finder auto-mount?
- Why is this a LaunchDaemon and not a login item or LaunchAgent?
- Why not just add entries to macOS's real `/etc/fstab`?

## Fit
- When is this the wrong tool for my situation?
- Does this work on Apple Silicon / recent macOS versions?

## Comparison
- `ntfs` vs `ntfs-ro` — which fstype should I actually use?
- `osx-fstab.stub`/`ntfs` fstype vs `mount-ntfs-rw.sh` — why are there two ways to get NTFS rw?
- How is this different from the Linux/k8s tools elsewhere in `utilities/`?

## Capability
- Can it recover if a volume's UUID changes (e.g. after reformatting)?
- Can I apply a config change without rebooting?
- Can mountpoints or labels contain spaces?

## Caveats
- What's the security cost of the NTFS rw path?
- What happens if `make install` runs where sudo isn't cached and isn't passwordless?
- What happens on a volume that never mounts — does the daemon retry indefinitely or give up?

## Trust
- Does this send any data anywhere, or touch anything outside the target Mac?
- Does uninstalling remove my volume configuration?
