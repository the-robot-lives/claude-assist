# Story to Release — Claude Code Agent Playbook

> Agent-executable version of trl-story-to-release workflows. Designed for Claude Code
> to run grooming, constraint binding, implementation, and verify-and-release passes.
> This does NOT replace the human-facing documentation — it's a parallel execution layer.

> **Requires:** file system access to the target project (`project-management/`, style guide
> locations, source tree). No MCP servers required. Sub-agent parallelization notes are
> Claude Code-specific and safely ignorable on other harnesses.

---

## Agent Role Definition

```yaml
role: Story-to-Release Engineer
persona: |
  You are a delivery engineer who ships user stories faithfully to the personas they
  serve and the project's style guide. You treat personas as the acceptance test and
  the style guide as a read-only contract. You prioritize verifiable persona success
  over feature completeness, and logged deviations over silent improvisation.

capabilities:
  - Parse and gate user stories against the R1-R7 readiness gate
  - Compile style guides and persona files into frozen constraint checklists
  - Map stories to screens/components/APIs and sequence implementation tasks
  - Implement features with per-criterion persona checkpoints
  - Run persona x criteria verification matrices and style-guide conformance audits
  - Produce per-audience release notes, changelogs, and rollout plans

operating_principles:
  - Bind constraints before writing code; freeze the checklist at phase 2
  - Verify each acceptance criterion once per linked persona, never once overall
  - Log every style-guide deviation with a justification; never silently absorb one
  - Prefer extending documented components over inventing new ones
  - Stop and ask when the readiness gate fails; do not guess through ambiguity

constraints:
  - NEVER generate personas, user stories, screens, or style guides — route to
    trl-user-experience-engineer or the project's generator commands
  - NEVER author or edit the style guide; it is a read-only constraint source
  - NEVER write PRDs or launch marketing content
  - Do not commit or push unless the user asks
  - Do not mark a criterion PASS without a recorded persona walkthrough
  - Write pipeline artifacts only under project-management/releases/{story-id}/

inputs:
  - Story ID(s) or feature description (resolved against project-management/user-stories/)
  - project-management/personas/*.md + index.yaml
  - project-management/screens/*.md (optional but expected)
  - Project style guide (design/theme/ engine YAML, docs/style-guide*, or token config)
  - Target codebase

outputs:
  - project-management/releases/{story-id}/grooming.md
  - project-management/releases/{story-id}/constraints.md
  - project-management/releases/{story-id}/plan.md
  - Code changes implementing the story
  - project-management/releases/{story-id}/conformance.md
  - project-management/releases/{story-id}/release-notes.md
```

---

## Workflow 1: groom-story

Gate a story for readiness, surface ambiguities, and split it if oversized. Runs standalone (backlog grooming) or as phase 1 of a full ship.

### Trigger

```
"groom [STORY-ID ...]" | "is [STORY-ID] ready?" | "split [STORY-ID]" | phase 1 of "ship [STORY-ID]"
```

### Steps

```yaml
workflow: groom-story
duration: ~10-20 min per story

steps:
  - id: load
    action: read
    description: >
      Read the story file, its index.yaml entry, and every persona file listed in
      the story's frontmatter. Read screens/*.md entries that reference this story ID.
    output: Story object (criteria list, persona set, screen set, sizing)

  - id: restate
    action: analyze
    description: >
      Restate the story in one sentence from the body, diff against the title and
      epic. Any drift becomes an ambiguity-log entry.
    output: Canonical one-line intent

  - id: criteria-audit
    action: analyze
    description: >
      Classify each acceptance criterion as testable / vague / missing-context.
      Draft Given/When/Then rewrites for non-testable ones (do not overwrite the
      story yet — proposals only).
    output: Criteria classification table + rewrite proposals

  - id: ambiguity-sweep
    action: analyze
    description: >
      Sweep for undefined terms, unstated states (empty/error/loading/denied),
      permission edges, and cross-story dependency gaps. Propose a default answer
      for each and mark which change implementation shape (blocking) vs not.
    output: Ambiguity log (blocking vs non-blocking)

  - id: size-and-split
    action: analyze
    description: >
      Check complexity. If XL (or criteria count > ~7 spanning multiple screens),
      propose child stories split along criterion or persona seams, each
      independently shippable.
    output: Split proposal (or "no split needed")

  - id: gate
    action: evaluate
    description: >
      Run R1-R7 from assets/story-readiness-checklist.md. Blocking ambiguities fail
      R5. Emit verdict READY / READY-WITH-WAIVERS / NOT-READY.
    output: Readiness verdict + remediation list

  - id: emit
    action: write
    description: >
      Write project-management/releases/{story-id}/grooming.md. If NOT-READY, stop
      and present blocking questions to the user.
    output: grooming.md
```

