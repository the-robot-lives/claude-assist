# The Robot Draft ↔ Sparx Enterprise Architect — Feature Parity List

> Purpose: map The Robot Draft (TRD) against the feature surface of **Sparx Enterprise Architect (EA)**,
> grouped the way EA's own [Compare Editions](https://sparxsystems.com/products/ea/compare-editions.html)
> page groups it (modelling languages, diagramming, code/DB engineering, simulation, collaboration,
> publishing, management, extensibility, UI, interchange).
> Date: 2026-06-26.
>
> **Sourcing note.** `sparxsystems.com` hard-blocks automated fetch (HTTP 403 to WebFetch, the
> markdown converter, and the Chrome extension was offline), so the EA column is built from EA's
> **documented capability areas + edition tiering** (cross-checked via web search of the editions
> pages) and TRD's own committed parity targets in
> [`docs/specs/diagram-catalog.md`](specs/diagram-catalog.md) and
> [`docs/specs/file-formats.md`](specs/file-formats.md). Treat per-edition cell assignments as
> indicative; confirm against the live matrix when it's reachable from a browser.

---

## Legend (TRD status)

| Mark | Meaning |
|------|---------|
| ✅ **Has** | Implemented and working in the current build |
| 🟡 **Partial** | Present but limited / stand-in implementation |
| 📋 **Specced** | Committed in the design corpus, not yet built |
| ❌ **Gap** | Not addressed in build or specs |
| ➕ **Beyond EA** | TRD capability EA does not have |

EA edition where a feature first appears: **Pro** = Professional · **Corp** = Corporate ·
**Uni** = Unified · **Ult** = Ultimate. (Community/Lite is read-only and omitted.)

---

## 0. Editions context (EA)

EA ships as tiers; each superset includes the lower tier:

| Edition | Adds over previous | Headline capability |
|---------|--------------------|---------------------|
| **Professional** | — | Single/workgroup modelling, code engineering, shared file/replication |
| **Corporate** | DBMS-backed shared repository, security/RBAC, auditing | Team repository on Oracle/SQL Server/etc. |
| **Unified** | Built-in frameworks (TOGAF, Zachman, UAF/UPDM), SysML, BPSim | Enterprise-architecture frameworks |
| **Ultimate** | Executable code-miner, full simulation, row-level security config | Everything, all domains |

TRD is a **single product, not tiered.** Its ambition spans roughly Pro→Unified modelling breadth
plus a differentiated 3D/VR + reverse-engineering core; it is weakest exactly where EA's *Corporate*
tier is strongest (team repository, security, governance).

---

## 1. Modelling Languages & Notations

| Capability | EA (edition) | TRD | Notes |
|---|---|---|---|
| UML 2.5.1 — all 14 diagram types | Pro | 🟡 | All 14 element/edge **kinds** in the palette; projection engine + full notation fidelity 📋 ([diagram-catalog §1](specs/diagram-catalog.md)) |
| SysML (BDD, IBD, Parametric, Requirement) | Uni | 📋 | Specced via the profile mechanism; not built |
| BPMN 2.0 (Process/Collaboration/Choreography) | Pro/Uni | 📋 | Specced; node kinds partly present |
| DMN (DRD + decision tables + FEEL) | Uni | 📋 | Specced |
| ArchiMate 3.x (layers + viewpoints) | Uni | 📋 | Specced as layer-colored bubble planes |
| UAF / UPDM (DoDAF/MODAF/NAF) | Uni/Ult | 📋 | Specced (grid-addressed bubbles) |
| TOGAF (ADM) | Uni | 📋 | Specced |
| Zachman framework | Uni | 📋 | Specced |
| ERD / physical data model | Pro/Corp | 📋 | Specced; no live schema reverse-engineering yet |
| Profile / MDG / stereotype extension | Pro→Ult | 🟡 | Profile node kinds + «extension» edge in build; MDG-tech authoring 📋 |
| Rational Rose legacy (Statechart/Collaboration names) | n/a | 📋 | Specced for import fidelity ([diagram-catalog §8](specs/diagram-catalog.md)) |
| Rose RealTime (Capsules/Ports/Protocols) | n/a | 📋 | Specced |
| Mind map / DFD / network / wireframe / whiteboard / Gantt-Kanban | Pro/Uni | 🟡 | Whiteboard nodes/connectors now in build; remaining auxiliary layouts are specced as bubble layouts |

