# The Robot Draft

> A high-performance, VR-capable UML/IDE that lets you fly through a codebase as a living
> 3D model — navigate functions and types as nested "bubbles," reverse-engineer source and
> binaries into standard diagrams, and round-trip back to code. Built on Unity, tuned to
> render very large systems fast and cleanly.

**Status:** Pre-alpha — specification & design phase. The repository holds the design corpus
under [`docs/`](docs/) plus an **initial Unity 6.3 stub** that opens and renders a "Coming Soon"
splash (see [Running the stub](#running-the-stub)). The bubble-view application itself is not
built yet.

---

## What it is

The Robot Draft treats a software system as a **navigable 3D space** rather than a wall of
static diagrams. You load a repository (or a compiled artifact), and the tool reverse-engineers
it into a model you can explore:

- **Bubble view** — packages, types, and functions render as nested, packed spheres ("bubbles").
  Containment is spatial: a class bubble holds its method bubbles; a package bubble holds its
  classes. You zoom from a whole-system overview down to a single function and back without
  losing your place.
- **Reverse engineering** — extract class, dependency, call, and sequence structure from source
  code via compiler-grade frontends (Roslyn, Clang, JDT, the TypeScript checker, `go/types`),
  and from compiled artifacts via decompilers (ILSpy, CFR/JADX, Ghidra).
- **Reverse compile** — lift bytecode/IL and native binaries back toward readable source and
  models, so you can explore a dependency you have no source for.
- **Standard diagrams on demand** — any region of the model can be projected into a conventional
  diagram (UML class, sequence, component, deployment; plus SysML, BPMN, ERD, ArchiMate, and the
  other families that tools like Sparx Enterprise Architect and Rational Rose support).
- **VR-first, desktop-equal** — designed for head-mounted "fly-through" exploration and
  collaborative review, but fully usable on a flat screen with mouse and keyboard.
- **Fast by construction** — a data-oriented (Unity DOTS) and GPU-driven rendering pipeline so
  that million-element graphs stay inside a VR frame budget.

## Why

Traditional UML tools (Sparx EA, Rational Rose, Visual Paradigm) model systems as flat 2D
diagrams that go stale the moment code changes. IDEs navigate code well but show structure only
as trees and text. The Robot Draft's bet is that **spatial, always-live, reverse-engineered
visualization** makes large systems comprehensible in ways neither a diagram editor nor a file
tree can — especially for onboarding, architecture review, and exploring unfamiliar or
source-less code.

## Core capabilities (target)

| Capability | Summary |
|------------|---------|
| Model ingestion | Reverse-engineer source (LSP / compiler frontends / tree-sitter + SCIP) and binaries (decompilers) into a unified internal model. |
| Diagram coverage | Full UML 2.5.1 (14 diagram types), SysML, BPMN 2.0, DMN, ArchiMate, ERD/DDL, and Rational Rose legacy models. See [`docs/specs/diagram-catalog.md`](docs/specs/diagram-catalog.md). |
| Interchange | Import/export XMI, Rose petal files, EA native repositories, BPMN/DMN/ArchiMate exchange XML, PlantUML/Mermaid/DOT, and SVG/PNG renders. See [`docs/specs/file-formats.md`](docs/specs/file-formats.md). |
| Bubble navigation | Nested sphere-packing layout with hierarchical level-of-detail; zoom, drill, and trace across the model. |
| Rendering | Unity DOTS/ECS + GPU-driven indirect draws, octree culling, HLOD, foveated rendering — built to hold 90 fps in VR on large graphs. |
| Round-trip | Edit in the model, regenerate code and standard-format diagrams. |

## Documentation

The design is captured as a structured doc corpus. Start with the architecture overview, then
the specs.

| Document | What it covers |
|----------|----------------|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | System architecture: ingestion → model → layout → render, and the major subsystems. |
| [`docs/CONCEPTS.md`](docs/CONCEPTS.md) | The bubble metaphor, navigation model, and core vocabulary. |
| [`docs/specs/diagram-catalog.md`](docs/specs/diagram-catalog.md) | Every supported diagram type (UML, SysML, BPMN, DMN, ArchiMate, ERD, Rose legacy), with notation and bubble-view mapping. |
| [`docs/specs/file-formats.md`](docs/specs/file-formats.md) | Import/export formats, interchange standards, and round-trip fidelity. |
| [`docs/specs/reverse-engineering.md`](docs/specs/reverse-engineering.md) | How source and binaries become models; the unified code-graph. |
| [`docs/specs/rendering-and-vr.md`](docs/specs/rendering-and-vr.md) | The 3D bubble layout and the performance/VR rendering pipeline. |
| [`docs/specs/unity-6.3-baseline.md`](docs/specs/unity-6.3-baseline.md) | Verified Unity 6.3 LTS engine baseline (graphics, DOTS, XR, scripting) with primary sources. |
| [`docs/specs/unity-6.5-delta.md`](docs/specs/unity-6.5-delta.md) | What changed in Unity 6.4 → 6.5 vs the 6.3 baseline (breaking ECS removals, DOTS core-package renumber, Quest perf, LTS-vs-Tech-Stream guidance). The editor is now `6000.5.1f1`. |
| [`docs/specs/design-conventions.md`](docs/specs/design-conventions.md) | Visual, layout, color, and interaction conventions across diagram types. |
| [`docs/adrs/`](docs/adrs/) | Architecture Decision Records. |

## Project layout

```
therobotdrafts/            ← Unity 6.3 project root
├── README.md              ← you are here
├── Assets/
│   ├── Scenes/Boot.unity  ← entry scene (empty; the splash is built at runtime)
│   └── Scripts/ComingSoonBootstrap.cs  ← stub "Coming Soon" overlay
├── Packages/manifest.json ← package set (resolves for Unity 6.x)
├── ProjectSettings/       ← ProjectVersion.txt etc. (most regenerated by Unity on first open)
└── docs/
    ├── ARCHITECTURE.md
    ├── CONCEPTS.md
    ├── specs/             ← diagram, format, reverse-engineering, rendering, convention specs
    ├── adrs/              ← architecture decision records
    └── diagrams/          ← diagrams of The Robot Draft's own design
```

## Running the stub

1. Install the Unity editor pinned in `ProjectSettings/ProjectVersion.txt`
   (currently **`6000.3.18f1`** — the **6.3 LTS** line the design baseline targets, see
   [`docs/specs/unity-6.3-baseline.md`](docs/specs/unity-6.3-baseline.md)) via Unity Hub. *(The stub
   also opens on 6.5; the 6.4→6.5 deltas are tracked in
   [`docs/specs/unity-6.5-delta.md`](docs/specs/unity-6.5-delta.md).)*
2. **Add** this folder as a project in Unity Hub and open it. Unity regenerates the rest of
   `ProjectSettings/`, resolves packages, and imports `Assets/` on first open.
3. Open `Assets/Scenes/Boot.unity` and press **Play** — you'll see a dark screen with
   **"Coming Soon"** and the subtitle **"The Robot Draft"**.

The splash is a deliberately dependency-free placeholder: `ComingSoonBootstrap` builds a uGUI
overlay at runtime via `[RuntimeInitializeOnLoadMethod]`, so the project renders correctly
without any render-pipeline, scene, or asset wiring. The production shell (URP + Render Graph,
UI Toolkit front-end, DOTS/OpenXR bubble-view renderer) is wired in a later milestone per
[`docs/specs/unity-6.3-baseline.md`](docs/specs/unity-6.3-baseline.md) and
[ADR-001](docs/adrs/ADR-001-unity-dots-rendering.md).

## Building a standalone app

A headless build script produces a standalone player from the command line:

```bash
./build-mac.sh        # builds Builds/macOS/The Robot Draft.app (universal: arm64 + x86_64)
```

It auto-selects an installed editor that has **Mac Build Support** (preferring the pinned
version) and runs `Assets/Editor/BuildMac.cs` in batch mode; the log goes to
`Builds/build-macos.log`. You can also build from the editor menu: **The Robot Draft ▸ Build ▸
macOS**. If no installed editor has Mac Build Support, add it in Unity Hub
(Installs ▸ ⋮ ▸ Add modules ▸ *Mac Build Support*). `Builds/` is git-ignored.

## Status & roadmap

This is a greenfield design effort. The current milestone is a complete, internally consistent
specification of the model, diagram coverage, file formats, and rendering approach — the
foundation a Unity implementation will be built against. See the ADRs for the decisions made so
far and their rationale.

---

*Part of the Noizu portfolio. "The Robot Draft" — drafts, as in drawings; and drafts, as in
the robot's working sketches of your code.*
