# project-uplift pipeline

Brings every non-backburner project under `projects/` up to a common bar: a substantial
README, a full project-management corpus (personas, 100+ user stories, screens +
components), 7 effective theme directions (treatise + styleguide-engine YAML + renders that
feed back into the theme), and a milestone roadmap. 46 frozen targets, see `roster.yaml`.

Main thread (**Loom**) only coordinates. Every stage of every project runs in a **fresh
subagent** driven by the small committed templates in `templates/` — tobor instruction-prompt
tools aren't live yet, so committed files are the transport mechanism instead.

## Stage machine

```
Stage A (README + PM corpus)
   │
   ├──▶ Stage B (theme treatises + screen allocation)
   │        │
   │        └──▶ Stage C ×N (one fresh agent per theme, sequential within a project)
   │
   └──▶ Stage D (roadmap) — runs in parallel to B/C, only depends on A
```

Per project: `A → B → C(×themes, sequential)`, `D` after `A` (parallel to B/C, disjoint
pathspecs from B/C so no merge contention). ~11 agent runs per project across the full 46.

| Stage | What | Skill invoked | Model |
|---|---|---|---|
| A | README + personas/stories/screens/components | trl-user-experience-engineer | sonnet |
| B | Similitude scoring + treatises + screen allocation | (none — read the treatise contract ref directly) | opus |
| C | Per-theme render → reflect → implement → validate | trl-theme-designer | opus |
| D | Milestone roadmap | trl-agentic-project-manager | opus |
| Setup, roster census, resume scouts | — | — | sonnet (haiku for trivial state summaries) |
| Preflight scout | — | — | haiku |
| Final verify sweep | — | — | haiku/sonnet |

Fable (this main thread) is never itself spawned as an agent — it only coordinates, reviews
reports, and decides what to spawn next.

## Spawning a stage

Every spawn prompt is short — the template carries the detail:

```
Read docs/pipelines/project-uplift/templates/stage-{X}.md.
Params: project={project} theme={theme-or-omit} eval={on|off} media={on|off}.
Read state/{project}.yaml first.
Do NOT create a tobor session.
Reply ONLY with the report-format.md block.
```

Pass the model from the table above via the `Agent` tool's `model:` param. A failed sonnet
stage may retry once, escalated to opus.

## Resume procedure (fresh session / crashed run)

1. `Session.Create` per CLAUDE.md's hard rule (this applies to Loom's own session — stage
   agents explicitly do **not** create one).
2. Spawn one scout (haiku or sonnet) to read every `state/{project}.yaml` and
   `state/_pipeline.yaml`, and summarize into a stage matrix: which projects/stages are
   `pending`/`in-progress`/`done`/`blocked`, and what's next in dependency order.
3. Rebuild the spawn queue from that matrix. **Loom never reads project files directly** —
   only the state summary.
4. Any stage found `in-progress` (not `done`) at resume time means a prior run crashed
   mid-stage — re-run that stage's template; its own idempotency rules (top-up, regenerate
   indexes from directory listings, never re-render existing valid images) make this safe.

## Commit protocol

One commit per stage (per theme, for Stage C), **pathspec-only**, serialized through
`repo-lock` so concurrent stage agents never race the same commit:

```bash
git add <specific paths only — never `git add -A`, never a whole projects/{project}>
REPO_LOCK_SESSION=$(grep -oP 'repo_lock_session:\s*\K\S+' docs/pipelines/project-uplift/state/_pipeline.yaml) \
repo-lock exec --label "uplift {project} {stage}" -- \
  git commit -m "{project}: uplift stage {X} — {summary}" \
             -m "Co-Authored-By: Loom <loom@therobotlives.com>" \
  -- <same pathspecs> docs/pipelines/project-uplift/state/{project}.yaml
```

Trailer is **Loom only** — never Claude/Anthropic, never a Claude-Session URL. The working
tree has substantial unrelated drift outside this pipeline at any given time (other in-flight
work in this monorepo) — pathspec-only commits are load-bearing, not a style preference.

