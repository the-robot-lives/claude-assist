---
id: M0
name: "Foundation: Graph Studio & Battle Engine"
sequence: 0
depends_on: []
lanes: 4
stories: [US-001, US-002, US-003, US-005, US-006, US-015, US-017, US-020, US-061, US-062, US-064, US-071, US-073, US-074, US-087]
---

# M0 — Foundation: Graph Studio & Battle Engine

The origin milestone. It freezes the JSON fighter-graph schema, ships the visual Fighter
Studio editor, delivers the deterministic server-side battle engine, and establishes the
design-system and fairness baselines that every later milestone inherits. Nothing else in the
product can exist until a graph can be authored, saved, and resolved into a battle.

## Entry criteria

- None — this is the sequence's origin point.

## Exit criteria

- The graph schema is frozen: `contracts/graph-schema/graph.schema.json` file exists and
  `npm run validate:schema` exits 0 against the 20+ node-type registry.
- The Fighter Studio round-trips a graph: `npm run test:studio` exits 0, covering create,
  edit, node search, manual positioning, save/restore, and session resume.
- The battle engine is deterministic: `cargo test -p engine` exits 0, and the determinism
  test proves identical `(graph, seed)` inputs yield byte-identical replay output.
- Fairness holds: the engine resolves a battle from the graph alone with no energy gate and no
  purchasable power — `cargo test -p engine fairness::` exits 0.
- The design-system baseline is enforced: `npm run test:a11y-baseline` exits 0 for 48px touch
  targets, reduced-motion, non-color node-state, and color-vision-safe tokens.
- All 15 stories in this milestone have their acceptance criteria checked off.

## Transition checklist

- [ ] `contracts/graph-schema/graph.schema.json` exists and `npm run validate:schema` exits 0
- [ ] `npm run test:studio` exits 0 (create/edit/search/position/save/restore/resume)
- [ ] `cargo test -p engine` exits 0 including the determinism test
- [ ] `cargo test -p engine fairness::` exits 0 (graph-only resolution, no energy, no pay-to-win)
- [ ] `npm run test:a11y-baseline` exits 0
- [ ] All 15 M0 stories' acceptance criteria checked off
- [ ] M1 Entry criteria reviewed and satisfied

## Worker lanes

### L0.A — Graph Contract & Data Model
- **Zone / exclusive paths:** `contracts/graph-schema/`, `contracts/api/graph/`
- **Mission:** Define and freeze the JSON fighter-graph format, the node-type registry, and the
  export/import + obfuscation contract that every other lane and milestone consumes.
- **Tasks:**
  - T0.A.1 — Author `graph.schema.json` with the 20+ perception/decision/modifier/action node
    types and validation rules (US-001).
  - T0.A.2 — Specify the export/import file format, device-portable, with an optional
    logic-obfuscation flag that preserves shareability without revealing core logic (US-003, US-017).
  - T0.A.3 — Publish the frozen schema version + changelog; downstream changes go through a
    contract-RFC.
- **Stories delivered:** US-001, US-003, US-017
- **Contracts:** provides `graph.schema.json` [graph contract] + export/import format,
  consumed by L0.B, L0.C, and every later milestone. Consumes: none.

### L0.B — Fighter Studio Client
- **Zone / exclusive paths:** `client/studio/`
- **Mission:** Ship the visual node editor — the make-or-break mobile graph-editing surface —
  with authoring, explainability, versioning, and resumable sessions.
- **Tasks:**
  - T0.B.1 — Node canvas with drag/manual positioning and node search-by-name/function
    (US-087, US-015).
  - T0.B.2 — Per-choice explainability panel surfacing why each node/decision was made,
    reading the engine decision-trace format (US-002).
  - T0.B.3 — Save/restore of previous graph versions and session-resumable editing state
    (US-006, US-062).
- **Stories delivered:** US-002, US-006, US-015, US-062, US-087
- **Contracts:** provides the Studio save/load calls [studio↔graph]. Consumes: L0.A graph
  contract, L0.D design tokens, L0.C decision-trace format.

### L0.C — Battle Engine & Fairness
- **Zone / exclusive paths:** `engine/`
- **Mission:** Deterministic, cheat-resistant, async-compatible server-side simulation that
  resolves a battle purely from graph definitions and emits a replay + decision trace.
- **Tasks:**
  - T0.C.1 — Deterministic `(graph, seed) → replay` simulation with a byte-identical
    determinism test (US-061).
  - T0.C.2 — Emit the decision-trace format (chosen action + reason + confidence per tick)
    consumed by Studio and the replay viewer (supports US-002).
  - T0.C.3 — Enforce fairness: resolution reads the graph only, with no energy system and no
    purchasable power (US-005, US-064).
- **Stories delivered:** US-005, US-061, US-064
- **Contracts:** provides the battle-result + decision-trace format [replay contract], consumed
  by M1 replay viewer and all later replay/analytics work. Consumes: L0.A graph contract.

### L0.D — Design-System Baseline
- **Zone / exclusive paths:** `client/design-system/`
- **Mission:** Establish the "Neural Neon" token set and the accessibility baselines every
  screen in every later milestone must inherit.
- **Tasks:**
  - T0.D.1 — Token set (color/type/spacing) with color-vision-safe semantic pairs (US-020).
  - T0.D.2 — 48px minimum touch-target primitives and a reduced-motion mode wired to all
    motion tokens (US-073, US-074).
  - T0.D.3 — Non-color node-state indicators (shape/label/icon) for graph nodes (US-071).
- **Stories delivered:** US-020, US-071, US-073, US-074
- **Contracts:** provides the design-token + a11y-primitive library [design-system contract],
  consumed by every client lane in M1–M4. Consumes: none.

## Cross-lane integration tasks

- T0.X.1 (owned by L0.C) — End-to-end foundation proof: a graph authored in the Studio (L0.B)
  and saved via the L0.A schema is resolved by the L0.C engine into a replay whose decision
  trace renders back in the Studio explainability panel, with all UI honoring L0.D tokens.
  Gate: `npm run test:e2e:foundation` exits 0.
