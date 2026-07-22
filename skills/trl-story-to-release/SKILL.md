---
name: trl-story-to-release
description: >-
  Ship user stories through grooming, persona- and style-aligned implementation, acceptance checks, rollout, and release notes. Use for story readiness, implementation, definition-of-done checks, or shipping; not PRDs or launch marketing.
extended_description: >
  Take user stories from backlog to shipped release, implemented faithfully to the
  personas they serve and the project's style guide. Use this skill (/trl-story-to-release)
  to implement a user story, ship a story, groom the backlog, verify acceptance criteria,
  audit style guide conformance, implement a feature for a persona, or write release
  notes — even without the words "story to release." Also trigger on: definition of done,
  story readiness, constraint checklist, rollout plan, persona verification. NOT for
  generating personas/stories/screens or authoring style guides
  (trl-user-experience-engineer), PRD authoring, or launch marketing (trl-marketing).
ch-description: >-
  將使用者故事從梳理推進至符合人物角色與風格指南的實作、驗收、上線及發行說明。適用於故事就緒度、實作、完成定義檢查或發布；不適用於 PRD 或上市行銷。
---

# Story to Release

Phased workflow that turns a groomed user story into shipped, persona-verified, style-guide-conformant software with audience-ready release notes.

## Overview

This skill is the execution bridge between a project's `project-management/` artifacts (personas, user stories, screens) and a shipped release. It provides:

- **Story intake & grooming** — readiness gating, ambiguity surfacing, splitting oversized stories
- **Constraint binding** — style guide + persona expectations compiled into a checkable constraint list
- **Implementation planning** — story mapped to screens, components, and APIs with a sequenced task list
- **Persona-conscious implementation** — "would this persona succeed here?" checkpoints at every acceptance criterion
- **Verification** — persona × criteria walkthrough matrix plus style-guide conformance audit
- **Release** — per-audience release notes, changelog, rollout/flag strategy, post-release validation

## Core Philosophy

**Five Principles:**

1. **The persona is the acceptance test** — a criterion is not "done" when the code works; it is done when the *linked persona*, with their technical level, device, and patience, would succeed. Verify per persona, not per feature.
2. **Style guides are constraints, not suggestions** — the design system is a read-only contract. Deviations are logged and justified, never silently absorbed. If the guide is wrong, file it upstream; don't fork it locally.
3. **Bind constraints before writing code** — a constraint discovered during review is 10x more expensive than one bound before implementation. The checklist is frozen at phase 2 and audited at phase 5.
4. **A story that can't be verified can't be shipped** — grooming rejects stories with untestable criteria before any effort is spent. The readiness gate is the cheapest quality control in the pipeline.
5. **Release is a phase, not an afterthought** — notes per audience, a rollout strategy, and post-release validation are deliverables of the story, part of its definition of done.

## When to Use This Skill

- **Implementing a backlog story** — a `US-NNN` story exists and needs to become working software
- **Grooming before sprint** — assess readiness, surface ambiguities, split XL stories before committing
- **Conformance audit** — an implemented feature needs a style-guide and persona verification pass
- **Definition-of-done disputes** — produce the persona × criteria matrix that settles "is it done?"
- **Shipping** — release notes, changelog, flag/rollout plan, and post-release validation for completed work

> For generating personas, user stories, screens, or style guides, see **trl-user-experience-engineer** (`references/outputs/product-management-artifacts.md` there) — this skill only *consumes* those artifacts.
> For launch/marketing content around the release, see **trl-marketing** — this skill stops at release notes and rollout.
> For deep polish of changelogs and user-facing docs, see **trl-technical-writer** (`references/doc-types/`).

## The Story Pipeline