`.gitignore` (repo root) excludes `projects/*/design/asset-prompts/**/.genai.*/` and
`projects/*/design/asset-prompts/**/*.png` — the full render corpus (every candidate variant)
stays on disk for the user's future separate tracking repo; only curated impactful finals
enter git, via explicit `git add -f` (see `templates/stage-c-theme.md` §7). Never delete a
`.genai.*/` directory.

## Degraded-media mode

Checked once at setup, recorded in `state/_pipeline.yaml` `preflight:` — **re-check before
trusting a stale reading**, these are live external dependencies:

- **`media: off`** (no `generate-media-prompt` CLI, or no `GEMINI_API_KEY`): run A/B/D
  everywhere; Stage C still authors `.media.prompt` files and the theme YAML (deltas from the
  treatise), just marks image generation `deferred` per theme in state. This is a first-class
  expected outcome, not a failure — top up renders later once media is restored.
- **`eval: off`** (evaluator endpoint unreachable — the flakiest dependency in this pipeline):
  every Stage C render uses `--no-eval`. `.media.prompt` files still carry a full `eval:`
  block for whenever the evaluator comes back; today's runs just don't wait on it.
- **`styleguide_serve: off`** (`@noizu/styleguide` not resolvable from the public npm
  registry, no private-registry `.npmrc` configured): Stage C validates via the legacy
  in-repo path — `components/styleguide/app`'s `npm run generate-css` pointed at the target
  theme dir via `STYLEGUIDE_CONFIG_ROOT` (see `templates/stage-c-theme.md` §5). This path
  lacks the `✗`/`⚠` severity distinction the real serve command gives; note that in the
  conformance report.

Current readings live in `state/_pipeline.yaml` — as of pipeline setup (2026-07-16): media
**on** (confirmed end-to-end with a probe render), eval **off** (port-forward to
`svc/lmstudio-proxy` connects at the TCP level but the endpoint returns an empty reply —
looks like an unhealthy backend pod, not a missing tunnel), styleguide_serve **off** (no
private registry configured for the `@noizu` npm scope).

## Rollout: pilot → waves

1. **Pilot, sequential, W=1:** `NoizuPromptLingo` fully (A→B→C×themes→D), then
   `aifighter.com` fully. These two were chosen to stress opposite ends of the theme-scoring
   formula — NoizuPromptLingo already has 4 named themes (tests the similitude gate reducing
   new-theme count), aifighter.com has zero (tests full novel-theme creation from a bare
   `theme-style-guide` scaffold).
2. **User review gate:** present a digest — counts, sample renders, sample treatise excerpts
   — from both pilots. Do not start wave 1 before this gate passes
   (`state/_pipeline.yaml` `pilot.review_gate_passed`). Template fixes discovered during the
   pilot bump the relevant template's `version:` field (tracked in
   `state/_pipeline.yaml` `template_versions`) before waves begin.
3. **Waves of 3** for the remaining 44 targets (`roster.yaml` `policy.wave_size`), rate-limited
   to ≤3 in-flight theme-image requests at a time. Digest to the user every ~5 completed
   projects; maintain a blocked-list.
4. **Final sweep:** one verifier agent per project re-runs the full `templates/verify.md`
   suite and flips `verified: true` in its state file.

## Files in this directory

```
roster.yaml              frozen 46-target list, census, per-project quirk flags, exclusions
templates/
  stage-a-docs-pm.md      Stage A template
  stage-b-treatises.md    Stage B template
  stage-c-theme.md        Stage C template (spawned once per theme)
  stage-d-roadmap.md      Stage D template
  verify.md               copy-pasteable verification commands, one section per stage
  report-format.md        the fixed report block every stage agent replies with
state/
  _pipeline.yaml          session identity, preflight results, wave config, template versions
  {project}.yaml          one per target — per-stage status/counts/blockers (single-writer)
```