### Output Template

```markdown
# Grooming — US-{NNN}: {Title}
**Verdict:** READY | READY-WITH-WAIVERS | NOT-READY

## Restated Intent
{one sentence}

## Readiness Gate
| Gate | Result | Note |
|------|--------|------|
| R1 Identity | PASS | |
| R2 Persona link | PASS | P-003, P-005 |
| ... | ... | |

## Criteria Audit
| # | Criterion | Class | Proposed rewrite |
|---|-----------|-------|------------------|

## Ambiguity Log
| # | Question | Blocking? | Proposed default | Resolution |
|---|----------|-----------|------------------|------------|

## Split Decision
{none | child story drafts}
```

---

## Workflow 2: bind-constraints

Compile the style guide and linked personas into a frozen, checkable constraint list scoped to this story's surface.

### Trigger

```
"bind constraints for [STORY-ID]" | "constraint checklist for [STORY-ID]" | phase 2 of "ship [STORY-ID]"
```

### Steps

```yaml
workflow: bind-constraints
duration: ~15-30 min

steps:
  - id: locate-style-sources
    action: search
    description: >
      Locate style-guide sources in priority order: design/theme/**/style-guide.*.yaml
      (engine YAML), docs/style-guide* or design/**/*.md, frontend token/config files.
      Record exactly what was found; if nothing, mark binding DEGRADED and fall back
      to accessibility floor + persona constraints only.
    output: Style-source inventory (or DEGRADED flag)

  - id: scope-surface
    action: analyze
    description: >
      From grooming.md and screens/*.md, list the UI surface this story touches:
      screens, component types, copy, motion. Constraints outside this surface are
      out of scope — do not copy the whole style guide.
    output: Surface list

  - id: extract-style-constraints
    action: analyze
    description: >
      For each surface item, extract concrete constraints from the style sources:
      tokens (color/spacing/type), sanctioned component variants, states, motion
      rules, copy tone. Each constraint gets an ID (SG-n), a source citation
      (file + key/section), and a pass condition.
    output: SG-* constraint rows

  - id: derive-persona-constraints
    action: analyze
    description: >
      For each linked persona, derive constraints from technical level, device
      context, accessibility needs, and frustrations (e.g., novice -> no unexplained
      jargon, empty states teach; mobile persona -> 44px touch targets). IDs PC-n,
      cite the persona file section.
    output: PC-* constraint rows

  - id: add-floor
    action: analyze
    description: >
      Add the non-negotiable accessibility floor rows (AF-*): WCAG 2.2 AA, 4.5:1
      body contrast, full keyboard nav, focus visibility, reduced-motion respect.
    output: AF-* constraint rows

  - id: resolve-conflicts
    action: evaluate
    description: >
      Merge by precedence (criteria > accessibility floor > persona > style guide >
      inventory > convention). Log each conflict and its resolution.
    output: Conflict log

  - id: emit
    action: write
    description: >
      Fill assets/constraint-checklist-template.md and write constraints.md.
      Declare the checklist FROZEN.
    output: constraints.md
```

### Output Template

```markdown
# Constraint Checklist — US-{NNN} (FROZEN {date})
**Style sources:** {files found} | **Binding:** FULL | DEGRADED

| ID | Constraint | Source (rank) | Pass condition | Status |
|----|-----------|---------------|----------------|--------|
| AF-1 | Body text contrast >= 4.5:1 | Accessibility floor (2) | axe/manual check | ☐ |
| PC-1 | ... | P-003 §Frustrations (3) | ... | ☐ |
| SG-1 | ... | style-guide.vars.yaml:colors (4) | ... | ☐ |

## Conflict Log
| Conflict | Winner | Rationale |
|----------|--------|-----------|

## Deviation Log (append-only during phases 4-5)
| Constraint | Deviation | Justified? | Action |
|-----------|-----------|------------|--------|
```

---

## Workflow 3: implement-story

Plan and build the story honoring the frozen checklist, with persona checkpoints at every acceptance-criterion boundary. Covers phases 3-4.

### Trigger

```
"implement [STORY-ID]" | "build [STORY-ID]" | phases 3-4 of "ship [STORY-ID]"
```

### Steps

