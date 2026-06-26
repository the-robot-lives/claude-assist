# arch/decisions.md — Key Architectural Decisions

The reasoning behind the architecture's choices is recorded as Architecture Decision Records in
[../adrs/](../adrs/). Read the ADRs before changing a subsystem's contract — they capture trade-offs
that aren't obvious from the code. This file summarizes the load-bearing decisions.

| Decision | Rationale | Trade-off | Record |
|----------|-----------|-----------|--------|
| **Model as single source of truth** | Every bubble/diagram/export is a derived view; no authoritative state outside the model. Diagrams never drift from code; edits round-trip. | All views must be re-derivable; no view may hold private state. | core invariant |
| **DOTS/ECS over GameObjects** | Bubbles are data in packed arrays so million-element counts stay inside a VR frame budget. | Higher implementation complexity than a GameObject scene graph. | [ADR-001](../adrs/ADR-001-unity-dots-rendering.md) |
| **Unified internal model (KDM-as-schema)** | One graph populated by mature tooling rather than a KDM-conformant extractor; imported diagrams are first-class, not sidecars. | KDM is an organizing schema only, not the import format. | [ADR-002](../adrs/ADR-002-unified-internal-model.md) |
| **Sphere-packing bubbles over "code city"** | Volumetric containment (child *inside* parent) extends to arbitrary depth; continuous LOD (collapse to one proxy sphere); natural VR fly-through. | A single scalar metric (building height) is less legible than in the city metaphor. | [ADR-003](../adrs/ADR-003-sphere-packing-bubble-layout.md) |
| **Heavy work off the frame loop** | Ingestion, layout, and projection stream results in; the render pipeline never blocks on analysis. | Requires diff-based, incremental subsystems rather than synchronous rebuilds. | core invariant |

## Decisions implicit in the current code

- **UI-agnostic authoring core.** Model/rules/commands/controller live in `Authoring/` with no
  `UnityEngine` UI dependency, so the same core backs both the 2D `Uml/` harness and the 3D `Uml3D/`
  scene — and will back the DOTS bubble renderer behind `Seams/IPacker.cs` without changing.
- **`JsonUtility`-shaped DTOs.** The Unity player runtime has no `System.Text.Json`, so both
  `LlmClient` and `CodeParser` use single-root-object-with-named-array DTOs.
- **Deterministic-first import/codegen.** A network-free structural parser and source skeleton are
  the first-choice strategies (instant, offline); the LLM is the fallback/elaboration layer.

→ Further reading: [../adrs/](../adrs/), [implementation-status.md](implementation-status.md).
