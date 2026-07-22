# Changelog — utilities/osx/fstab

## [Unreleased]
- No changes since the last milestone tag.

## [m4-docs-refresh] — 2026-07-16 — tag: `utilities-osx-fstab/m4-docs-refresh`
Brought PROJ-ARCH/PROJ-LAYOUT docs (and their summaries) in `docs/` up to date with the NTFS support and parser changes landed since the initial import.

### Changed
- PROJ-ARCH.md and PROJ-ARCH.summary.md revised to describe current architecture
- PROJ-LAYOUT.md and PROJ-LAYOUT.summary.md revised to reflect current file layout

## [m3-entry-parser-rewrite] — 2026-06-20 — tag: `utilities-osx-fstab/m3-entry-parser-rewrite`
Rewrote the `osx-fstab.stub` line parser in `fstab-remount` from positional token-splitting to regex/awk field extraction, fixing handling of mountpoints and labels containing spaces.

### Changed
- `uuid=`/`label=`/`disk=` tagged fields extracted via regex before positional parsing
- `fstype`/`options`/`mountpoint` parsed from the right-hand side of the line via awk, so multi-word mountpoints and labels no longer break field alignment
- stub file header comments updated to document the new field-parsing rules and space/`\040` handling

## [m2-ntfs-rw-support] — 2026-06-16 — tag: `utilities-osx-fstab/m2-ntfs-rw-support`
Added NTFS read-write mounting support alongside the existing APFS/read-only handling, plus a standalone helper script for one-off rw remounts.

### Added
- `mount-ntfs-rw.sh` — standalone script to add an rw NTFS `/etc/fstab` entry and force-remount a given volume
- `ntfs` (rw, via ntfs-3g + FUSE-T) and `ntfs-ro` (native, read-only) fstypes documented and supported in `osx-fstab.stub`
- Makefile targets to support the new NTFS rw workflow

### Changed
- `fstab-remount` extended to handle the new NTFS fstypes
- `osx-fstab.stub` header rewritten with fstype support table and NTFS rw/ro examples
- `.gitignore` updated

## [m1-initial-import] — 2026-06-13 — tag: `utilities-osx-fstab/m1-initial-import`
Initial import of the osx/fstab utility into the monorepo via subtree merge: a LaunchDaemon-driven tool that remounts custom APFS volumes at boot from a `/etc/osx-fstab` declaration file, working around macOS's lack of native fstab support for non-boot volumes.

### Added
- `fstab-remount` — parses `/etc/osx-fstab`, resolves volumes by UUID → label → disk, mounts via `diskutil`
- `osx-fstab.stub` — example/template declaration file with format documentation
- `Makefile` — install/uninstall of the LaunchDaemon
- `com.keithbrings.fstab-remount.plist` — LaunchDaemon definition
- `docs/PROJ-ARCH.md`, `docs/PROJ-LAYOUT.md` (+ summaries)
