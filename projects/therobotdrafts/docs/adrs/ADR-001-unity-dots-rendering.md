---
id: ADR-001
title: "Unity DOTS + GPU-driven indirect rendering"
status: accepted
date: 2026-06-21
---

# ADR-001: Unity DOTS + GPU-driven indirect rendering

## Context

The Robot Draft must hold **90fps in VR** while displaying graphs with up to a **million elements**
(packages, types, methods, fields, and their edges). VR is unforgiving: a single missed frame is a
visible judder, and sustained frame drops cause discomfort. This raises the performance floor far
above a desktop visualization tool.

Unity's default object model — `GameObject` + `MonoBehaviour`, one component tree per entity, drawn
through the standard scene graph — does not survive this scale. In practice it tops out in the low
thousands of active objects before per-object CPU overhead and draw-call count dominate the frame.
Managed-memory churn makes it worse: garbage-collector pauses introduce non-deterministic hitches,
and in VR a GC stall is a guaranteed judder. We need **zero per-frame heap allocation** on the hot
path, which the classic model cannot guarantee.

Unity also lacks an equivalent of Unreal's Nanite. There is no built-in system that virtualizes
geometry and continuously selects detail per-cluster on the GPU. Unity's `LODGroup` and baked
occlusion culling are authored, per-object, CPU-side mechanisms designed for hand-placed scenes of
modest object counts — not for a procedurally generated, million-node hierarchy that changes as the
user navigates. They do not scale to our object counts and cannot express our hierarchical
level-of-detail (HLOD) model where a whole package collapses to one proxy sphere.

## Decision

Build the renderer on **Unity DOTS** (Entities/ECS) with **Burst**-compiled jobs, and draw the world
through a **custom GPU-driven indirect pipeline** rather than the GameObject scene graph.

Concretely:

- **ECS + Burst** for all model-to-render data. Bubble transforms, kinds, metrics, and LOD state live
  in tightly packed component arrays processed by Burst jobs off the main thread. No `MonoBehaviour`
  on the hot path.
- **`RenderMeshIndirect` / indirect instanced draws.** Visible instances are written to GPU buffers
  and drawn with indirect arguments, so the CPU issues a handful of draw calls regardless of element
  count.
- **Compute-shader culling and HLOD selection.** A GPU compute pass performs **octree culling**,
  **Hi-Z (hierarchical-Z) occlusion culling**, frustum culling, and per-cluster **HLOD** selection,
  emitting the instance and argument buffers the indirect draw consumes. The CPU never iterates a
  million elements per frame.
- **Foveated rendering** in VR, driving detail toward the gaze point (see
  [`rendering-and-vr.md`](../specs/rendering-and-vr.md)).
- **Zero per-frame allocation** on the render path is a hard, enforced constraint, not a goal.

## Consequences

- **This is the only path to our scale target.** Nothing else in the Unity ecosystem holds 90fps VR
  on million-element graphs.
- **High engineering cost.** Because Unity has no Nanite, we build the equivalents ourselves: Hi-Z
  occlusion, the HLOD proxy system, GPU culling, and the indirect submission path. These are
  substantial, specialized subsystems with their own correctness and tooling burden.
- **DOTS is the harder authoring model.** ECS imposes a data-oriented discipline that is less
  ergonomic than `GameObject` scripting; debugging and tooling are thinner. The team pays a learning
  and iteration cost.
- **The zero-allocation rule is non-negotiable and constrains everything downstream.** Any feature
  that allocates per frame is a bug; this shapes how layout results, label budgets, and edge bundles
  are streamed in.
- **We own the GPU pipeline.** We gain full control over culling and LOD (good — our HLOD model
  requires it) but lose the "it just works" convenience of Unity's built-in rendering and any future
  engine improvements to it.

## Alternatives considered

- **Classic GameObjects / MonoBehaviour.** *Rejected.* Hits a hard scale wall in the thousands, and
  GC pauses cause VR judder. Not viable at our object counts.
- **Unreal Engine + Nanite.** *Rejected — with acknowledged tradeoff.* Nanite and Lumen would give us
  virtualized geometry "for free," removing much of the GPU-pipeline work above. We are committed to
  Unity for the rest of the toolchain and team expertise, so we accept building the GPU-driven
  equivalents ourselves. This is the most significant tradeoff in the decision.
- **Web / WebXR (Three.js / Babylon.js).** *Rejected.* The browser performance ceiling and weaker GPU
  control make 90fps VR on million-element scenes unattainable. Reconsider only for a low-fidelity
  viewer, never the primary tool.

See also [ADR-003](./ADR-003-sphere-packing-bubble-layout.md) — the bubble layout doubles as the HLOD
hierarchy this pipeline selects against.