**Read:** TRD has the *vocabulary* (element/edge kinds) for nearly EA's whole notation range, but the
**diagram-projection engine** that turns the model into a faithful, standard 2D diagram is the missing
core. Today it's a direct editor, not a region-projection system.

---

## 2. Diagramming & Visualization

| Capability | EA | TRD | Notes |
|---|---|---|---|
| 2D diagram canvas, palette, styling | Pro | ✅ | Runtime uGUI editor; per-element color/font/stereotype |
| Connectors w/ multiplicity, roles, routing | Pro | ✅ | Orthogonal + bezier, waypoints, end markers |
| Layers / diagram filters | Pro | 🟡 | Z-layers + cross-layer chevrons; no semantic filter views |
| Auto-layout | Pro | 🟡 | Sequence auto-arrange + force/grid; sphere-packing 📋 (ADR-003) |
| **3D spatial navigation (bubble view)** | — | ➕✅ | 3D mesh scene, orbit/dolly/fly, depth-layers — EA has none |
| **VR / XR fly-through** | — | ➕📋 | Core differentiator; desktop-only today, OpenXR/XRI specced |
| Hierarchical level-of-detail for huge models | partial | 📋 | HLOD/octree specced (ADR-001); label LOD is a current gap (UX P0-4) |
| Diagram legends, model views, dashboards | Corp/Uni | ❌ | Not addressed |

---

## 3. Code Engineering (forward / reverse / round-trip)

