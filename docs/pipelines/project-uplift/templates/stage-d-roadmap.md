# stage-d-roadmap.md (version: 1)

Stage D — author a milestone roadmap with verifiable entry/exit gates and full story
traceability. Runs **parallel to B/C** — its only dependency is Stage A (needs the user
stories). Self-contained: this file + your state file + spawn params + committed repo docs.

## Params (from your spawn prompt)

- `project` — the slug under `projects/{project}/`

## 0. Setup

1. Read `docs/pipelines/project-uplift/state/{project}.yaml` first — `stage_a.status` must be
   `done` (or at least have real personas/stories) before this stage makes sense; if it isn't,
   note that and proceed only if enough of the story corpus already exists to roadmap against.
   `census.roadmap_exists` tells you whether this is fresh authoring or audit/top-up.
2. Set `stage_d.status: in-progress` in the state file now, uncommitted.
3. Do **not** create a tobor session.
4. Invoke **Skill(trl-agentic-project-manager)** before planning the milestone/lane
   decomposition below — it governs work-DAG decomposition and parallel-lane discipline.
5. Read the precedent at `projects/noizu-intellect/project-management/roadmap/` (00-overview.md,
   one milestone doc, index.yaml, story-coverage.md) for the full-scale version of this shape.
   **That project is an 11-zone Elixir umbrella app — do not copy its scale.** Right-size lane
   count and milestone granularity to what you're actually looking at: a small portfolio site
   might need 1-3 lanes per milestone named by area (Frontend, Content, Backend) rather than
   dedicated OTP-app zones; a bigger multi-service project earns more structure.

## 1. If a roadmap already exists — audit, don't replace

If `project-management/roadmap/` has content, run `templates/verify.md` §D against it first.
Top up only what's missing or failing (e.g., a milestone doc missing Exit criteria, or story
coverage below 80%) — don't regenerate milestone docs that already pass. `noizu-intellect`,
`therobotdrafts`, and `tobornalp.com` all have existing roadmaps in this category.

## 2. Decompose into milestones

