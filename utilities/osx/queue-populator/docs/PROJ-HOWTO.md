# queue-populator — How-To

Task-oriented guides for things you'll actually do with this app. For *what it is*, see [PROJ-ARCH.md](PROJ-ARCH.md); for *where things live*, see [PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## How to: build, install, and verify it for the first time
Get the app installed, permissioned, and capturing your first voice memo into a queue file.
→ *See [howto/first-hour.md](howto/first-hour.md)*

## How to: configure the LLM provider and API key
Point queue-populator at Anthropic, OpenAI, Groq, Cerebras, DeepSeek, Z.AI, LiteLLM, Ollama, or a custom endpoint, and store the key safely.
→ *See [howto/configure-llm-provider.md](howto/configure-llm-provider.md)*

## How to: capture and approve a voice memo (the everyday workflow)

**Goal:** speak an item and have it land in the right `~/personal-development/queue/*.jsonl` file.
**Prereqs:** app running, not paused, LLM provider configured (see above).

1. Say the wake phrase — default **"hey robot"** — to start recording.
2. Speak your memo, then say the end phrase — default **"that is all"** — to stop.
3. Review the transcript in the Memo Review window; edit it or say **"approve memo"**.
4. The LLM classifies the memo against the ~30-file queue manifest and proposes one or more entries.
5. Say **"looks good"** to write them, or **"revise that"** and speak a correction to loop back to step 4.
6. Say **"cancel that"** at any point before approval to discard the memo.

**Verify:** `tail -n 5 ~/personal-development/queue/<file>.jsonl` shows your new entry with `"processed": false`.
**Gotchas:** all six trigger phrases are configurable — see below if the defaults don't fit your voice/accent.

## How to: change wake/trigger phrases or the queue base path

**Goal:** use your own wording for wake/end/approve/cancel/revise/memo-approve, or point the queue at a different directory.
**Prereqs:** app running.

1. Menu bar icon → **Configure...**.
2. Edit the phrase fields (Wake, End, Approve memo, Cancel, Approve, Revise) and/or the **Base path** field (default `~/personal-development/queue`).
3. Save. Phrases are lowercased and trimmed on save; an empty field reverts to its default rather than saving blank.

**Verify:** speak your new wake phrase — the state overlay should switch to "recording."
**Gotchas:** phrases are matched against speech-recognition output, so short/common words (e.g. "yes") cause false triggers — prefer distinct 2-3 word phrases like the defaults.

## How to: route your voice into Claude/Codex/Llama as a virtual microphone
Let another app receive your live voice as a selectable input device, opened/closed by voice command.
→ *See [howto/virtual-microphones.md](howto/virtual-microphones.md)*

## How to: add a new queue category

**Goal:** add a target `.jsonl` file the LLM can route memos into (e.g. a new `ideas/` sub-category).
**Prereqs:** repo checked out, Swift toolchain.

1. Add an entry to `QueueManifest.files` in `Sources/Queue/QueueManifest.swift`:
   ```swift
   QueueFile(path: "ideas/my-category.jsonl", description: "Short phrase the LLM will match memos against"),
   ```
2. Rebuild and reinstall: `./install.sh`.

**Verify:** speak a memo matching the new description; check the new file appears under `~/personal-development/queue/` with your entry.
**Gotchas:** the manifest is compiled into the binary (not a runtime config file) — a plain restart won't pick up the change, you must rebuild.

## How to: debug when something isn't working
Find out why a memo wasn't captured, classified, or written, using the structured debug log.
→ *See [howto/debugging.md](howto/debugging.md)*

## How to: uninstall

**Goal:** remove the app, its launch agent, and old binaries, without touching your queue data or config.
**Prereqs:** none.

1. ```bash
   cd utilities/osx/queue-populator
   ./uninstall.sh
   ```
2. If you also installed the virtual mic driver: `cd Driver && ./uninstall-virtual-mics.sh`.

**Verify:** `/Applications/Queue Populator.app` is gone; `pgrep -f queue-populator` returns nothing.
**Gotchas:** `~/.config/queue-populator/` (config + debug log) and `~/personal-development/queue/` (your data) are left intact intentionally — delete manually if you want a full wipe.