```
project-management/          THIS SKILL                        downstream
┌──────────────┐   ┌────────────────────────────────────┐   ┌────────────┐
│ personas/    │   │ 1 intake & grooming  ──► readiness │   │ trl-content│
│ user-stories/│──►│ 2 constraint binding ──► checklist │──►│ -publishing│
│ screens/     │   │ 3 implementation planning          │   │ trl-tech-  │
│ style guide  │   │ 4 persona-conscious implementation │   │ writer     │
└──────────────┘   │ 5 verification ──► conformance rpt │   └────────────┘
                   │ 6 release ──► notes + rollout      │
                   └────────────────────────────────────┘
```

### Story-Readiness Gate (Phase 1 exit)

A story proceeds only when every row passes (or is explicitly waived with a reason logged in `grooming.md`):

| # | Gate | Pass condition | On fail |
|---|------|----------------|---------|
| R1 | Identity | Story has ID, title, and lives in `project-management/user-stories/` | Route to generator commands, stop |
| R2 | Persona link | ≥1 persona ID in frontmatter; each persona file exists | Ask user to link; do NOT invent a persona |
| R3 | Testable criteria | Every criterion is Given/When/Then and observable | Rewrite criteria with user; log originals |
| R4 | Sized | Complexity S/M/L; XL must be split first | Split into child stories (see `story-intake-and-grooming.md`) |
| R5 | Unambiguous | No open questions that change the implementation shape | Surface ambiguity log; get answers or park |
| R6 | Screen mapping | Screens touched exist in `screens/` or are declared net-new | Note gap; net-new screens flagged in plan |
| R7 | Dependency clear | "Depends on US-XXX" stories are shipped or explicitly out of scope | Re-order backlog or narrow scope |

### Constraint-Source Precedence (Phase 2)

When constraint sources conflict, higher rows win. Every constraint in the checklist cites its source row:

| Rank | Source | Examples | Conflict behavior |
|------|--------|----------|-------------------|
| 1 | Acceptance criteria (the story) | "then metrics render within 2s" | Never overridden |
| 2 | Accessibility floor | WCAG 2.2 AA, 4.5:1 contrast, keyboard nav | Never overridden; beats style guide if guide violates it |
| 3 | Persona constraints | novice → progressive disclosure; mobile-first persona → touch targets | Overridden only by 1-2, with log entry |
| 4 | Project style guide / design tokens | colors, spacing, component variants, engine YAML tokens | Overridden only by 1-3, with log entry |
| 5 | Screen/component inventory | reuse documented components before inventing | Advisory — deviations logged |
| 6 | General platform conventions | framework idioms, house code style | Fills gaps only |

### Verification Matrix (Phase 5)

One row per (persona × criterion) pair. Shape (full method in `acceptance-verification.md`):

| Criterion | Persona | Walkthrough result | Style conformance | Edge cases checked | Verdict |
|-----------|---------|--------------------|-------------------|--------------------|---------|
| AC-1 | P-003 (novice admin) | Reached metric cards in 2 clicks, labels self-explanatory | Tokens ✓, spacing ✓ | Empty-data state ✓ | PASS |
| AC-1 | P-005 (power user) | Wanted keyboard shortcut — logged as follow-up, not blocking | ✓ | — | PASS |
| AC-2 | P-003 | Export button not discoverable below fold on 1366px | ✓ | Small viewport ✗ | FAIL → fix |

A story ships only when every row is PASS or explicitly waived by the user.

## The Six Phases

| Phase | Purpose | Key inputs | Output artifact | Reference |
|-------|---------|-----------|-----------------|-----------|
| 1. Story intake & grooming | Parse story + criteria + personas; surface ambiguities; split oversized | `US-*.md`, `index.yaml`, personas | `grooming.md` + readiness verdict | `story-intake-and-grooming.md` |
| 2. Constraint binding | Compile style guide + persona expectations into a frozen checklist | Style guide, persona files, screens | `constraints.md` | `constraint-binding.md` |
| 3. Implementation planning | Map story → screens/components/APIs; sequence tasks; find reuse | Screens/components inventory, codebase | `plan.md` | `persona-conscious-implementation.md` §1 |
| 4. Persona-conscious implementation | Build honoring the checklist, persona checkpoint per criterion | `constraints.md`, `plan.md` | Code + checkpoint log | `persona-conscious-implementation.md` |
| 5. Verification | Persona × criteria walkthrough; style-guide audit; persona edge cases | Built feature, `constraints.md` | `conformance.md` | `acceptance-verification.md` |
| 6. Release | Per-audience notes, changelog, rollout/flag strategy, post-release checks | `conformance.md`, story | `release-notes.md` | `release-notes-and-rollout.md` |

