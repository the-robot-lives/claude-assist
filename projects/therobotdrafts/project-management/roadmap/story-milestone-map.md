# Story → Milestone Map

Every one of the 100 user stories mapped to the milestone that delivers it. Titles are verbatim from
`project-management/user-stories/index.yaml`. Milestone assignments are fixed by the roadmap brief —
stories are not moved. See [`README.md`](./README.md) for the milestone definitions and dependency
DAG.

## Persona legend

| Name | ID | Slug | Segment |
|------|----|------|---------|
| Dana | P-001 | trd-systems-architect | primary |
| Marcus | P-002 | trd-onboarding-engineer | primary |
| Priya | P-003 | trd-tech-lead | secondary |
| Sven | P-004 | trd-reverse-engineer | secondary |
| Robert | P-005 | trd-legacy-modeler | secondary |
| Aiko | P-006 | trd-vr-explorer | secondary |
| Elena | P-007 | trd-cs-educator | tertiary |
| ARIA | P-008 | trd-automation-agent | edge-case |
| Theo | P-009 | trd-accessibility-first-dev | edge-case |

## Full story map (sorted by story ID)

| ID | Title | Persona | Epic | Priority | Milestone |
|----|-------|---------|------|----------|-----------|
| US-001 | Reverse-engineer a monorepo into a bubble model | Dana | Ingestion & reverse-engineering | P0 | M4 |
| US-002 | Frame the whole-system overview | Dana | Bubble navigation & orientation | P0 | M1 |
| US-003 | Trace a service's inbound and outbound dependencies | Dana | Bubble navigation & orientation | P0 | M2 |
| US-004 | Detect and highlight dependency cycles | Dana | Bubble navigation & orientation | P1 | M2 |
| US-005 | Drill from system overview to a single function and back | Dana | Bubble navigation & orientation | P0 | M1 |
| US-006 | Project a subsystem region to a UML component diagram | Dana | Diagram coverage & projection-to-2D | P0 | M5 |
| US-007 | Export a projected diagram to PlantUML | Dana | Interchange (XMI/Rose/EA/PlantUML import-export) | P1 | M5 |
| US-008 | Search a type by qualified name and focus it | Dana | Search & filter | P0 | M2 |
| US-009 | Filter the model by language, layer, or package | Dana | Search & filter | P1 | M2 |
| US-010 | Re-ingest changed code to keep the model live | Dana | Ingestion & reverse-engineering | P1 | M4 |
| US-011 | Navigate a million-element graph at interactive frame rates | Dana | Performance & scale | P1 | M8 |
| US-012 | Trace a call path across service and language boundaries | Dana | Bubble navigation & orientation | P0 | M2 |
| US-013 | Color nodes by a structural metric to spot bottlenecks | Dana | Search & filter | P1 | M2 |
| US-014 | Compare two model versions to see structural drift | Dana | Performance & scale | P2 | M7 |
| US-015 | Save named architecture views and bookmarks | Dana | Persistence & document management | P1 | M3 |
| US-016 | Project a deployment diagram of services | Dana | Diagram coverage & projection-to-2D | P2 | M5 |
| US-017 | Export a high-resolution render of a region | Dana | Interchange (XMI/Rose/EA/PlantUML import-export) | P1 | M5 |
| US-018 | Re-parent a module in-model and preview the impact | Dana | Authoring (add/connect/edit/re-parent) | P2 | M3 |
| US-019 | Offer an 'Import a repo' call-to-action on first run | Marcus | Onboarding & first-run | P0 | M1 |
| US-020 | Teach the core verbs with a one-time coachmark overlay | Marcus | Onboarding & first-run | P1 | M10 |
| US-021 | Prompt the first element on an empty canvas | Marcus | Onboarding & first-run | P1 | M3 |
| US-022 | Orbit the whole system to survey its clusters | Marcus | Bubble navigation & orientation | P0 | M1 |
| US-023 | Focus and frame the selected node with F | Marcus | Bubble navigation & orientation | P0 | M1 |
| US-024 | Keep node labels legible when zoomed out | Marcus | Performance & scale | P0 | M1 |
| US-025 | Recenter to recover from being lost in space | Marcus | Bubble navigation & orientation | P0 | M1 |
| US-026 | Search a class by name and jump to it | Marcus | Search & filter | P0 | M2 |
| US-027 | Trace the callers of a class to scope a bug | Marcus | Bubble navigation & orientation | P0 | M2 |
| US-028 | Distinguish core modules from peripheral ones | Marcus | Search & filter | P1 | M2 |
| US-029 | Show a compass/horizon orientation gizmo | Marcus | Bubble navigation & orientation | P1 | M2 |
| US-030 | Reveal actions through hover highlight and tooltips | Marcus | Authoring (add/connect/edit/re-parent) | P0 | M3 |
| US-031 | Show a persistent verb rail of available actions | Marcus | Authoring (add/connect/edit/re-parent) | P0 | M3 |
| US-032 | Show a breadcrumb of the current drill location | Marcus | Bubble navigation & orientation | P1 | M2 |
| US-033 | Open the code behind a bubble in my editor | Marcus | Code round-trip & LLM codegen | P1 | M4 |
| US-034 | Read a class's members in a detail panel | Marcus | Bubble navigation & orientation | P1 | M1 |
| US-035 | Bookmark a node to return to it later | Marcus | Persistence & document management | P2 | M3 |
| US-036 | Take a guided fly-through of a subsystem | Marcus | Onboarding & first-run | P2 | M10 |
| US-037 | Share a live model view by link | Priya | Collaboration / sharing / annotation | P0 | M6 |
| US-038 | Annotate a region with notes and callouts | Priya | Collaboration / sharing / annotation | P1 | M6 |
| US-039 | Highlight cycles for a review presentation | Priya | Collaboration / sharing / annotation | P1 | M6 |
| US-040 | Enter a clean presentation mode for screensharing | Priya | Collaboration / sharing / annotation | P1 | M6 |
| US-041 | Record a guided fly-through tour to replay | Priya | Collaboration / sharing / annotation | P2 | M6 |
| US-042 | Project a region for a non-technical audience | Priya | Diagram coverage & projection-to-2D | P1 | M5 |
| US-043 | Export an annotated view to PNG/PDF | Priya | Interchange (XMI/Rose/EA/PlantUML import-export) | P2 | M5 |
| US-044 | Preview a refactor's dependency impact before committing | Priya | Authoring (add/connect/edit/re-parent) | P1 | M3 |
| US-045 | Anchor comment threads to elements for async review | Priya | Collaboration / sharing / annotation | P1 | M6 |
| US-046 | Save and share a named review session | Priya | Persistence & document management | P2 | M6 |
| US-047 | Show a before/after of a proposed refactor | Priya | Collaboration / sharing / annotation | P2 | M6 |
| US-048 | Share a read-only view that viewers can't edit | Priya | Collaboration / sharing / annotation | P3 | M6 |
| US-049 | Decompile a JAR into a navigable bubble model | Sven | Ingestion & reverse-engineering | P0 | M7 |
| US-050 | Recover a native binary's call graph | Sven | Ingestion & reverse-engineering | P1 | M7 |
| US-051 | Unify mixed artifact types into one code-graph | Sven | Ingestion & reverse-engineering | P1 | M4 |
| US-052 | Trace every path that reaches a sensitive module | Sven | Bubble navigation & orientation | P0 | M2 |
| US-053 | Identify external entry points and trust boundaries | Sven | Search & filter | P1 | M4 |
| US-054 | Lift bytecode toward readable source | Sven | Code round-trip & LLM codegen | P1 | M7 |
| US-055 | Annotate findings on nodes that persist | Sven | Collaboration / sharing / annotation | P1 | M6 |
| US-056 | Handle stripped and obfuscated symbols gracefully | Sven | Ingestion & reverse-engineering | P2 | M7 |
| US-057 | Cross-reference a suspicious function's callers and callees | Sven | Bubble navigation & orientation | P0 | M2 |
| US-058 | Compare two versions of a vendored binary | Sven | Performance & scale | P2 | M7 |
| US-059 | Export the recovered model and findings | Sven | Interchange (XMI/Rose/EA/PlantUML import-export) | P2 | M7 |
| US-060 | Import XMI with full relationship fidelity | Robert | Interchange (XMI/Rose/EA/PlantUML import-export) | P0 | M7 |
| US-061 | Import Rational Rose petal files | Robert | Interchange (XMI/Rose/EA/PlantUML import-export) | P1 | M7 |
| US-062 | Import an EA native repository | Robert | Interchange (XMI/Rose/EA/PlantUML import-export) | P1 | M7 |
| US-063 | Export to XMI and round-trip diff for fidelity | Robert | Interchange (XMI/Rose/EA/PlantUML import-export) | P0 | M7 |
| US-064 | Author across the full UML 2.5.1 diagram set | Robert | Diagram coverage & projection-to-2D | P1 | M7 |
| US-065 | Project and verify a SysML block diagram | Robert | Diagram coverage & projection-to-2D | P1 | M7 |
| US-066 | Interchange BPMN, DMN, and ArchiMate models | Robert | Interchange (XMI/Rose/EA/PlantUML import-export) | P2 | M7 |
| US-067 | Get a fidelity report of dropped elements on import | Robert | Interchange (XMI/Rose/EA/PlantUML import-export) | P1 | M7 |
| US-068 | Preserve manually-placed diagram layout | Robert | Authoring (add/connect/edit/re-parent) | P2 | M3 |
| US-069 | Validate diagrams against notation standards | Robert | Diagram coverage & projection-to-2D | P2 | M7 |
| US-070 | Export Mermaid and DOT for lightweight sharing | Robert | Interchange (XMI/Rose/EA/PlantUML import-export) | P2 | M5 |
| US-071 | Fly through a system in VR at frame budget | Aiko | VR & comfort | P0 | M11 |
| US-072 | Author with a wrist-anchored radial menu | Aiko | VR & comfort | P0 | M11 |
| US-073 | Connect nodes in VR with ray-pick assists | Aiko | VR & comfort | P0 | M11 |
| US-074 | Name elements with a near-field VR keyboard | Aiko | VR & comfort | P1 | M11 |
| US-075 | Use comfort options to prevent motion sickness | Aiko | VR & comfort | P0 | M11 |
| US-076 | Hand off between desktop and VR without losing place | Aiko | VR & comfort | P1 | M11 |
| US-077 | Peek-expand collapsed clusters to target deep children | Aiko | VR & comfort | P1 | M11 |
| US-078 | Keep an edge type sticky while drawing in VR | Aiko | VR & comfort | P2 | M11 |
| US-079 | Drill and locomote without inducing vection | Aiko | VR & comfort | P1 | M11 |
| US-080 | Read SDF labels and icons clearly at any depth in VR | Aiko | VR & comfort | P1 | M11 |
| US-081 | Project a reference pattern's class diagram | Elena | Diagram coverage & projection-to-2D | P1 | M5 |
| US-082 | Render projector-legible high-contrast labels | Elena | Accessibility (color/keyboard/motion) | P1 | M10 |
| US-083 | Show code and model side by side | Elena | Code round-trip & LLM codegen | P1 | M4 |
| US-084 | Build and save canonical teaching examples | Elena | Persistence & document management | P2 | M3 |
| US-085 | Share a model file students can open and explore | Elena | Collaboration / sharing / annotation | P1 | M6 |
| US-086 | Render monochrome-safe for projectors and handouts | Elena | Accessibility (color/keyboard/motion) | P2 | M10 |
| US-087 | Step through a pattern's collaboration sequence | Elena | Diagram coverage & projection-to-2D | P2 | M5 |
| US-088 | Offer a simplified guided mode for the classroom | Elena | Onboarding & first-run | P2 | M10 |
| US-089 | Re-model a repo headlessly on commit | ARIA | Automation / headless / API | P0 | M4 |
| US-090 | Generate code from model edits deterministically | ARIA | Code round-trip & LLM codegen | P0 | M4 |
| US-091 | Export diagrams headlessly to SVG and PlantUML | ARIA | Automation / headless / API | P1 | M5 |
| US-092 | Return structured errors and exit codes | ARIA | Automation / headless / API | P1 | M9 |
| US-093 | Cancel and time out long operations | ARIA | Automation / headless / API | P1 | M9 |
| US-094 | Configure endpoints and keys via env/secret | ARIA | Automation / headless / API | P1 | M4 |
| US-095 | Fail the build on a structural rule violation | ARIA | Automation / headless / API | P2 | M9 |
| US-096 | Drive every authoring verb from the keyboard | Theo | Accessibility (color/keyboard/motion) | P0 | M3 |
| US-097 | Encode every kind and edge type beyond color | Theo | Accessibility (color/keyboard/motion) | P0 | M3 |
| US-098 | Use a reduced-motion mode with instant transitions | Theo | Accessibility (color/keyboard/motion) | P0 | M3 |
| US-099 | Read high-contrast labels regardless of hue | Theo | Accessibility (color/keyboard/motion) | P1 | M10 |
| US-100 | Get non-color status feedback for actions | Theo | Accessibility (color/keyboard/motion) | P1 | M3 |

