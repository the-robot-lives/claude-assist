# arch/implementation-status.md — Designed vs. Built

The Robot Draft's design (`ARCHITECTURE.md`) describes a six-subsystem pipeline targeting a DOTS
bubble world in VR. The committed Unity code implements a **vertical slice** of that vision: an
interactive **standard-UML editor** (2D harness + real 3D mesh scene) over a UI-agnostic authoring
core, with deterministic + LLM code↔model round-tripping. This document maps the as-built code to
the designed architecture so engineers know what exists today and what is still on paper.

## As-built component map

| Designed subsystem | Current implementation | Where |
|--------------------|------------------------|-------|
| Unified Model | In-memory authoring model: elements (kind, name, containment parent, modifiers), ids, relationship kinds | `Assets/Scripts/Authoring/Model/` |
| — rules & commands | Legality checks with human reasons; undo/redo command stack; affordance/controller state | `Authoring/Rules/`, `Authoring/Commands/`, `Authoring/State/` |
| Ingestion (source) | Deterministic structural parser (C# strong; TS/Java light) + LLM JSON parser as fallback — paste code → model | `Assets/Scripts/CodeGen/CodeStructParser.cs`, `CodeParser.cs` |
| Ingestion (binary) | Not implemented (no decompilers) | — |
| Layout engine | 2D harness layout (packages as tabs, classifier boxes, edge routing); 3D Z-layer placement. Real sphere packer is a seam only | `Uml/UmlCanvas.Layout.cs`, `Uml3D/`, `Authoring/Seams/IPacker.cs` |
| Render pipeline | uGUI 2D canvas + procedural 3D mesh slabs with world-space compartment canvases, 6-DOF camera rig. **No DOTS, no HLOD, no VR yet** | `Uml/UmlCanvas.cs`, `Uml3D/Uml3DScene.cs`, `UmlCameraRig.cs`, `UmlNode3D.cs` |
| Diagram projection | Standard-UML class diagrams: classifier boxes w/ compartments, UML arrowheads, member visibility glyphs. Other notations not built | `Uml/UmlNodeView.cs`, `UmlEdgeView.cs`, `UmlMemberSignature.cs` |
| — code generation | model → source: deterministic skeleton (C#/Java/TS/Python) + LLM elaboration | `CodeGen/CodeSkeleton.cs`, `CodeGenContext.cs`, `Uml/UmlCanvas.CodeGen.cs` |
| Interchange | Diagram → PNG snapshot + OS clipboard (macOS `osascript`); persistence save/load. No XMI/Rose/EA/BPMN | `Uml/UmlImageClipboard.cs`, `Uml/UmlCanvas.Persistence.cs` |
| LLM access | Dependency-free OpenAI-compatible `/chat/completions` client + settings | `Assets/Scripts/Llm/` |

## What works end-to-end today

1. **Code → model → diagram.** Paste source; the structural parser (or LLM fallback) produces a
   `ParsedModel`; `UmlCanvas.CodeImport` materializes it as UML classifier boxes + relationships.
2. **Interactive editing.** Add containment-filtered elements, draw typed relationships with proper
   UML arrowheads, move/resize boxes, undo/redo — all against the shared authoring core.
3. **Model → code.** Walk the model into a `CodeGenContext`, emit a deterministic skeleton, and
   optionally elaborate via the LLM; display highlighted in a read-only viewer with Copy/Approve.
4. **3D view.** The same model renders as lit 3D slabs on Z-layers with a 6-DOF orbit/dolly/fly
   camera and dashed/arrowed 3D edges.
5. **Export.** Snapshot the diagram to PNG and the OS clipboard.

## Key architectural seam

`Authoring/` is **pure logic with no `UnityEngine` UI dependency**, so the identical model, rules,
commands, and controller back both the 2D `Uml/` harness and the 3D `Uml3D/` scene. The 2D harness
is an explicit desktop stand-in for the planned DOTS bubble renderer; the real spatial packer lives
behind `Seams/IPacker.cs` and will own true 3D bubble layout (ADR-003) without changing the core.

## Notable runtime constraints

- **No `System.Text.Json`** in the Unity player runtime → both `LlmClient` and `CodeParser` use
  `JsonUtility`-shaped DTOs (a single root object with a named array of items).
- **Legacy uGUI rich text has no entity escaping** → `CodeHighlighter` substitutes look-alike angle
  brackets (‹ › U+2039/203A) in the *display* string only; the raw source is kept separately.
- Heavy parse/LLM calls run off the UI thread (coroutine + `UnityWebRequest`); the caller owns the
  request lifecycle.

## Gap to the design target

Not yet started: DOTS/ECS rendering, GPU indirect draws, octree culling, HLOD proxies, VR
stereo/foveation, compiler-grade ingestion frontends (Roslyn/Clang/JDT/TS/go), decompiler binary
path, identity-preserving interchange (XMI/Rose/EA/BPMN), and notations beyond UML class diagrams.