### Phase 1 — Story Intake & Grooming

| Step | Action | Failure handling |
|------|--------|------------------|
| 1.1 | Load story, its `index.yaml` entry, and every linked persona file | Missing persona → R2 fail |
| 1.2 | Restate the story in one sentence; diff against title for drift | Drift → ambiguity log |
| 1.3 | Classify each acceptance criterion: testable / vague / missing-context | Vague → propose Given/When/Then rewrite |
| 1.4 | Ambiguity sweep: undefined terms, unstated states (empty/error/loading), permission edges | List with proposed defaults; ask user |
| 1.5 | Size check; split XL along criterion or persona seams | Produce child story drafts for user approval |
| 1.6 | Run readiness gate R1–R7 | Any fail → stop with remediation |

### Phase 2 — Constraint Binding

| Step | Action |
|------|--------|
| 2.1 | Locate the style guide (`design/theme/`, `docs/style-guide*`, engine YAML, frontend token config); record what was found or that binding is degraded |
| 2.2 | Extract only constraints *relevant to this story's surface* — tokens, component variants, spacing, motion, tone of copy |
| 2.3 | For each linked persona, derive constraints from technical level, device context, accessibility needs, frustrations |
| 2.4 | Merge by the precedence table; log conflicts and their resolution |
| 2.5 | Emit `constraints.md` from `assets/constraint-checklist-template.md`; freeze it |

### Phase 3 — Implementation Planning

| Step | Action |
|------|--------|
| 3.1 | Map criteria → screens (existing `screens/*.md` or declared net-new) → components → APIs/data |
| 3.2 | Reuse pass: existing components/endpoints that already satisfy a need; extension beats duplication |
| 3.3 | Sequence tasks: data/API → components → screen assembly → states (empty/error/loading) → polish |
| 3.4 | Attach relevant constraint IDs from `constraints.md` to each task |
| 3.5 | Emit `plan.md`; user confirms before build on L-sized stories |

### Phase 4 — Persona-Conscious Implementation

Build task-by-task. At each acceptance criterion boundary, run the checkpoint:

| Checkpoint question | Evidence required |
|--------------------|-------------------|
| Would *each linked persona* succeed at this step unaided? | Walk the flow at their expertise level; note friction |
| Are the constraint IDs attached to this task satisfied? | Tick them in the checkpoint log with file/line evidence |
| Did I introduce anything the style guide doesn't sanction? | New colors/spacing/variants → deviation log entry |
| Are the non-happy paths built (empty, error, loading, denied)? | Each state exists or is explicitly deferred with a log entry |

### Phase 5 — Verification

| Step | Action |
|------|--------|
| 5.1 | Build the persona × criteria matrix (every pair gets a row) |
| 5.2 | Walk each criterion *as each persona* — their device, expertise, patience; record outcome verbatim |
| 5.3 | Style-guide conformance audit against the frozen checklist; every deviation gets verdict justified/fix |
| 5.4 | Persona edge cases: accessibility (keyboard, contrast, screen reader), device (viewport, touch), expertise (no-docs first run) |
| 5.5 | Fix FAILs, re-verify only affected rows; emit `conformance.md` from the template |

### Phase 6 — Release

