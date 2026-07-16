# How to: customize wake and command phrases

**Goal:** replace the default trigger phrases ("hey robot", etc.) with your own.
**Prereqs:** app installed; edit while queue-populator is stopped (it loads
config once at startup).

1. Open `~/.config/queue-populator/config.json` (created on first save; run
   the app once and quit, or let `install.sh`'s `--check` step create the
   directory).
2. Edit the `phrases` object — all fields are plain strings matched via fuzzy
   phrase detection against the live transcript:

   | Field | Default |
   |---|---|
   | `wake` | `hey robot` |
   | `end` | `that is all` |
   | `approveMemo` | `approve memo` |
   | `cancel` | `cancel that` |
   | `approve` | `looks good` |
   | `revise` | `revise that` |
   | `openClaude` / `closeClaude` | `robot open claude` / `robot close claude` |
   | `openCodex` / `closeCodex` | `robot open codex` / `robot close codex` |
   | `openLlama` / `closeLlama` | `robot open llama` / `robot close llama` |

3. Restart `queue-populator`.

**Verify:** say your new wake phrase — the tray icon should change state to
recording.
**Gotchas:**
- Very short or common phrases increase false triggers (fuzzy matching
  against continuous transcript); keep phrases at least 2-3 distinct words.
- Open/close phrases only fire while the app is idle — a phrase spoken mid-memo
  is treated as memo content, not a command.
