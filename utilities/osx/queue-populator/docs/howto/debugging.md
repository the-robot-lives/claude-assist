# How to: debug queue-populator when something isn't working

**Goal:** find out why a memo wasn't captured, classified, or written, using the app's structured debug log.
**Prereqs:** the app installed; a terminal.

1. Launch from a terminal with verbose partial-transcript output instead of double-clicking:
   ```bash
   "/Applications/Queue Populator.app/Contents/MacOS/queue-populator" --verbose
   ```

2. Tail the structured debug log (truncated fresh on every launch, also mirrored to stderr):
   ```bash
   tail -f ~/.config/queue-populator/debug.log
   ```
   Look for tagged lines: `[LOAD]`/`[SAVE n/8]` (config read/write), `[ENV]` (API key env var resolution), `[SAVE 4/8] FAIL dc encrypt returned nil` (secret store issue).

3. Inspect the persisted config directly (secrets are stored encrypted, safe to view):
   ```bash
   cat ~/.config/queue-populator/config.json
   ```

**Verify:** reproduce the failing action (speak a memo, open the config dialog, etc.) and confirm the log shows where the flow stopped.

**Gotchas:**
- `[SAVE 4/8] FAIL dc encrypt returned nil` → `dc` isn't installed at `~/.local/bin/dc`; run `make install-utilities` from the monorepo root, or store the key as `env:VARNAME` instead.
- `[ENV] resolve(...) -> ` empty even though the var is exported → the value came back empty after stripping shell-integration escape sequences (iTerm2/OSC codes); check the raw hex dump line just above it in the log.
- No `[LOAD]`/`[SAVE]` lines appear at all → you're looking at a stale log from the previous launch; the file truncates only at process start, so `tail -f` before launching, not after.
- Full memo pipeline reference (states, transitions) is in [PROJ-ARCH.md](../PROJ-ARCH.md).
