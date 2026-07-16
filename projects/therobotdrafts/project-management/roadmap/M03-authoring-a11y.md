# M3 — Authoring, Persistence & Core Accessibility

**Objective.** Make the model editable and accessible. Introduce server-authoritative mutation on the
patch protocol (single-user first, echoed over the `graph:doc:*` channel to seed M6 collaboration),
the authoring command surface (persistent verb rail, hover/tooltips, empty-canvas prompt, full
keyboard command map), edit gizmos with re-parent and refactor-impact preview and manual-layout
pinning, persistence of named views / bookmarks / teaching examples, and the P0 accessibility baseline
— keyboard-drivable verbs, non-color kind/edge encoding, non-color status feedback, and a
reduced-motion mode. From M3's exit the a11y baseline is a standing definition-of-done constraint, and
the project fans out into three independent tracks (M4 ingestion, M5 projection, M6 collaboration).

## Entry criteria

- M2 exit: comprehension tools (traversal, cycles, metrics, search/filter) are live; selection and
  drill work; the compass/breadcrumb orientation aids exist.
- M0 contracts available: patch-operation format (M0-BE-CORE-02) and channel protocol `graph:doc:*`
  (M0-BE-RT-01) are frozen; the start-app channel scaffold is present.
- Authoring semantics reference: `docs/specs/authoring-ux.md` (verb set, spring-loaded modes, parity
  matrix, reserved UI-state channel) and `docs/specs/design-conventions.md` (kind palette, edge
  styles). The packer owns position — placement is "pick the parent," not "pick a coordinate"
  (ADR-003) — which shapes re-parent and manual-pin design.

## Gate tasks

Two front-loaded gates unblock the milestone's two halves — mutation and accessibility:

- **M3-BE-CORE-01 — Finalize patch apply/validate semantics.** Server-authoritative apply against the
  M0 patch format: legality checks with human-readable reasons (porting the Unity `Authoring/Rules`
  concept), one op-batch = one version bump = one undo step, structured reject payload. Unblocks BE-RT
  and every client edit flow. `depends: M2 exit` · `size: L` · `stories: —`
- **M3-FE-SHELL-01 — Freeze the non-color encoding + UI-state token map.** Kind/edge glyph-and-shape
  vocabulary and the reserved UI-state channel (active / sticky / disabled / success / reject /
  pending) drawn from `@noizu/styleguide` tokens and authoring-ux §5.1. Unblocks FE-GL rendering and
  all authoring feedback. `depends: M2 exit` · `size: M` · `stories: US-097`

## Lanes & tasks

### BE-CORE — domain model + persistence

- **M3-BE-CORE-01 — (gate) patch apply/validate + versioning.** See Gate tasks; exposes
  `POST /api/v1/docs/:id/patches`. `size: L` · `stories: —`
- **M3-BE-CORE-02 — Patch log table.** `collab_events` append log of applied/rejected patches per
  document version (introduced here even single-user; the substrate M6 multi-user builds on).
  `depends: M3-BE-CORE-01` · `size: S` · `stories: —`
- **M3-BE-CORE-03 — Named views + bookmarks.** Persist named architecture views (camera pose + filter
  + highlight state) and per-node bookmarks; list/restore API. `depends: M2 exit` · `size: M`
  · `stories: US-015, US-035`
- **M3-BE-CORE-04 — Teaching examples.** Save a document as a canonical, named teaching example that
  can be reopened and shared read-only in later milestones. `depends: M3-BE-CORE-03` · `size: S`
  · `stories: US-084`

### BE-RT — realtime

- **M3-BE-RT-01 — Channel patch echo (single-user).** `graph:doc:*` handles `patch:apply` →
  BE-CORE validate/apply → broadcast the applied patch (or `patch:reject`) back to the joined session;
  single-user now, presence/cursors deferred to M6. `depends: M3-BE-CORE-01` · `size: M`
  · `stories: —`

### FE-SHELL — app UX, non-3D UI, API client

- **M3-FE-SHELL-01 — (gate) non-color encoding + UI-state token map.** See Gate tasks. `size: M`
  · `stories: US-097`
- **M3-FE-SHELL-02 — Persistent verb rail.** Left rail exposing Select / Add-node / Connect / Delete /
  Undo / Redo / Project→2D, with active/sticky/disabled state per the UI-state channel (authoring-ux
  §2.2). `depends: M3-FE-SHELL-01` · `size: M` · `stories: US-031`
