# M6 — Collaboration & Sharing

Objective: Turn HoloGraph from a single-user tool into a shared review surface. This milestone builds multi-user presence and cursors on the `graph:doc:*` channel, share links with permission scopes, anchored annotations/callouts and comment threads, presentation mode with cycle highlighting for reviews, recorded fly-through tours, saved review sessions, before/after refactor comparison, and exportable model-file sharing. It builds directly on the M3 patch protocol and channel echo (single-user), extending them to multi-user. Parallel track C, running after M3 alongside M4 and M5; it is the prerequisite for M10 onboarding/polish.

## Entry criteria

- `M3 exit`: patch protocol, versioning, authoring verbs, single-user `graph:doc:*` echo, and the M2 cycle detection are live.
- M0 channel protocol (`doc:join/leave`, `patch:apply/reject`, `cursor:move`, `presence:state`) is in force and extended here.
- Cross-cutting a11y constraints from M3 apply: collab UI (annotations, comments, share dialog, presentation controls) must be keyboard-reachable and use non-color status feedback; tour playback must respect reduced-motion.

## Gate tasks

- **M6-GATE-01** (BE-CORE) — Freeze share-link + permission model. Token, scope (`view | comment | edit | read-only`), and expiry, mapping to shareable and read-only links. Scope is enforced on both channel join and REST. `depends: M3 exit` `size: M` `stories: US-037, US-048`
- **M6-GATE-02** (BE-CORE + BE-RT) — Freeze annotation/comment/callout data model + channel event additions. Element-anchored annotations, callouts, and comment threads; new events `annotation:*`, `comment:*`, and multi-user `presence:*`/`cursor:*` extending the M0 channel protocol. `depends: M3 exit` `size: M` `stories: US-038, US-045, US-055`
- **M6-GATE-03** (BE-CORE) — Freeze review-session + tour-recording format. Review session = named snapshot of view state + annotations; tour = a camera keyframe track; before/after = two model-state references + a diff pointer. `depends: M3 exit` `size: S` `stories: US-046, US-041, US-047`

## Lanes & tasks

### BE-RT — realtime (`backend/lib/holograph_web/channels/`, presence)

- **M6-BE-RT-01** — Multi-user presence + cursors. Presence state and live cursors over `graph:doc:*`, extending the single-user M3 channel to N participants. `depends: M6-GATE-02` `size: M` `stories: US-037`
- **M6-BE-RT-02** — Annotation/comment realtime sync. Broadcast annotation, callout, and comment operations with consistent ordering. `depends: M6-GATE-02` `size: M` `stories: US-038, US-045, US-055`
- **M6-BE-RT-03** — Presentation/follow-mode broadcast. Presenter camera and highlight state broadcast to following viewers. `depends: M6-GATE-02` `size: M` `stories: US-040`

### BE-CORE — domain model + persistence (`backend/lib/holograph/{docs,graph}/`, `db/changelog/`)

- **M6-BE-CORE-01** — Share links + permissions. Persist tokens; enforce scope on join and patch. `depends: M6-GATE-01` `size: M` `stories: US-037, US-048`
- **M6-BE-CORE-02** — Annotations, callouts, comment threads. Persist element-anchored notes/callouts and threaded comments, versioned with the document. `depends: M6-GATE-02` `size: L` `stories: US-038, US-045, US-055`
- **M6-BE-CORE-03** — Review sessions. Save and share a named session (view state + annotations). `depends: M6-GATE-03, M6-BE-CORE-02` `size: M` `stories: US-046`
- **M6-BE-CORE-04** — Before/after refactor snapshot. Capture two model states + a diff reference for comparison. `depends: M6-GATE-03` `size: M` `stories: US-047`
- **M6-BE-CORE-05** — Exportable model file. Serialize a document to a shareable `.trd-yaml`/model file and re-import it. `depends: M3 exit` `size: M` `stories: US-085`

### BE-API — REST surface (`backend/lib/holograph_web/{controllers,plugs}/`)

- **M6-BE-API-01** — Share-link CRUD + permission endpoints. Create/revoke links, resolve scope. `depends: M6-BE-CORE-01` `size: M` `stories: US-037, US-048`
- **M6-BE-API-02** — Annotation/comment REST. List/create/resolve annotations, callouts, and threads (async review path). `depends: M6-BE-CORE-02` `size: M` `stories: US-038, US-045, US-055`
- **M6-BE-API-03** — Review-session + model-file endpoints. Save/open sessions; export/import the model file. `depends: M6-BE-CORE-03, M6-BE-CORE-05` `size: M` `stories: US-046, US-085`

### FE-COLLAB — realtime client + collab UI (`frontend/src/lib/realtime/`, `frontend/src/components/collab/`)

- **M6-FE-COLLAB-01** — Realtime client (presence/cursors). Join via a share link; render presence avatars and live cursors. `depends: M6-BE-RT-01` `size: L` `stories: US-037`
- **M6-FE-COLLAB-02** — Annotation & callout UI. Create and anchor notes/callouts on regions and elements. `depends: M6-BE-RT-02, M6-BE-API-02` `size: L` `stories: US-038`
- **M6-FE-COLLAB-03** — Comment threads UI. Anchored threads with async resolve. `depends: M6-BE-API-02` `size: M` `stories: US-045`
- **M6-FE-COLLAB-04** — Findings annotations. Persisted node-level findings for the reverse-engineering workflow. `depends: M6-FE-COLLAB-02` `size: S` `stories: US-055`
- **M6-FE-COLLAB-05** — Read-only viewer mode. Enforce read-only scope in the UI (no verb rail, no patches). `depends: M6-BE-API-01` `size: S` `stories: US-048`

