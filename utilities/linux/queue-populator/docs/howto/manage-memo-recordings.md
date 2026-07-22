# How to: find, disable, or delete memo audio recordings

**Goal:** know where the recorded MP3 of each approved memo lands, and stop
or clean up that trail if you don't want a persistent audio copy.
**Prereqs:** none — this only matters if `ffmpeg` (or `lame`) is installed;
without either, no audio is ever exported (see `--check`).

1. Locate exports: they land as `memo-<yyyyMMdd-HHmmss>.mp3` in the parent
   directory of your configured `queueBasePath` (default
   `~/personal-development/queue/` → exports go to
   `~/personal-development/`). List them:
   ```
   ls ~/personal-development/memo-*.mp3
   ```
2. Delete existing exports you don't want kept:
   ```
   rm ~/personal-development/memo-*.mp3
   ```
3. Stop future exports — there's no config toggle for this independent of
   the encoder; remove both `ffmpeg` and `lame` (whichever your distro has),
   or leave one installed and just delete exports periodically via step 2.

**Verify:** `queue-populator --check` shows `△ ffmpeg not found` (export
disabled going forward); `ls ~/personal-development/memo-*.mp3` returns
nothing after step 2.
**Gotchas:**
- A memo with silence/no captured frames produces no MP3 at all — don't
  expect one file per approved memo if you spoke nothing before
  "that is all".
- Uninstalling (`./uninstall.sh`) does **not** touch these exports — see
  [PROJ-HOWTO.md#how-to-uninstall-queue-populator](../PROJ-HOWTO.md#how-to-uninstall-queue-populator).
- Removing `ffmpeg` doesn't stop `lame`-based export if that's also
  installed — check for both.
