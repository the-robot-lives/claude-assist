# How to: sync files with the colo server

**Goal:** push or pull files between your machine and `noizu.server` with automatic `/Users` ↔ `/home` path mirroring, so you don't have to remember the remote-side path.
**Prereqs:** SSH access to `noizu.server` as `$COLO_USER` (default `keith`); `rsync` on both ends.

## Single-flag mode (mirrored paths)

Given a local path, `colo-sync` derives the remote path by swapping `/Users/<user>` ↔ `/home/<user>`, and vice versa.

```bash
colo-sync --to   /Users/keith/Work/project     # push local → mirrored remote path
colo-sync --from /Users/keith/Work/project     # pull mirrored remote path → local
```

## Two-flag mode (explicit paths)

When source and destination don't follow the mirrored convention:

```bash
colo-sync --from /home/keith/data --to /Users/keith/Downloads/data
```

## Preview before running

```bash
colo-sync --to /Users/keith/Work/project --dry-run   # rsync --dry-run preview
colo-sync --to /Users/keith/Work/project --cmd        # print the rsync command, don't run it
```

**Verify:** `--dry-run` output lists the files that would transfer with no changes made; a real run ends with rsync's standard summary (files transferred, speedup).

**Gotchas:**
- Only one of `--to`/`--from` alone triggers mirrored-path mode — pass both when the local and remote layouts diverge (e.g. syncing into a differently-named directory).
- Default excludes (`node_modules`, `.venv`, `_build`, `.terraform`, `dist`, etc.) are always applied; add more via `COLO_RSYNC_OPTS="--exclude=foo"` rather than editing the script.
- Wrong host/user: override with `COLO_HOST=<host> COLO_USER=<user> colo-sync ...` rather than editing defaults in the script.
