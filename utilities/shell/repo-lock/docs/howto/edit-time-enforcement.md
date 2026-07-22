# Wiring edit-time lock enforcement into a harness

## How to: stop my agent from editing a path another session has locked

**Goal:** block `Edit`/`Write`/`MultiEdit` tool calls against a foreign-locked path *before*
they happen, not just at commit time.

**Prereqs:** `repo-lock` installed and on `PATH`; `REPO_LOCK_SESSION` exported in the harness
session; harness supports a `PreToolUse`-style hook (Claude Code does).

`repo-lock hook install` only wires commit-time enforcement — this step is separate and
opt-in because harnesses expose pre-tool-call hooks differently.

1. Add a `PreToolUse` hook in the harness's `settings.json` that runs `repo-lock check` against
   the target file and blocks the tool call on non-zero exit:
   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Edit|Write|MultiEdit",
           "hooks": [
             {
               "type": "command",
               "command": "repo-lock check \"$CLAUDE_TOOL_FILE_PATH\""
             }
           ]
         }
       ]
     }
   }
   ```
2. Adjust the path variable to whatever your harness exposes for the target file (Claude
   Code: `$CLAUDE_TOOL_FILE_PATH`; other harnesses vary — check their hook docs).

**Verify:** have a second session `acquire` the file/dir you're about to edit, then try the
edit in your harness — the tool call should be blocked with `repo-lock`'s exit-2 message
naming the holder.

**Gotchas:**
- `check` works with `REPO_LOCK_SESSION` unset (anonymous view) but then *every* held lock
  reads as foreign, including your own — export the session id in the harness first.
- This only protects tool calls that go through the harness's hook path; a plain shell `vim`
  or a script editing the file directly bypasses it entirely, same as the commit hook does
  for `git commit --no-verify`.
