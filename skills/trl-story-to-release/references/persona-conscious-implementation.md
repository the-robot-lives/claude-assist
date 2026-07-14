# Persona-Conscious Implementation

Phases 3–4: map the story onto screens/components/APIs, sequence the work, then build it with a "would this persona succeed here?" checkpoint at every acceptance-criterion boundary. The frozen constraint checklist (`constraints.md`) rides along the whole way.

## §1 Implementation Planning (Phase 3)

### Surface Mapping

For each acceptance criterion, fill one row before sequencing anything:

| Criterion | Screen (inventory ref or NET-NEW) | Components (reuse / extend / new) | API / data |
|-----------|-----------------------------------|-----------------------------------|------------|

Rules:

| Rule | Why |
|------|-----|
| Screens come from `project-management/screens/*.md`; net-new screens are flagged and described inline | Keeps the inventory the source of truth; suggests an `/extract-screens` refresh upstream |
| Component decisions are three-valued: **reuse** (as-is), **extend** (add prop/variant to existing), **new** (justify why nothing fits) | Extending a documented component beats duplication; "new" without justification is a phase-5 audit flag |
| Every data need names its source (existing endpoint, new endpoint, derived) | Unbudgeted backend work is the top cause of mid-story scope surprise |

### Task Sequencing

Default order — deviations fine, but justify them in `plan.md`:

```
data/API contracts → components (leaf-first) → screen assembly
  → non-happy states (empty / loading / error / denied) → polish (motion, copy pass)
```

| Sequencing rule | Rationale |
|-----------------|-----------|
| Non-happy states are *scheduled tasks*, not leftovers | Persona P-first-run hits the empty state before anything else |
| Each task lists the constraint IDs it must satisfy | Makes phase-4 checkpoints mechanical instead of vibes |
| L-sized stories: user confirms the plan before build | Cheap veto point |

## §2 Building with Persona Checkpoints (Phase 4)

Build task by task. Whenever the running build first satisfies an acceptance criterion, stop and run the checkpoint **once per linked persona**:

### The Checkpoint

| Check | How to evaluate | Record |
|-------|-----------------|--------|
| **Persona walkthrough** | Traverse the flow as the persona: their entry point, viewport/device, expertise (a novice gets no knowledge not on the screen), patience (≤ a few seconds of confusion = friction) | Friction notes, verbatim ("wouldn't know what 'p95' means") |
| **Constraint tick** | Tick this task's constraint IDs with file/line evidence | `PC-2 ✓ EmptyState.tsx:14` |
| **Sanction check** | Any new color/spacing/variant/dependency not in the checklist? | Deviation-log entry (justify or fix now) |
| **State coverage** | Empty / loading / error / denied built for this criterion's surface? | Built, or logged as an explicit deferral |

### Checkpoint Outcomes

| Outcome | Action |
|---------|--------|
| Persona succeeds, constraints tick | Continue to next task |
| Friction, non-blocking | Note it; becomes a phase-5 matrix input and possible follow-up story |
| Persona would fail the criterion | Fix now — this is the cheapest moment; do not defer to phase 5 |
| Constraint conflicts with reality | Deviation log + justification; if unjustifiable, redesign the task |

### Expertise Simulation Cheat Sheet

| Persona level | You must pretend not to know | Failure smell |
|---------------|------------------------------|---------------|
| Novice | Domain jargon, keyboard shortcuts, where settings "usually" are, that hovering reveals things | Tooltip-load-bearing UI; unexplained acronyms; empty state that says only "No data" |
| Intermediate | Internal system names, non-standard gestures | Features findable only via docs |
| Expert | Nothing — but they notice waste | Forced wizards, confirmation nagging, mouse-only paths |

## Worked Example (US-042, abridged)

Surface map:

| Criterion | Screen | Components | API/data |
|-----------|--------|------------|----------|
| AC-1 render 4 metric cards | `07-admin-dashboard.md` | reuse `StyleGuideCard`; extend `MetricTile` (add `unit`, `trend` props); reuse `PageShell` | new `GET /api/admin/metrics/summary` (24h window) |
| AC-2 render ≤2s warm | same | skeleton loaders (reuse `SkeletonCard`) | single batched endpoint, cache 30s |
| AC-3 unavailable state | same | extend `EmptyState` with action slot | endpoint 5xx / partial-null contract |

Task sequence: (1) metrics summary endpoint + contract test → (2) `MetricTile` extension → (3) dashboard assembly in `PageShell` → (4) empty/loading/denied states → (5) copy pass per SG-3 tone.

Checkpoint log excerpt at AC-1:

| Criterion | Persona | Friction noted | Constraints ticked | Deviations |
|-----------|---------|----------------|--------------------|------------|
| AC-1 | P-003 (Dana, novice) | First draft labeled a card "P95 LATENCY" — Dana wouldn't parse it. Relabeled "Slowest responses (p95)" with unit ms. Health verdict added as headline line so the JTBD ("at a glance") survives above the fold. | PC-1 ✓ `MetricTile.tsx:31`; PC-3 ✓ layout at 1366×768; SG-1 ✓ imports; SG-2 ✓ token colors | none |
| AC-3 | P-003 | "No data" alone reproduces Dana's logged frustration. Empty state now: "Metrics are still warming up — data appears within a minute. Check collector status →" | PC-2 ✓ `EmptyState.tsx:14` | Wanted amber `#f59e0b` for the warming state — not in tokens. Logged; used existing `warning` semantic token instead. Deviation avoided. |

> Continue with phase 5 in `acceptance-verification.md`; full end-to-end run in `worked-example-dashboard-story.md`.
