# stage-a-docs-pm.md (version: 1)

Stage A — README + project-management foundation (personas, user stories, screens,
components). This template is self-contained: you get this file, your project's state file,
and your spawn params. You do not have access to the pipeline plan or any other pipeline doc
— everything you need to act is below.

## Params (from your spawn prompt)

- `project` — the slug under `projects/{project}/`
- `eval`, `media` — pipeline-wide media availability flags (informational only; Stage A does
  not render or evaluate media — that's Stage C)

## 0. Setup

1. Read `docs/pipelines/project-uplift/state/{project}.yaml` first. It has your project's
   census (existing personas/stories/screens/components counts, README stub flag, any
   quirk notes) — this is your starting point, not a blank slate.
2. Set `stage_a.status: in-progress` in that file now, in your working tree. Do not commit
   yet — this is just so a crash mid-run is visible on resume.
3. Do **not** create a tobor session. Do not read the pipeline plan file or any file outside
   this template, your state file, and the target project's own tree.
4. Invoke **Skill(trl-user-experience-engineer)** before doing any authoring below — it
   governs the persona/story/screen quality bar this template's schemas assume.

## 1. Normalize directory layout — do this FIRST

Check these alternative locations for existing persona/story/PM content before writing
anything new:

| What to look for | Alternative locations |
|---|---|
| Personas | `docs/personas/`, `projects/personas/`, `personas/` |
| User stories | `docs/user-stories/`, `docs/stories/`, `projects/user-stories/`, `projects/stories/`, `user-stories/`, `stories/` |
| Mixed PM artifacts | `docs/project-management/`, `projects/project-management/` |

Rules:
1. If `project-management/` already exists with content, use it as-is — skip migration.
2. If content exists in an alternative location, `git mv` it into `project-management/`
   (preserves history), normalizing names to the canonical `personas/` and `user-stories/`
   (not `stories/`, not `user_stories/`).
3. If a `docs/project-management/` (or `projects/project-management/`) directory exists,
   `git mv` the whole thing to `project-management/` at the project root.
4. If nothing exists anywhere, create `project-management/personas/` and
   `project-management/user-stories/` fresh.
5. After migration, grep for old paths in any `index.yaml` or markdown cross-references and
   fix them.

Your project's state file may already flag a known non-standard location (e.g.
`docs/project-management/`) — if so, this step is not optional.

## 2. README

**Stub test:** README is a stub if it doesn't exist, has fewer than 50 lines, OR its first
`#` heading is literally `# start-app` (the scaffold boilerplate heading).

If stub: author a substantial README grounded in actual evidence — read the project's code,
`design/`, and `docs/` directories, and any existing (even thin) README, before writing. Do
not invent product claims that aren't supported by what's in the repo. Cover: what the
product is, who it's for, key features/screens, tech stack, how to run it locally if that's
discoverable.

If the README exists and passes the mechanical test but reads as topically unrelated to the
project (e.g., it describes something else entirely — check your state file's `notes:` for a
flag like this), verify by reading the whole file before trusting the line-count heuristic.

## 3. Personas — `project-management/personas/`

**How many:** 5-10, covering all primary/secondary/tertiary segments implied by the README
and code, plus at least one edge-case/underserved persona. If the system has agent/bot
actors as users, include at least one persona for that.

**File:** `project-management/personas/P-{NNN}-{slug}.md` (continue numbering past any
existing personas — never renumber existing files).

```markdown
---
id: P-{NNN}
name: "{Full Name}"
slug: "{slug}"
archetype: "{Archetype Label}"
segment: "{primary|secondary|tertiary|edge-case}"
tags: [{tag1}, {tag2}, ...]
---

# {Full Name} — {Archetype Label}

## Demographics

| Field | Value |
|-------|-------|
| **Age** | {range} |
| **Role** | {job title or life role} |
| **Technical Level** | {Novice / Intermediate / Advanced / Expert} |
| **Industry** | {industry or domain} |
| **Location** | {region or context} |

## Bio

{2-3 sentences — who they are, what they care about, what their day looks like.}

## Goals

1. {Primary goal}
2. {Secondary goal}
3. {Tertiary goal}

## Frustrations

1. {Pain point this product addresses}
2. {Pain point in their current workflow}
3. {Unmet need}

## Behaviors

- {How they currently solve the problem}
- {Tools they use}
- {Relevant habits}

## Job to Be Done

> "{When I [situation], I want to [motivation], so I can [expected outcome].}"

## Relationship to Product

{Discovery, adoption, which features matter most, what would make them churn.}

## Scenarios

1. **{Scenario name}** — {realistic usage scenario}
2. **{Scenario name}** — {another}
```

**Index** — `project-management/personas/index.yaml` (regenerated from a fresh directory
listing, see §6):

```yaml
personas:
  - id: P-001
    name: "{Name}"
    archetype: "{Archetype}"
    segment: "{segment}"
    file: P-001-{slug}.md
```

## 4. User Stories — `project-management/user-stories/`

**How many:** exactly 100 minimum (an existing over-target count, e.g. 1000, is a PASS —
never trim). Every persona must be referenced by at least 3 stories; no orphan personas.

Rough distribution (adjust to the actual product): core features 30-40, onboarding/auth
8-12, settings 5-8, admin/moderation 8-12, search/discovery 6-10, social/collaboration 8-12,
edge cases/error states 5-8, accessibility/i18n 3-5, performance/scale 3-5,
integration/API 3-5.

**File:** `project-management/user-stories/US-{NNN}-{slug}.md` (continue numbering past any
existing stories).