**Hard minimum: at least 4 milestone documents** (`00-overview.md` doesn't count toward this)
regardless of project size — `verify.md` §D enforces this floor. For a small project this
usually means finer-grained milestones rather than 1-2 large ones — e.g. `M0 Foundation`,
`M1 Core Flows`, `M2 Secondary Features & Polish`, `M3 Launch Readiness` is a reasonable
4-milestone shape for a simple app. Rule of thumb: roughly 15-25 stories per milestone: total
story count ÷ 20 gives a starting milestone count, floored at 4.

Every one of the project's user stories is assigned to exactly one **primary** milestone +
lane; a second lane may be noted as "supports US-XXX" where it materially contributes, but
that's the only kind of duplication — never claim a story as a second primary owner.

## 3. `00-overview.md`

```markdown
# {Project} Roadmap — Overview

## Mission

{2-4 sentences: what building this roadmap sequences, and the core principle ordering it —
e.g. "dependency order, not calendar time." No dates/durations/estimates anywhere in this
document set — only what must be true before a milestone starts and before it exits.}

## Core principles

{3-6 short numbered principles that hold across every milestone — sequence not schedule,
lane ownership = exclusive file paths, contract-first entry (a milestone's entry criteria
list the interfaces other lanes consume), MoSCoW orders work within a lane not across
milestones.}

## Milestone summary

| ID | Name | Mission | Lanes | Stories |
|---|---|---|---|---|
| M0 | {Name} | {one sentence} | {N} | {N} |
| M1 | {Name} | {one sentence} | {N} | {N} |
...

Story count check: M0={n0}, M1={n1}, ... → {total}, matching the story corpus. See
[`story-coverage.md`](story-coverage.md) for the full traceability matrix.

## How to read this roadmap

1. Open your milestone's doc; read its **Entry criteria** — anything it depends on must
   already be satisfied.
2. Find your lane; its **Zone / exclusive paths** line is the only code you may edit.
3. Work the lane's task list in priority order (musts before shoulds/coulds).
4. A milestone isn't done from one lane's view — exit requires every lane's exit criteria
   plus any cross-lane integration task.

## Traceability

Every user story is assigned to exactly one primary milestone/lane; see
[`story-coverage.md`](story-coverage.md) for the full matrix.
```

## 4. Per-milestone doc — `NN-M{K}-{slug}.md`

Frontmatter:
```yaml
---
id: M{K}
name: {Name}
sequence: {K}
depends_on: [M{K-1}]        # [] for M0
lanes: {N}
stories: [US-XXX, US-YYY, ...]
---
```

Body sections, in order:

```markdown
# M{K} — {Name}

{1-2 sentences: what this milestone delivers and why it's sequenced here.}

## Entry criteria

- {What must already be true/merged before this milestone starts — a verifiable gate, e.g.
  "`M0`'s exit criteria are met" or "the `Screen` component contract from M1/LA is merged".}
- {"None — this is the sequence's origin point" for M0.}

## Exit criteria

- {Each one a **verifiable gate**: "command exits 0", "file exists at path X", "N stories'
  acceptance criteria are demonstrably met" — not vague ("mostly working"). Example:
  "`npm run build` exits 0 with no type errors" / "`project-management/screens/12-*.md`
  exists and is linked from the nav" / "all 6 US-0XX stories in this milestone have their
  acceptance criteria checked off".}

## Transition checklist

- [ ] {Restate each exit criterion above as a literal checkbox}
- [ ] Next milestone's Entry criteria reviewed and satisfied

## Worker lanes

### L{K}.A — {Lane Name}
- **Zone / exclusive paths:** {the specific file/dir globs this lane owns — the only paths
  it may edit}
- **Mission:** {1-2 sentences}
- **Tasks:**
  - T{K}.A.1 — {task}
  - T{K}.A.2 — {task}
- **Stories delivered:** {US-XXX, US-YYY, or "none — enablement only"}
- **Contracts:** provides {…} [contract], consumed by {…}. Consumes: {…}.

{Repeat per lane. Ticket IDs are `T{milestone}.{lane-letter}.{number}` — e.g. `T1.A.3`.}

## Cross-lane integration tasks

{Only if this milestone has >1 lane: one owning lane runs a task proving the lanes actually
compose — e.g. "an end-to-end request exercises lane A's UI calling lane B's API." Omit this
section entirely for single-lane milestones.}
```

## 5. `index.yaml`

```yaml
roadmap:
  - id: RM-00
    title: Roadmap Overview
    file: 00-overview.md
  - id: RM-01
    title: "M0 — {Name}"
    file: 01-M0-{slug}.md
  # ... one entry per milestone doc, in sequence order
  - id: RM-{NN}
    title: Story Coverage & Traceability Matrix
    file: story-coverage.md
```

## 6. `story-coverage.md`

```markdown
# Story Coverage & Traceability Matrix

Every user story is assigned to exactly one primary milestone/lane (see
[`00-overview.md`](00-overview.md)). A story appears in **Notes** when a second lane
materially supports it — the only kind of duplication this matrix records.

Count check: M0={n0}, M1={n1}, ... → {total}.

## M0 — {Name}

| US-ID | Title | Priority | Epic | Lane | Notes |
|---|---|---|---|---|---|
| US-001 | {title} | {priority} | {epic} | L0.A {Lane Name} | |
...

{repeat per milestone}

## Epic → milestone summary

| Epic | Milestone(s) |
|---|---|
| {epic} | M0, M2 |
```

**Coverage target: ≥80%** of the project's user stories must appear in this matrix (not
100% — some very long-tail edge-case stories are legitimately left unroadmapped if they
don't map cleanly to a milestone; note any deliberately-excluded stories and why, in a short
paragraph above the tables, rather than silently omitting them).

## 7. Idempotency

Top-up only, per §1. Don't rewrite milestone docs that already pass `verify.md` §D.

## 8. Verify

Run `templates/verify.md` §D with `PROJECT={project}` set. Paste every `PASS:`/`FAIL:` line
into your report's `verify:` list.

## 9. Update state and commit

Update `docs/pipelines/project-uplift/state/{project}.yaml`:
- `stage_d.status: done` (or `blocked`)
- `stage_d.attempts` incremented
- `stage_d.story_coverage_pct` set to your computed coverage percentage

**Commit protocol** (pathspec-only):

```bash
git add <specific paths only — projects/{project}/project-management/roadmap/...>
REPO_LOCK_SESSION=$(grep -oP 'repo_lock_session:\s*\K\S+' docs/pipelines/project-uplift/state/_pipeline.yaml) \
repo-lock exec --label "uplift {project} D" -- \
  git commit -m "{project}: uplift stage D — {one-line summary}" \
             -m "Co-Authored-By: Loom <loom@therobotlives.com>" \
  -- <same pathspecs> docs/pipelines/project-uplift/state/{project}.yaml
```

Trailer is **Loom only**.

## 10. Report

Reply **ONLY** with the `templates/report-format.md` block.

## 11. Failure handling

If a `verify.md` §D check fails and you can't fix it this pass: set `stage_d.status:
blocked` with a `blocked:` reason, still commit the state file alone, and report `status:
failed`/`blocked` with `blockers:` populated.