- **M3-FE-SHELL-03 — Hover highlight + tooltips.** Reveal available actions on hover with tooltips
  that also teach the keyboard path. `depends: M3-FE-SHELL-02` · `size: S` · `stories: US-030`
- **M3-FE-SHELL-04 — Empty-canvas prompt.** First-element prompt on an empty document, guiding the
  user to create their first node. `depends: M3-FE-SHELL-02` · `size: S` · `stories: US-021`
- **M3-FE-SHELL-05 — Keyboard command map.** Every authoring verb keyboard-drivable — `N`, `C`,
  `Del`/`Backspace`, `Ctrl/⌘+Z`, `Ctrl/⌘+Shift+Z`, `P`, `F2`, `Esc` — plus keyboard selection/drill
  focus traversal so no verb requires the mouse. `depends: M3-FE-SHELL-02` · `size: M`
  · `stories: US-096`
- **M3-FE-SHELL-06 — Non-color kind/edge encoding.** Apply the frozen glyph/shape/label encoding so
  every element kind and edge type is distinguishable without color. `depends: M3-FE-SHELL-01`
  · `size: M` · `stories: US-097`
- **M3-FE-SHELL-07 — Non-color status feedback.** Success / reject / pending action feedback conveyed
  by icon + text + motion state, never color alone; consumes the patch-reject payload.
  `depends: M3-FE-SHELL-01, M3-BE-RT-01` · `size: S` · `stories: US-100`
- **M3-FE-SHELL-08 — Reduced-motion mode.** A toggle (honoring `prefers-reduced-motion`) that swaps
  camera/gizmo animations for instant transitions everywhere. `depends: M3-FE-SHELL-02` · `size: M`
  · `stories: US-098`

### FE-GL — WebGL renderer

- **M3-FE-GL-01 — Edit gizmos.** Add-into-parent, connect-drag, and delete gizmos rendered and
  picked, issuing patches through the channel/REST flow; honors spring-loaded one-shot vs sticky
  modes. `depends: M3-BE-RT-01, M3-FE-SHELL-01` · `size: L` · `stories: US-030, US-031`
- **M3-FE-GL-02 — Re-parent preview.** Dragging a node into a new container previews the packer's
  re-pack (parent-owns-position) before commit. `depends: M3-FE-GL-01, M3-FE-GRAPH-01` · `size: M`
  · `stories: US-018`
- **M3-FE-GL-03 — Refactor impact preview.** Ghost/highlight the elements a pending edit would affect
  before committing. `depends: M3-FE-GL-01, M3-FE-GRAPH-01` · `size: M` · `stories: US-044`
- **M3-FE-GL-04 — Manual layout pinning.** Pin a manually-placed node/region so re-packs preserve its
  placement (needed for imported diagrams whose layout is authored, not derived).
  `depends: M3-FE-GL-01, M3-FE-GRAPH-01` · `size: M` · `stories: US-068`

### FE-GRAPH — graph/layout algorithms (pure TS)

- **M3-FE-GRAPH-01 — Incremental re-pack + impact set.** Re-pack a subtree on a containment change and
  compute the affected-element set, feeding the FE-GL previews and the committed apply. Owned here
  because it is sphere-packing work. `depends: M2 exit` · `size: M`
  · `stories: US-018, US-044, US-068`

### QA — e2e + fixtures + harness

- **M3-QA-01 — Authoring e2e.** Verb rail actions, add/connect/delete/undo/redo via patch flow,
  re-parent preview → commit, refactor-impact preview, manual pin survives re-pack, save + restore a
  named view and a bookmark, save a teaching example. `depends: M3-INT-01, M3-INT-02` · `size: M`
  · `stories: US-015, US-018, US-021, US-030, US-031, US-035, US-044, US-068, US-084`
- **M3-QA-02 — Accessibility gate.** Keyboard-only authoring session completes every verb;
  `cypress-axe`/equivalent asserts non-color encoding presence, keyboard reachability, and that
  reduced-motion removes animated transitions. This suite becomes the standing a11y gate for M4+.
  `depends: M3-INT-03` · `size: M` · `stories: US-096, US-097, US-098, US-100`

## Integration & exit criteria

- **M3-INT-01 — Patch round trip.** Edit in the client → patch → BE-CORE validate/apply/version →
  `graph:doc:*` echo → re-render, with a reject surfaced as non-color status feedback. Joins
  **BE-CORE + BE-RT + FE-GL + FE-SHELL**. `depends: M3-FE-GL-01, M3-BE-RT-01, M3-FE-SHELL-07`
  · `size: M`