```markdown
---
id: US-{NNN}
title: "{Short title}"
slug: "{slug}"
personas: [{P-001}, {P-003}]
epic: "{Epic Name}"
priority: "{must-have|should-have|could-have|won't-have-yet}"
complexity: "{S|M|L|XL}"
tags: [{tag1}, {tag2}]
---

# US-{NNN}: {Short Title}

## User Story

**As a** {persona archetype or name} ({persona ID}),
**I want to** {action or capability},
**So that** {benefit or outcome}.

## Acceptance Criteria

- [ ] {Given [context], when [action], then [expected result]}
- [ ] {Given [context], when [action], then [expected result]}
- [ ] {Given [context], when [action], then [expected result]}

## Notes

{Brief — 1-3 sentences. Cross-reference related stories by ID if useful.}
```

MoSCoW honestly: `must-have` = product is broken without it; `should-have` = expected but a
workaround exists; `could-have` = nice-to-have; `won't-have-yet` = planned, deferred. Size
honestly: S = hours, M = 1-2 days, L = 3-5 days, XL = needs decomposition. Acceptance
criteria must be testable (Given/When/Then), not vague ("user can see their profile" is bad;
"given a logged-in user, when they navigate to /profile, then they see display name, avatar,
bio" is good).

**Index** — `project-management/user-stories/index.yaml`:

```yaml
epics:
  - name: "{Epic Name}"
    stories: [US-001, US-002, ...]

stories:
  - id: US-001
    title: "{Title}"
    personas: [P-001, P-003]
    epic: "{Epic Name}"
    priority: "{priority}"
    complexity: "{complexity}"
    file: US-001-{slug}.md
```

If your project's census shows a **structural mismatch** — screens/components already exist
with 0 backing stories, or personas exist with 0 stories, or vice versa — reconcile rather
than blindly regenerating: author what's missing so cross-references resolve, don't
duplicate what's already there just because the "expected" artifact was absent.

## 5. Screens + Components (only after personas + stories are solid)

Read ALL user stories. For each distinct screen/view, write:

**Path:** `project-management/screens/{NN}-{screen-slug}.md`

```markdown
# {Screen Name}

| Field | Value |
|-------|-------|
| **ID** | `{screen-slug}` |
| **Type** | {Primary\|Dashboard\|Settings\|Modal\|Storyboard} |
| **Category** | {Category Name} |
| **User Stories** | {US-001, US-002, ...} |

## Description

{What this screen does and why it exists}

## Key Components

- **{Component name}** — {What it does here} ({US-XXX reference})

## Interactions

- {User interaction description}

## Navigation

- Accessible from: {where users arrive from}
- Links to: {where users can go from here}
```

Then extract reusable components:

**Path:** `project-management/components/{NN}-{component-slug}.md`

```markdown
# {Component Name}

| Field | Value |
|-------|-------|
| **ID** | `{component-slug}` |
| **Category** | {Category Name} |
| **Used In** | {NN-Screen Name, NN-Screen Name, ...} |

## Description

{What this component does}

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | {chip/badge/single-line} |
| **Compact** | {card/summary} |
| **Expanded** | {panel/detail} |
| **Full Page** | {standalone page} |

(Omit rows that don't apply)

## Props / Configuration

- `{propName}` — {description}

## Interactions

- {Interaction description}
```

Both dirs need a `README.md` with a category table, full index, total count, and (for
screens) confirmation every user story maps to at least one screen.

Component categories to draw from: Data Display, Cards & Tiles, Navigation & Layout, Input &
Forms, Feedback & Indicators, AI-Specific, Modals & Overlays, Domain-Specific, Tables &
Lists. Focus on components appearing across 2+ screens or representing complex, even if
single-use, interaction patterns.

## 6. Idempotency — top-up only

This project may already have some or all of these artifacts (check your state file's
census). Never delete or blanket-regenerate correct existing content. Read what exists, fill
gaps (missing personas, stories short of 100, screens not yet extracted), continue ID
numbering rather than renumbering existing files.

**Always regenerate every `index.yaml` from a fresh directory listing at the end of this
stage** — never hand-append an entry. A stale index (referencing renamed/deleted files, or
missing newly added ones) is a common and easy-to-avoid bug.

## 7. Verify

Run `templates/verify.md` §A with `PROJECT={project}` set. Paste every `PASS:`/`FAIL:` line
into your report's `verify:` list.

## 8. Update state and commit

Update `docs/pipelines/project-uplift/state/{project}.yaml`:
- `stage_a.status: done` (or `blocked`, see §9)
- `stage_a.attempts` incremented
- `stage_a.counts` set to the final personas/stories/screens/components counts
- `census.*` fields refreshed to match if they changed

**Commit protocol** (pathspec-only — never `git add -A`, never the whole `projects/{project}`
tree; list every path you actually touched):

```bash
git add <specific paths only — e.g. projects/{project}/README.md projects/{project}/project-management/...>
REPO_LOCK_SESSION=$(grep -oP 'repo_lock_session:\s*\K\S+' docs/pipelines/project-uplift/state/_pipeline.yaml) \
repo-lock exec --label "uplift {project} A" -- \
  git commit -m "{project}: uplift stage A — {one-line summary}" \
             -m "Co-Authored-By: Loom <loom@therobotlives.com>" \
  -- <same pathspecs> docs/pipelines/project-uplift/state/{project}.yaml
```

Trailer is **Loom only** — never Claude/Anthropic, never a Claude-Session URL.

## 9. Report

Reply **ONLY** with the `templates/report-format.md` block. No prose before or after.

## 10. Failure handling

If a `verify.md` §A check fails and you can't fix it this pass: set `stage_a.status:
blocked` with a `blocked:` reason string in the state file, still commit the state file
alone (pathspec-only, same protocol above) so progress is visible, and report `status:
failed` (or `blocked` if it's a clean top-up-later case) with `blockers:` populated in your
report.