| Step | Action |
|------|--------|
| 6.1 | Release notes per audience: end users (benefit language, per persona segment), operators/admins (config, migration), developers (API/changelog) |
| 6.2 | Changelog entry (Keep-a-Changelog style: Added/Changed/Fixed) |
| 6.3 | Rollout strategy: direct / flagged / percentage / cohort — chosen by the risk table in `release-notes-and-rollout.md` |
| 6.4 | Post-release validation checklist: smoke path per persona, metrics to watch, rollback trigger |
| 6.5 | Emit `release-notes.md`; tick story criteria checkboxes; hand off notes to trl-marketing / trl-technical-writer if launch content or doc polish is wanted |

## Quick Start Guides

### Ship one story end-to-end
1. `/trl-story-to-release ship US-042`
2. Answer grooming ambiguities when prompted (phase 1)
3. Confirm the constraint checklist and plan (phases 2–3)
4. Review the conformance report; approve waivers if any (phase 5)
5. Receive release notes + rollout plan (phase 6)

### Groom the backlog before a sprint
1. `/trl-story-to-release groom US-010 US-011 US-012`
2. For each story: readiness verdict, ambiguity log, split proposals
3. Fix or park failing stories; only READY stories enter the sprint

### Audit an already-built feature
1. `/trl-story-to-release verify US-042` (skips phases 3–4)
2. Constraint binding runs against the story + style guide (phase 2)
3. Persona × criteria matrix and conformance report produced (phase 5)
4. Fix list ordered by persona impact

## Reference Guide

### When to Read Each Reference

| Task | Read These |
|------|-----------|
| **Grooming / splitting / readiness gating** | `story-intake-and-grooming.md` |
| **Turning a style guide into constraints** | `constraint-binding.md` |
| **Planning + building with persona checkpoints** | `persona-conscious-implementation.md` |
| **Verification matrices and conformance audit** | `acceptance-verification.md` |
| **Release notes, changelog, rollout, flags** | `release-notes-and-rollout.md` |
| **Calibrating on a full example** | `worked-example-dashboard-story.md` |
| **Agent execution of any workflow** | `agent-playbook.claude-code.md` |

All reference paths are relative to `references/`.

## Related Skills

- **trl-user-experience-engineer** — upstream: generates the personas, user stories, screens, and style guides this skill consumes
- **trl-marketing** — downstream: launch announcements and campaigns built from this skill's release notes
- **trl-technical-writer** — downstream: polishes changelogs, release notes, and user-facing docs
- **trl-site-walkthrough** — complementary: persona-driven journey validation of the deployed result

## Bundled Resources

### References
- [agent-playbook.claude-code.md](references/agent-playbook.claude-code.md) — Agent role + 4 executable workflows (groom-story, bind-constraints, implement-story, verify-and-release)
- [story-intake-and-grooming.md](references/story-intake-and-grooming.md) — Readiness gate, ambiguity sweep, story splitting, with worked example
- [constraint-binding.md](references/constraint-binding.md) — Style guide → checklist extraction method, persona-derived constraints, precedence resolution
- [persona-conscious-implementation.md](references/persona-conscious-implementation.md) — Planning method + per-criterion persona checkpoints during build
- [acceptance-verification.md](references/acceptance-verification.md) — Persona × criteria walkthrough matrices, conformance audit, edge-case batteries
- [release-notes-and-rollout.md](references/release-notes-and-rollout.md) — Per-audience notes, changelog format, rollout strategy selection, post-release validation
- [worked-example-dashboard-story.md](references/worked-example-dashboard-story.md) — One story ("first-time admin metrics dashboard") through all 6 phases

### Assets
- [project-tracker.md](assets/project-tracker.md) — Per-story pipeline tracker (phases, artifacts, verdicts)
- [constraint-checklist-template.md](assets/constraint-checklist-template.md) — Fillable phase-2 constraint checklist
- [story-readiness-checklist.md](assets/story-readiness-checklist.md) — R1–R7 gate worksheet for grooming
- [conformance-report-template.md](assets/conformance-report-template.md) — Persona × criteria matrix + style audit report shell