### FE-SHELL — app UX, non-3D UI (`frontend/src/app/`, `.../components/`)

- **M6-FE-SHELL-01** — Share dialog. Generate/copy a link and pick a scope. `depends: M6-BE-API-01` `size: M` `stories: US-037, US-048`
- **M6-FE-SHELL-02** — Presentation mode. Clean chrome for screensharing; follow the presenter. `depends: M6-BE-RT-03` `size: M` `stories: US-040`
- **M6-FE-SHELL-03** — Cycle highlight for review. Reuse M2 cycle detection as a review-presentation overlay. `depends: M2 exit` `size: S` `stories: US-039`
- **M6-FE-SHELL-04** — Review-session save/open UI. `depends: M6-BE-API-03` `size: S` `stories: US-046`
- **M6-FE-SHELL-05** — Model-file share/open UI. `depends: M6-BE-API-03` `size: S` `stories: US-085`

### FE-GL — WebGL renderer (`frontend/src/renderer/`)

- **M6-FE-GL-01** — Tour recording + playback. Record camera keyframes and replay a guided fly-through (reduced-motion aware). `depends: M6-GATE-03` `size: M` `stories: US-041`
- **M6-FE-GL-02** — Before/after diff rendering. Visualize two model states (overlay or side-by-side) driving off the snapshot diff. `depends: M6-BE-CORE-04` `size: M` `stories: US-047`

### QA — e2e + fixtures (`frontend/cypress/`, `backend/test/integration/`)

- **M6-QA-01** — Multi-client collab e2e. Two clients: presence, annotation sync, comment threads. `depends: M6-INT-01` `size: L` `stories: US-037, US-038, US-045`
- **M6-QA-02** — Permission/read-only tests. Scope enforcement across REST and channel. `depends: M6-BE-API-01, M6-FE-COLLAB-05` `size: M` `stories: US-048`
- **M6-QA-03** — Presentation/tour/session tests. Presentation follow, tour record/replay, session save/open. `depends: M6-INT-02, M6-INT-03` `size: M` `stories: US-040, US-041, US-046`

## Integration & exit criteria

- **M6-INT-01** (BE-RT + FE-COLLAB) — Live shared session. Link → join → presence/cursors → annotate → comment → persisted findings. `stories: US-037, US-038, US-045, US-055`
- **M6-INT-02** (BE-CORE + FE-SHELL) — Presentation + review session + cycle highlight. Enter presentation mode, highlight cycles, save a review session. `stories: US-039, US-040, US-046`
- **M6-INT-03** (FE-GL + BE-CORE) — Tour record/replay + before/after. Record a fly-through, replay it, compare a refactor before/after. `stories: US-041, US-047`
- **M6-INT-04** (BE-CORE + FE-SHELL) — Model-file share/open + read-only. Export a model file, open it, and share a read-only view. `stories: US-048, US-085`

Exit criteria:

- Two users share a live model view by link (US-037), annotate regions and anchor comment threads (US-038, US-045), and reverse-engineering findings persist on nodes (US-055).
- A reviewer enters presentation mode (US-040), highlights cycles (US-039), records/replays a guided tour (US-041), saves a review session (US-046), and compares a refactor before/after (US-047).
- Read-only shared views cannot be edited (US-048); a model file can be shared and opened (US-085).
- Each story has at least one test; multi-user paths are covered by the two-client e2e; a11y constraints hold on all collab UI.

Demo script: create a share link → a second client joins → presence and cursors appear → annotate a region and start a comment thread → enter presentation mode and highlight cycles → record a fly-through and replay it → save the review session → export a model file and open it read-only.

## Parallelization notes

- Supports ~6-7 concurrent workers: BE-RT, BE-CORE, BE-API, FE-COLLAB (may be a pair), FE-SHELL, FE-GL, QA. BE-ING/BE-INT/BE-AI have no work here.
- Gate tasks land first: GATE-01 unblocks permissions; GATE-02 unblocks the realtime + annotation lanes; GATE-03 unblocks sessions/tours/before-after.
- Lane isolation: BE-RT owns channels/presence, BE-CORE owns persistence, FE-COLLAB owns `realtime/`+`components/collab/`, FE-SHELL owns app chrome (share dialog, presentation, session/file UI), FE-GL owns camera tour + diff rendering. FE-COLLAB and FE-SHELL are kept in separate component subtrees to avoid collisions.
- Merge order: gates → BE-RT + BE-CORE in parallel → BE-API → FE lanes → integration. FE-SHELL-03 (cycle highlight) depends only on M2 and can start immediately.
- US-039 reuses the M2 cycle-detection output rather than recomputing it.

## Stories delivered

| ID | Priority | Persona | Title |
|----|----------|---------|-------|
| US-037 | P0 | Priya (tech lead) | Share a live model view by link |
| US-038 | P1 | Priya (tech lead) | Annotate a region with notes and callouts |
| US-039 | P1 | Priya (tech lead) | Highlight cycles for a review presentation |
| US-040 | P1 | Priya (tech lead) | Enter a clean presentation mode for screensharing |
| US-045 | P1 | Priya (tech lead) | Anchor comment threads to elements for async review |
| US-055 | P1 | Sven (reverse-engineer) | Annotate findings on nodes that persist |
| US-085 | P1 | Elena (CS educator) | Share a model file students can open and explore |
| US-041 | P2 | Priya (tech lead) | Record a guided fly-through tour to replay |
| US-046 | P2 | Priya (tech lead) | Save and share a named review session |
| US-047 | P2 | Priya (tech lead) | Show a before/after of a proposed refactor |
| US-048 | P3 | Priya (tech lead) | Share a read-only view that viewers can't edit |
