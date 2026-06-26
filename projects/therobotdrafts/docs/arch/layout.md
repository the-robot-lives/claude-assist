# arch/layout.md — Layout Engine

The Layout engine assigns geometry. It reads the [Unified Model](unified-model.md) and produces
positions, offering two fundamentally different spatial idioms chosen by what the user is doing. It
emits layout **as data, not scene-graph mutations**, so the render pipeline can consume it in bulk;
layout for off-screen and collapsed regions is computed lazily.

## Bubble layout (sphere / circle packing)

The default spatial view nests packed spheres: package bubbles contain class bubbles contain method
bubbles, so containment is *physical* — a child is inside its parent's volume. Packing is computed
**bottom-up** (members sized, then packed into their type, then types into their package), which
keeps each level locally stable when a sibling changes. This is the everyday "fly through the
system" experience. *(Rationale: ADR-003, see [decisions.md](decisions.md).)*

## Relational layout (Sugiyama / force-directed)

When drilling into relationships — a call graph, class diagram, sequence — bubble packing is the
wrong tool, because those views are about edges, not containment. Here the engine switches to
**Sugiyama** layered layout (directed, hierarchy-like graphs: inheritance, layered call flow) and
**force-directed** layout (dense, non-hierarchical relationship webs).

## As built

The current code implements harness layout, not the real packer: the 2D `Uml/UmlCanvas.Layout.cs`
arranges classifier boxes and routes edges within a package tab; `Uml3D/` places lit slabs on
Z-layers with a 6-DOF camera. The true sphere/circle packer is a **seam only** —
`Authoring/Seams/IPacker.cs` — so it can own real 3D bubble layout later without touching the core.

→ Further reading: [../specs/rendering-and-vr.md](../specs/rendering-and-vr.md) (layout↔render contract), [../specs/design-conventions.md](../specs/design-conventions.md) (sizing, spacing, color), [../ARCHITECTURE.md §3](../ARCHITECTURE.md).
