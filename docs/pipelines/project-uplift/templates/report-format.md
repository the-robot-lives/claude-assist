# report-format.md (version: 1)

The fixed report block every stage agent replies with — **and only this** (per the stage
template's instruction to "reply ONLY with the report-format.md block"). No prose before or
after. Keep the whole block to **30 lines or fewer**: omit count/detail keys that don't apply
to your stage rather than padding with `null`/`0`.

```yaml
report:
  project: "{project-slug}"
  stage: "A|B|C|D"
  theme: "{theme-slug}"          # Stage C only; omit entirely for A/B/D
  status: "done|blocked|failed"
  counts:                        # include only the keys relevant to your stage
    personas: N
    stories: N
    screens: N
    components: N
    effective_theme_count: N.N   # Stage B only (the E value)
    themes_written: N            # Stage B only
    prompts: N                   # Stage C only
    images: N                    # Stage C only
    api_calls: N                 # Stage C only — must be <= 12
    milestones: N                # Stage D only
    story_coverage_pct: N        # Stage D only
  verify:                        # one line per check from your templates/verify.md section
    - "PASS: <check name>"
    - "FAIL: <check name> — <one-line reason>"
  committed: "<sha>"              # or false if nothing was committed (blocked/failed)
  notes:
    - "<anything the next reader needs — max ~3 short bullets>"
  blockers:                      # omit key entirely if status == done
    - "<reason, matching state file's blocked: field>"
```

## Rules

- `status: done` requires every check in your stage's `verify.md` section to PASS. If any
  FAIL, use `status: blocked` (recoverable — a top-up/retry can fix it) or `status: failed`
  (something broke that needs a human or a different approach) — never report `done` with a
  FAIL line still in `verify:`.
- `committed:` is the real commit SHA (`git rev-parse HEAD` after the commit) when
  `status: done`. When blocked/failed, still commit the state file alone if you changed it
  (see your stage template's failure-handling step) and report that SHA; if truly nothing
  was committed, use `false`.
- Keep `notes` to what changes the next agent's or Loom's decision — not a narration of steps
  taken. "4 existing themes scored E=2.1, wrote 5 new" is a note; "I read the treatise and
  then wrote the files" is not.
- Stage C reports once per theme (one report per spawn) — `theme:` is required, and `counts`
  should reflect that theme only, not the project's other themes.
