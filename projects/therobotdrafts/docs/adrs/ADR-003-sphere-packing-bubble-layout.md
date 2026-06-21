---
id: ADR-003
title: "Sphere-packing \"bubble\" layout for the primary 3D view"
status: accepted
date: 2026-06-21
---

# ADR-003: Sphere-packing "bubble" layout for the primary 3D view

## Context

The primary 3D view must let a user navigate a whole codebase as a place (see
[`CONCEPTS.md`](../CONCEPTS.md)). To do that well it has to satisfy several constraints at once:

- **Show the containment hierarchy legibly** — package → class → method — because that hierarchy is the
  user's mental map and the basis of navigation.
- **Encode at least one node metric** (size, LOC, significance) without overloading the view.
- **Keep occlusion low in 3D/VR.** A layout that buries nodes behind other nodes is unusable in a
  headset, where the user cannot trivially re-angle as on a desktop.
- **Stay stable across edits.** Re-running layout after a small change must not reshuffle the world, or
  the user loses their spatial memory.
- **Double as the level-of-detail hierarchy** the GPU pipeline ([ADR-001](./ADR-001-unity-dots-rendering.md))
  selects against.

Edges (calls, dependencies, inheritance) cross the containment hierarchy and, if all drawn, produce a
hairball — the single worst problem for 3D legibility. So the layout must privilege containment and a
metric, and treat edges as a secondary, on-demand concern.

Code-city / treemap layouts encode containment and a metric very well, but they encode **edges** poorly.
Pure force-directed layouts encode edges but are unstable and occlusion-heavy. Neither alone fits.

## Decision

Use **nested sphere packing** as the primary navigation layout, with specialized layouts for the
secondary tasks it does poorly.

- **Primary: nested circle/sphere packing** (D3-`pack`-style, extruded into Z). Each container is a
  sphere; its children are packed inside its volume; sizing is computed bottom-up. This gives strict,
  visible containment and a clear size metric, with relatively low self-occlusion. Packing is **stable**:
  a local change re-packs only the affected subtree and ripples upward gently, preserving sibling
  positions (see [`CONCEPTS.md`](../CONCEPTS.md) § Containment).
- **Directed drill-downs: Sugiyama (layered).** When the user drills into a directed structure
  (inheritance, a dependency slice), project it as a ranked, layered layout.
- **Large dependency clouds: force-directed with Barnes-Hut / octree.** For unranked relationship masses
  too large for Sugiyama, use an octree-accelerated force layout, settled and then frozen for stability.
- **Dense edges: Hierarchical Edge Bundling.** Route edges along the containment hierarchy to collapse
  hairballs into legible ribbons.
- **Edges are not all drawn.** They are on-demand, hop-limited, and bundled (see
  [`design-conventions.md`](../specs/design-conventions.md) § Edge conventions).

The packing hierarchy **is** the HLOD hierarchy: a collapsed container becomes a single proxy sphere,
which is exactly the unit [ADR-001](./ADR-001-unity-dots-rendering.md)'s GPU pipeline culls and
swaps.

## Consequences

- **Stable, semantic, occlusion-light bubbles** that align one-to-one with the code hierarchy. The
  layout is meaningful (position encodes ownership), navigable (you fly into containers), and friendly
  to VR comfort.
- **The layout doubles as HLOD for free.** No separate spatial hierarchy is needed for culling and
  detail selection; the packing tree serves both.
- **Edge tracing needs a dedicated mode/view.** Because containment is privileged, relationships are not
  ambient — following a call chain requires trace mode, bundling, or a projected diagram. This is an
  accepted, deliberate cost.
- **Sphere self-occlusion is a known limit.** Densely packed children can still hide one another from
  some angles; foveation, focus-dimming, and drill-in mitigate but do not eliminate it.
- **Multiple layout engines to build and maintain** (packing, Sugiyama, force-directed, HEB) rather than
  one.

## Alternatives considered

- **Code-city / treemap.** *Viable — kept as an alternate skin.* Encodes containment and a metric well;
  many users find the "city" metaphor intuitive. It encodes edges poorly and reads as a flat field
  rather than a navigable nesting, so it is offered as an alternate visual skin over the same packing
  hierarchy, not the default.
- **Pure force-directed as the primary view.** *Rejected.* Unstable across edits (destroys spatial
  memory) and produces the **worst** edge occlusion — unacceptable as the always-on primary layout. It
  survives only in the bounded role above (frozen, for large clouds on demand).
- **3D UMAP / semantic embedding cloud.** *Kept as a complementary axis, not the primary.* A semantic
  projection (clustering by behavioral or textual similarity) is a valuable *additional* lens, but it
  does not encode the containment hierarchy and is not stable, so it is a secondary view the user can
  switch to, never the navigation backbone.

See also [ADR-002](./ADR-002-unified-internal-model.md) (the model being laid out) and
[ADR-001](./ADR-001-unity-dots-rendering.md) (the renderer that draws it).
