# How to: build, install, and verify queue-populator for the first time

**Goal:** get the menu bar app installed, permissioned, and capturing your first voice memo into a queue file.
**Prereqs:** macOS with Xcode/Swift toolchain installed (`swift build` must work); this repo checked out.

1. Build and install the app bundle + launch agent removal step (app launches manually, not at login):
   ```bash
   cd utilities/osx/queue-populator
   ./install.sh
   ```
   This runs `swift build -c release`, assembles `/Applications/Queue Populator.app`, and prints the next steps.

2. Grant microphone + speech-recognition permissions (does its own permission prompts, then exits):
   ```bash
   "/Applications/Queue Populator.app/Contents/MacOS/queue-populator" --authorize
   ```

3. Launch the app from `/Applications/Queue Populator.app` (double-click, or `open "/Applications/Queue Populator.app"`). A menu bar icon appears.

4. Configure an LLM provider so memos can be classified — see [howto/configure-llm-provider.md](configure-llm-provider.md). The default provider is `anthropic`, expecting `ANTHROPIC_API_KEY` in your shell environment.

5. Speak the wake phrase (default **"hey robot"**), say a short memo, then the end phrase (default **"that is all"**), then **"approve memo"** to accept the transcript. The LLM classifies it; review the proposed entries in the Review window and say **"looks good"** (or click Approve).

**Verify:**
```bash
tail -n 5 ~/personal-development/queue/binlog.jsonl   # or whichever file it routed to
```
You should see a new JSONL line with today's timestamp and your memo text.

**Gotchas:**
- No mic/speech prompt appeared → you already granted permissions previously, or ran the binary without `--authorize` first; re-run step 2.
- Nothing gets classified → no LLM key resolved; check [howto/configure-llm-provider.md](configure-llm-provider.md).
- Wrong queue file / no split → the classifier picks from the fixed manifest; see [howto/debugging.md](debugging.md) if output looks wrong, or edit `Sources/Queue/QueueManifest.swift` to add a category (rebuild + `./install.sh` required).
