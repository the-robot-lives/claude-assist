# How to: fix the most common generation failures

**Goal:** recognize the tool's abort/skip messages and know the fix without re-reading the source.
**Prereqs:** none.

## Dependency cycle detected

```
Error:
   0: Dependency cycle detected involving: cycle-a, cycle-b
Location:
   src/dag.rs:86
```

**Fix:** two or more `.media.prompt` files in the same scan reference each other via
`depends_on[].ref`, directly or transitively. Break the cycle — one of them shouldn't depend on
the other. This is an immediate abort for the whole batch, not just the offending files, since
tier ordering can't be computed. `--dry-run` catches this without spending any API calls, so
always dry-run a new batch of interdependent prompts first.

## `${alias}` doesn't resolve / dependency ref not found

**Fix:** `depends_on[].ref` matches by the *other file's* `id` field or its relative path — not
its filename. Confirm the `id:` in the referenced prompt matches exactly, and that both files are
in the scanned scope (same directory or a parent you passed to the CLI).

## Provider dies immediately with a named missing-key error

**Fix:** this is `401`/`403` handling — the tool dies rather than retrying, since a bad key won't
fix itself. Resolution order is: environment variable → `.envrc.k8.dc` secrets layer at
`$INFRA_ROOT` → hard error. See the API Key Resolution table in `README.md` for the exact env var
per provider (e.g. `GEMINI_API_KEY`, `SUNO_API_KEY`, `XAI_API_KEY`). `--dry-run` tolerates a
missing key so you can still preview the plan.

## Post-processing step silently does nothing

**Fix:** not a bug — **all `post_processing` actions are currently stubbed** (`resize`, `crop`,
`convert`, `optimize`, `trim`, `normalize`). They parse and show in `--dry-run` output but no
transform runs. If you need the resize/convert today, pipe the generated output through
ImageMagick/cwebp/ffmpeg yourself; see README "Post-Processing → Implementation Status" for what's
planned.

## Output file wasn't overwritten on a re-run

**Fix:** default behavior is skip-if-exists. Pass `--force` to regenerate over an existing output
file.

## Eval grading never seems to run / always accepts the first generation

**Fix:** an `eval` block only grades if a probeable evaluator endpoint responds. Check reachability
in order: `MEDIA_EVAL_BASE_URL`/`--eval-url` → LAN inference server (`192.168.68.59:3713`) →
`noizu.server:3713` → in-cluster `lmstudio-proxy` → local port-forward. If none respond, the tool
silently skips grading (or uses Groq-graded best if `GROQ_API_KEY` is set) — this is a graceful
degrade, not an error. Run `bin/media-eval-port-forward` if you're off the LAN and need the
in-cluster evaluator. Also: `music`/`voice` prompts aren't gradable yet — omit `eval` blocks on
those or expect a warning + first-generation acceptance.
