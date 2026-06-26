# arch/rendering-and-vr.md — Render Pipeline & VR

The render pipeline draws the laid-out model fast enough for VR — the target is **90 fps on
million-element graphs**. It is built on Unity **DOTS/ECS** so that bubbles are data in tightly
packed arrays, not GameObjects, which is the only way element counts at this scale stay tractable.
Because layout arrives as data and the model never mutates inside the frame loop, the pipeline can
run flat-out while ingestion and projection proceed in the background.

## Stages

- **GPU-driven indirect draws** — bubble geometry submitted in large batches via indirect draw
  arguments computed on the GPU; the CPU never iterates a million elements per frame.
- **Octree culling** — a spatial octree over bubble positions answers "what is visible from here?"
  per frame, so only on-screen, in-budget elements reach the rasterizer.
- **HLOD (hierarchical level of detail)** — a collapsed package renders as **one** impostor proxy
  bubble instead of its thousands of descendants. HLOD is what makes the whole-system overview
  cheap; it is a first-class concept (a collapsed package = one HLOD proxy).
- **VR stereo + foveated rendering** — stereo for head-mounted display, foveation to spend GPU
  budget where the eye looks. Desktop renders the same scene mono and remains fully equal.

## As built

None of the DOTS pipeline exists yet. The current renderer is a non-DOTS stand-in: the 2D
`Uml/UmlCanvas` is a uGUI canvas of classifier boxes; `Uml3D/` builds **procedural mesh slabs**
(12-triangle cuboids) whose front face carries a world-space uGUI canvas reproducing the UML
compartments, lit via URP/Lit (with Standard/unlit fallbacks) and pickable through a `BoxCollider`.
`Uml3D/UmlCameraRig.cs` is a full 6-DOF rig (orbit/dolly/pan/roll/free-fly + frame-to-fit). No
octree culling, no HLOD, no VR stereo/foveation.

→ Further reading: [../specs/rendering-and-vr.md](../specs/rendering-and-vr.md), [../CONCEPTS.md (LOD / HLOD)](../CONCEPTS.md#level-of-detail-as-a-first-class-concept), [decisions.md](decisions.md) (ADR-001), [../ARCHITECTURE.md §4](../ARCHITECTURE.md).