| Capability | EA | TRD | Notes |
|---|---|---|---|
| Reverse-engineer source → model | Pro | 🟡 | Regex/structural parser (C#, light TS/Java) + LLM fallback; compiler-grade frontends (Roslyn/Clang/JDT/tsc) 📋 |
| Forward-engineer model → code | Pro | ✅ | Deterministic multi-lang skeletons (C#/Java/TS/Python/Elixir) |
| Round-trip / synchronize code ↔ model | Pro | ✅ | Surgical LLM **overlay** edit of original source |
| **LLM-assisted generation & overlay** | — | ➕✅ | EA has no native LLM codegen |
| Language breadth (10+ languages) | Pro | 🟡 | Skeletons in ~5 langs; import narrower |
| **Decompile binaries (IL/bytecode/native) → model** | — | ➕📋 | ILSpy/JADX/CFR/Ghidra specced; EA does not decompile binaries |
| Build/debug/execution integration | Pro | ❌ | Not addressed |
| Code template framework | Pro | 🟡 | Skeleton generator; no editable template grammar |

---

## 4. Database Engineering

| Capability | EA | TRD | Notes |
|---|---|---|---|
| ERD / physical data modelling | Pro/Corp | 📋 | Specced |
| Reverse-engineer DB schema (Oracle/SQLServer/PG/MySQL) | Corp | 📋 | Specced ([diagram-catalog §6.1](specs/diagram-catalog.md)); not built |
| Generate DDL | Pro/Corp | 📋 | Specced |
| Database compare / sync | Corp | ❌ | Not addressed |

---

## 5. Requirements & Traceability

| Capability | EA | TRD | Notes |
|---|---|---|---|
| Requirements as first-class model elements | Pro/Corp | 📋 | SysML Requirement bubbles specced |
| Traceability matrix | Corp | 📋 | Specced as edge-adjacency view |
| Relationship matrix / impact analysis | Corp | ❌ | Not addressed |
| Requirements import (CSV/ReqIF) | Corp | ❌ | Gap |

---

## 6. Simulation & Execution

| Capability | EA | TRD | Notes |
|---|---|---|---|
| Dynamic model simulation (state/activity) | Uni/Ult | ❌ | Not addressed |
| BPSim business-process simulation | Uni/Ult | ❌ | Listed for import fidelity only |
| Executable StateMachines / code-miner | Ult | ❌ | Gap |
| Parametric (SysML) evaluation | Uni/Ult | 📋 | Parametric bubbles specced; no solver |

**Read:** Simulation is the clearest whole-category EA gap for TRD — not in build or design beyond the
parametric stub.

---

## 7. Documentation & Publishing

| Capability | EA | TRD | Notes |
|---|---|---|---|
| Image export (PNG/SVG/etc.) | Pro | 🟡 | PNG screenshot today; SVG/vector specced |
| Document generation (RTF/PDF/DOCX, templated) | Pro/Corp | ❌ | Not addressed |
| HTML report / web publish | Pro/Corp | ❌ | Gap |
| WebEA / browser viewing | Corp+ | ❌ | Gap |

---

## 8. Collaboration, Repository & Security

| Capability | EA | TRD | Notes |
|---|---|---|---|
| Shared file / replication | Pro | 🟡 | Single local JSON file; no multi-user (UX P1-1) |
| DBMS-backed team repository | Corp | ❌ | **Major gap** — EA's core team value |
| Cloud server / Pro Cloud Server | Corp+ | ❌ | Gap |
| Version control integration (Git/SVN) | Pro/Corp | ❌ | Gap |
| Security / RBAC / user locking | Corp | ❌ | Gap |
| Row-level security configuration | Ult | ❌ | Gap |
| Auditing / change history | Corp | 🟡 | Undo/redo only; no audit trail |
| Discussions / reviews / model mail | Corp | ❌ | Gap (tech-lead persona need) |

**Read:** This block is where TRD is furthest from EA and where EA's *Corporate+* editions earn their
price. Collaboration is a deliberate later-phase concern for TRD, but it's the biggest parity hole.

---

## 9. Project & Model Management

| Capability | EA | TRD | Notes |
|---|---|---|---|
| Gantt / Kanban / resource allocation | Corp/Uni | 📋 | Gantt/Kanban specced as *diagrams*, not PM tooling |
| Testing & test-case management | Corp | ❌ | Gap |
| Maintenance items (defects/changes/issues) | Pro/Corp | ❌ | Gap |
| Model patterns / reusable asset service | Corp/Uni | ❌ | Gap |
| Baselines & model diff | Corp | ❌ | Gap |

---

## 10. Extensibility & Automation

| Capability | EA | TRD | Notes |
|---|---|---|---|
| Scripting (JS/VBScript/Python) | Pro/Corp | ❌ | Gap |
| Automation / Object Model API | Pro/Corp | 🟡 | LLM endpoint config only; no public model API (automation persona need) |
| Add-in / plugin framework | Pro/Corp | ❌ | Gap |
| MDG technologies / custom toolboxes | Pro→Ult | 🟡 | Profile mechanism specced; no MDG packaging |
| Headless / CI mode | partial | 🟡 | `build-mac.sh` batch build; no headless model API (ARIA persona, UX P1) |

---

## 11. Model Interchange (Import / Export)

| Format | EA | TRD | Notes |
|---|---|---|---|
| **XMI** (multi-dialect import / 2.5.1 export) | Pro→Ult | 📋 | P0 target ([file-formats §2](specs/file-formats.md)); not built |
| Sparx EA native `.qea`/`.eap` | native | 📋 | `.qea` import P0 / export P1 (specced) |
| Rational Rose petal `.mdl` | import | 📋 | P2 specced |
| Eclipse `.uml` / `.ecore` | partial | 📋 | P1/P2 specced |
| ArchiMate Model Exchange `.xml` | Uni | 📋 | P1 specced (layout-carrying) |
| BPMN 2.0 / DMN XML | Uni | 📋 | P1/P2 specced (DI in-file) |
| PlantUML / Mermaid / DOT | via add-in | 📋 | P1/P2 specced |
| **Native JSON diagram save/load** | — | ➕🟡 | TRD's only working persistence today (single file) |
| SVG / PNG export | Pro | 🟡 | PNG ✅, SVG 📋 |
| PDF / EMF / WMF export | Pro | ❌ | P3 / gap |

**Read:** EA interoperability is the make-or-break for the *legacy modeler* persona (Robert). All the
right formats are specced with a sound internal-model-as-hub strategy — but **none are implemented**;
the only working I/O is a private JSON file + PNG.

---

## 12. User Interface & Usability

| Capability | EA | TRD | Notes |
|---|---|---|---|
| Toolbox / element palette | Pro | ✅ | Sectioned, collapsible palette |
| Properties / inspector editing | Pro | ✅ | Per-element + per-member editors |
| Command discoverability (toolbar/ribbon) | Pro | 🟡 | Verbs hidden in right-click + hotkeys; verb rail 📋 (UX P0-1) |
| Tooltips / contextual help | Pro | ❌ | None today (UX P0-2) |
| Keyboard-driven operation | Pro | 🟡 | Many hotkeys; not full keyboard-complete (Theo persona) |
| Search / model find & filter | Pro/Corp | ❌ | No palette/model search (UX P2) |
| Accessibility (contrast/colorblind/reduced-motion) | partial | 🟡 | Redundancy contract specced; not all enforced in build |
| Diagram navigation / focus / framing | Pro | 🟡 | Frame-all only; focus-on-selection 📋 (UX P0-3) |
| **Immersive 3D/VR UI (radial, near-field keyboard)** | — | ➕📋 | Authoring-UX spec; desktop verbs only today |

---

## 13. Strategic read

**Where TRD already leads EA (➕):**
- 3D spatial bubble navigation and (planned) VR fly-through — EA has no spatial model at all.
- Binary **reverse-compilation** to a navigable model (decompiler integration) — outside EA's scope.
- **LLM-native** code generation and surgical round-trip overlay.
- "Always-live, reverse-engineered model as the source of truth" vs EA's authored-diagram-first stance.

**At rough parity (build or near-build):**
- Core UML authoring, connectors, styling, forward codegen, round-trip, undo/redo, image export.

**The parity gaps that matter most, in priority order:**
1. **Interchange (§11)** — XMI + `.qea` import/export. Without it, no EA/Rose user can adopt TRD. Specced, unbuilt.
2. **Diagram-projection engine (§1–§2)** — turn the model into faithful standard diagrams across the specced languages; today it's a direct editor.
3. **Compiler-grade reverse-engineering (§3)** — replace the regex/LLM stand-in with real frontends for trustworthy models.
4. **Team repository + security + version control (§8)** — EA's Corporate moat; TRD's largest whole-category hole.
5. **Documentation/publishing (§7)** and **simulation (§6)** — full EA categories currently absent.

**Net:** TRD is not "behind EA" so much as **differently shaped** — it bets the spatial/RE/AI core while
EA's depth is in repository, governance, simulation, and publishing. For credible "EA parity" marketing
(README claim), the unglamorous **interchange + projection + real RE** trio is the gating work; the
collaboration/governance block is a deliberate later phase.

---

## Appendix — category ↔ source map

- Modelling languages & diagrams → [`specs/diagram-catalog.md`](specs/diagram-catalog.md) (46 families, tiered)
- Interchange formats → [`specs/file-formats.md`](specs/file-formats.md) (import/export matrix, round-trip strategy)
- UI/usability gaps → [`ux-review-current-build.md`](ux-review-current-build.md)
- Authoring/VR UI → [`specs/authoring-ux.md`](specs/authoring-ux.md)
- Current build capabilities → memory note `therobotdrafts-project` + `Assets/Scripts/{Uml,Uml3D,Llm,CodeGen}`
