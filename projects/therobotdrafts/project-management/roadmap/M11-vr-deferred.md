# M11 — [Deferred post-v1] VR / WebXR

**Status: deferred. Out of v1 scope.** Captured here for continuity and to fix the prerequisites,
not scheduled. v1 ships desktop WebGL2 (with the optional WebGPU engine) only. The ten VR stories
(US-071–US-080, persona **Aiko** / `trd-vr-explorer`) are not allocated to any v1 milestone.

## Objective

Bring the bubble world into immersive VR via **WebXR** once the web renderer and its performance
foundation can sustain a headset frame budget. This is the eventual vehicle for the VR-explorer
persona. There is no v1 commitment to any of it.

## Deferred scope

The full VR & comfort epic, carried from `docs/specs/rendering-and-vr.md` §4 as *targets, not code*:
fly-through at frame budget (US-071), a wrist-anchored radial authoring menu (US-072), ray-pick node
connection (US-073), a near-field VR keyboard (US-074), comfort options to prevent motion sickness
(US-075), desktop↔VR handoff without losing place (US-076), peek-expand of collapsed clusters
(US-077), a sticky edge type while drawing (US-078), locomotion without vection (US-079), and SDF
labels/icons legible at any depth (US-080).

## Prerequisites (gates before this work can start)

- **M8 performance foundation complete.** Instancing/impostors, hierarchical + occlusion culling,
  LOD/HLOD, the bounded label atlas, off-main-thread layout, and streaming are prerequisites, not
  nice-to-haves: VR must render **both eyes** within ~11.1 ms at 90 Hz, with fill computed at roughly
  **2× display resolution**, so the overdraw and draw-count discipline from M8 is load-bearing.
- **Babylon WebGPU engine path matured** (the optional M8-FE-GL-07 flag). The compute-driven
  cull/Hi-Z path is the practical route to VR-scale frames; WebGL2 alone is unlikely to hold the
  headset budget on large graphs.
- **WebXR session support behind `IRenderer`.** Stereo rendering, device-dependent foveation, and
  correct motion vectors for reprojection all sit behind the same renderer abstraction, so the desktop
  and VR paths stay unified.

## Carry-over design notes (Unity spec → WebXR targets)

- Cull **once** against a combined stereo frustum bounding both eyes — never per eye.
- Pair the 3D world with a **2D HUD for text**; offer a **table-top mode** (model scaled in front of a
  seated user); use **teleport locomotion** to avoid the vection that causes cybersickness
  (US-075, US-079).
- Pair **gaze-driven LOD/labels** with foveation where the device supports eye tracking, reusing the
  M8 label top-K and LOD signals.
- Treat **reprojection as a safety net, not a plan**: if AppSW-style synthesis is used, the indirect
  shaders must emit correct motion vectors.

## Post-v1 statement

VR/WebXR is explicitly **post-v1**. These stories gate on M8 (and the WebGPU path) landing and being
proven at scale on the desktop target first; only then does an M11 planning pass turn the notes above
into scheduled lanes and tasks. Nothing in v1 depends on this milestone.

## Stories deferred

| ID | Priority | Persona | Title |
|----|----------|---------|-------|
| US-071 | P0 | Aiko | Fly through a system in VR at frame budget |
| US-072 | P0 | Aiko | Author with a wrist-anchored radial menu |
| US-073 | P0 | Aiko | Connect nodes in VR with ray-pick assists |
| US-074 | P1 | Aiko | Name elements with a near-field VR keyboard |
| US-075 | P0 | Aiko | Use comfort options to prevent motion sickness |
| US-076 | P1 | Aiko | Hand off between desktop and VR without losing place |
| US-077 | P1 | Aiko | Peek-expand collapsed clusters to target deep children |
| US-078 | P2 | Aiko | Keep an edge type sticky while drawing in VR |
| US-079 | P1 | Aiko | Drill and locomote without inducing vection |
| US-080 | P1 | Aiko | Read SDF labels and icons clearly at any depth in VR |