## Per-milestone counts

M0 carries no user stories — it is contract-freeze and scaffold work that enables every later
milestone. The 100 stories distribute across M1–M11 as follows.

| Milestone | Stories | Count |
|-----------|---------|-------|
| M0 Foundation & Contracts | *(enabling work; no stories)* | 0 |
| M1 Walking Skeleton | US-002, US-005, US-019, US-022, US-023, US-024, US-025, US-034 | 8 |
| M2 Navigate, Search & Understand | US-003, US-004, US-008, US-009, US-012, US-013, US-026, US-027, US-028, US-029, US-032, US-052, US-057 | 13 |
| M3 Authoring, Persistence & A11y | US-015, US-018, US-021, US-030, US-031, US-035, US-044, US-068, US-084, US-096, US-097, US-098, US-100 | 13 |
| M4 Ingestion & Round-Trip | US-001, US-010, US-033, US-051, US-053, US-083, US-089, US-090, US-094 | 9 |
| M5 Projection & Interchange | US-006, US-007, US-016, US-017, US-042, US-043, US-070, US-081, US-087, US-091 | 10 |
| M6 Collaboration & Sharing | US-037, US-038, US-039, US-040, US-041, US-045, US-046, US-047, US-048, US-055, US-085 | 11 |
| M7 Enterprise Interchange & Binary | US-014, US-049, US-050, US-054, US-056, US-058, US-059, US-060, US-061, US-062, US-063, US-064, US-065, US-066, US-067, US-069 | 16 |
| M8 Performance & Scale | US-011 | 1 |
| M9 Automation & CI | US-092, US-093, US-095 | 3 |
| M10 Onboarding & A11y Polish | US-020, US-036, US-082, US-086, US-088, US-099 | 6 |
| M11 VR / WebXR (deferred) | US-071, US-072, US-073, US-074, US-075, US-076, US-077, US-078, US-079, US-080 | 10 |
| **Total** | | **100** |