- **M3-INT-02 — Persistence round trip.** Save and restore a named view, a bookmark, and a teaching
  example. Joins **BE-CORE + FE-SHELL**. `depends: M3-BE-CORE-03, M3-BE-CORE-04, M3-FE-SHELL-02`
  · `size: S`
- **M3-INT-03 — A11y baseline lock-in.** A keyboard-only, reduced-motion, non-color-verified authoring
  session passes; this becomes the cross-cutting acceptance constraint enforced on every subsequent
  milestone. Joins **QA + FE-SHELL + FE-GL**. `depends: M3-FE-SHELL-05, M3-FE-SHELL-06,
  M3-FE-SHELL-08` · `size: M`
- **Demo script:** open an empty doc → follow the first-element prompt → create a node from the verb
  rail, then repeat entirely by keyboard → connect two nodes → hover to reveal actions → re-parent a
  module and preview the re-pack → preview a refactor's impact → pin a manually-placed node → undo/redo
  → save a named view and a bookmark → toggle reduced motion and confirm instant transitions → force a
  reject and confirm non-color status feedback.
- **Story acceptance checklist:** all 13 M3 stories demonstrable and each covered by at least one test.
- **Exit unlocks fan-out:** M4, M5, and M6 may now run as independent milestone tracks (each still
  internally lane-parallel). The a11y baseline is henceforth part of definition-of-done, not a
  milestone to revisit — M10 only *polishes* it (contrast themes, monochrome mode, coachmarks).

## Parallelization notes

- **Worker count: 6–7** (BE-CORE, BE-RT, FE-SHELL, FE-GL, FE-GRAPH, QA — with FE-SHELL optionally a
  worker pair).
- **Two front-loaded gates split the milestone.** M3-BE-CORE-01 (patch semantics) unblocks BE-RT and
  every edit gizmo; M3-FE-SHELL-01 (encoding + UI-state token map) unblocks FE-GL rendering and all
  authoring feedback. Both are the first thing their lane does.
- **The one shared-lane case.** FE-SHELL is the heaviest lane (seven tasks) and splits cleanly into two
  non-colliding sub-tracks a worker pair can own concurrently: an **authoring-surface** sub-track
  (rail / tooltips / empty-canvas prompt / keyboard map — M3-FE-SHELL-02..05) and an **a11y-encoding**
  sub-track (encoding / status feedback / reduced-motion — M3-FE-SHELL-01, 06, 07, 08). They touch
  different components under `frontend/src/components/` and `frontend/src/app/`; assign files at the
  gate so the pair never edits the same file. All other lanes have single-owner directories as in M1/M2.
- **Lane isolation.** BE-CORE owns `backend/lib/holograph/{docs,graph,draft}/` + changelog; BE-RT owns
  `backend/lib/holograph_web/channels/`; FE-GL owns `frontend/src/renderer/`; FE-GRAPH owns
  `frontend/src/graph/`; QA owns `cypress/` + `backend/test/integration/`.
- **Merge order:** gates (M3-BE-CORE-01, M3-FE-SHELL-01) → BE-RT + FE-GL edit + FE-GRAPH re-pack +
  FE-SHELL sub-tracks + BE-CORE persistence → M3-INT-01 / 02 / 03 → QA suites.

## Stories delivered

| ID | Priority | Persona | Title |
|------|------|---------|-------|
| US-015 | P1 | Dana | Save named architecture views and bookmarks |
| US-018 | P2 | Dana | Re-parent a module in-model and preview the impact |
| US-021 | P1 | Marcus | Prompt the first element on an empty canvas |
| US-030 | P0 | Marcus | Reveal actions through hover highlight and tooltips |
| US-031 | P0 | Marcus | Show a persistent verb rail of available actions |
| US-035 | P2 | Marcus | Bookmark a node to return to it later |
| US-044 | P1 | Priya | Preview a refactor's dependency impact before committing |
| US-068 | P2 | Robert | Preserve manually-placed diagram layout |
| US-084 | P2 | Elena | Build and save canonical teaching examples |
| US-096 | P0 | Theo | Drive every authoring verb from the keyboard |
| US-097 | P0 | Theo | Encode every kind and edge type beyond color |
| US-098 | P0 | Theo | Use a reduced-motion mode with instant transitions |
| US-100 | P1 | Theo | Get non-color status feedback for actions |