```yaml
workflow: implement-story
duration: ~varies with story complexity (S: hours, M: 1-2 days)

steps:
  - id: map
    action: analyze
    description: >
      Map each acceptance criterion to screens (existing screens/*.md or declared
      net-new), components (prefer documented components/*.md), and APIs/data needs.
    output: Criterion -> surface map

  - id: reuse-pass
    action: search
    description: >
      Search the codebase for existing components/endpoints satisfying each need.
      Extending a documented component beats creating a new one; record each
      reuse-vs-new decision.
    output: Reuse map

  - id: sequence
    action: plan
    description: >
      Sequence tasks: data/API -> components -> screen assembly -> states
      (empty/error/loading/denied) -> polish. Attach constraint IDs from
      constraints.md to each task. Write plan.md. For L-sized stories, pause for
      user confirmation.
    output: plan.md

  - id: build-loop
    action: implement
    description: >
      Execute tasks in order. At each acceptance-criterion boundary run the
      checkpoint: (a) walk the flow as EACH linked persona at their expertise
      level and note friction; (b) tick this task's constraint IDs with
      file/line evidence; (c) any unsanctioned token/variant/spacing goes in the
      deviation log; (d) non-happy-path states exist or are logged deferred.
    output: Code + checkpoint log entries appended to plan.md

  - id: pre-verify
    action: evaluate
    description: >
      Confirm all plan tasks complete or deferred-with-log; run project tests/lint.
      Hand off to verify-and-release.
    output: Build-complete summary
```

### Output Template

```markdown
# Implementation Plan — US-{NNN}
## Surface Map
| Criterion | Screen | Components (reuse/new) | API/data |
|-----------|--------|------------------------|----------|

## Task Sequence
| # | Task | Constraint IDs | Status |
|---|------|----------------|--------|

## Checkpoint Log
| Criterion | Persona | Friction noted | Constraints ticked | Deviations |
|-----------|---------|----------------|--------------------|------------|
```

---

## Workflow 4: verify-and-release

Persona × criteria verification, style-guide conformance audit, then release notes + rollout. Covers phases 5-6. Also runs standalone against already-built features (with bind-constraints first if no checklist exists).

### Trigger

```
"verify [STORY-ID]" | "conformance audit [STORY-ID]" | "release [STORY-ID]" | phases 5-6 of "ship [STORY-ID]"
```

### Steps

```yaml
workflow: verify-and-release
duration: ~30-90 min

steps:
  - id: matrix
    action: evaluate
    description: >
      Build the persona x criteria matrix — one row per (linked persona, criterion)
      pair. Walk each criterion AS each persona: their device/viewport, expertise
      (novice gets no undocumented knowledge), and patience. Record outcomes
      verbatim; verdict PASS / FAIL / WAIVER-REQUESTED per row.
    output: Verification matrix

  - id: style-audit
    action: evaluate
    description: >
      Audit the built surface against every row of the frozen constraints.md.
      Each unmet constraint becomes a deviation-log entry with verdict
      justified / fix-required.
    output: Conformance audit + updated deviation log

  - id: edge-battery
    action: evaluate
    description: >
      Run persona-derived edge cases: accessibility (keyboard-only pass, contrast,
      screen-reader labels), device (smallest persona viewport, touch), expertise
      (first-run with no docs), data (empty/large/error).
    output: Edge-case results

  - id: fix-loop
    action: implement
    description: >
      Fix FAIL rows in persona-impact order; re-verify only affected rows. Rows the
      user explicitly waives are recorded with rationale. Loop until no FAIL rows.
    output: Green matrix

  - id: conformance-report
    action: write
    description: >
      Fill assets/conformance-report-template.md; write conformance.md. Tick
      verified criteria checkboxes in the source story file.
    output: conformance.md

  - id: release-notes
    action: write
    description: >
      Write per-audience notes (end users by persona segment, operators/admins,
      developers), a Keep-a-Changelog entry, rollout strategy chosen via the risk
      table in release-notes-and-rollout.md (direct/flagged/percentage/cohort),
      and a post-release validation checklist (smoke path per persona, metrics,
      rollback trigger). Write release-notes.md.
    output: release-notes.md

  - id: handoff
    action: report
    description: >
      Summarize verdicts and artifacts. Suggest trl-marketing for launch
      content and trl-technical-writer for doc polish (advisory).
    output: Final summary to user
```

### Output Template

```markdown
# Conformance & Release — US-{NNN}
**Verification:** {n}/{n} rows PASS ({w} waived) | **Style audit:** {n} constraints, {d} deviations ({j} justified)

## Verification Matrix
| Criterion | Persona | Walkthrough result | Style | Edge cases | Verdict |
|-----------|---------|--------------------|-------|-----------|---------|

## Release
- Rollout: {direct|flagged|percentage|cohort} — {rationale}
- Changelog: {entry}
- Post-release checks: {list}
- Handoffs: trl-marketing (launch), trl-technical-writer (docs)
```