**Notes on light/heavy milestones.** M8 holds a single explicit story (US-011, the million-element
target); most M8 work is enabling perf infrastructure (instancing, culling, LOD/HLOD, worker/WASM
layout, streaming load, perf-budget CI) plus the **re-verification** of US-024 (label legibility) at
scale — US-024 is *delivered* in M1 and re-checked in M8, so it is counted once, under M1. M7 is the
heaviest at 16 stories because it joins two backlogs: enterprise interchange (Robert) and binary
ingestion / model-diff (Sven), which also absorbs US-014's version-drift comparison via the shared
diff engine.

## Per-priority coverage

Priority totals across all 100 stories, and where they land relative to the v1 line (M0–M10) versus
the deferred VR milestone (M11):

| Priority | Total | Delivered in v1 (M0–M10) | Deferred to M11 (VR) |
|----------|-------|--------------------------|----------------------|
| P0 | 31 | 27 | 4 |
| P1 | 46 | 41 | 5 |
| P2 | 22 | 21 | 1 |
| P3 | 1 | 1 | 0 |
| **Total** | **100** | **90** | **10** |

**P0 coverage — verified against the map:** all **27** non-deferred P0 stories land **by M7**. Their
latest milestone is M7 (US-049 JAR decompile, US-060 XMI import, US-063 XMI export/round-trip diff);
the earlier P0s complete across M1 (7), M2 (7), M3 (5), M4 (3), M5 (1), and M6 (1). The only P0
stories not delivered by M7 are the **4 VR P0s** (US-071, US-072, US-073, US-075), which are
explicitly deferred to M11 post-v1. So the brief's target — *"all P0s land by M7 except deferred
VR"* — holds exactly.

**Lower priorities.** The 10 deferred M11 stories are entirely persona Aiko's VR & comfort epic:
4 × P0, 5 × P1 (US-074, US-076, US-077, US-079, US-080), and 1 × P2 (US-078). Every other story of
every priority — including the sole P3 (US-048, read-only shared view, M6) — is delivered within the
v1 milestones M1–M10.
