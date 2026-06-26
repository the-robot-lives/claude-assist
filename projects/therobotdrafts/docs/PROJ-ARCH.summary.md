# Project Architecture (Summary) — The Robot Draft

Quick-reference companion to [PROJ-ARCH.md](PROJ-ARCH.md). Keep in sync on significant changes.

## Overview

VR-capable UML/IDE that treats a software system as a navigable 3D space. A one-directional
pipeline around a single shared **Unified Model**: input → ingestion → model → layout → render,
with on-demand diagram **projection** and **interchange**. Two invariants: the model is the single
source of truth (all bubbles/diagrams/exports are views), and heavy work is decoupled from the
frame loop. Repository is **pre-alpha**: the full pipeline is the design target; the committed
Unity code implements a working slice (UML editor: 2D harness + 3D mesh scene over a UI-agnostic
authoring core, with deterministic + LLM code↔model round-trip).

## Core Components

- **Ingestion** — source/binary/diagram → facts (compiler frontends, tree-sitter, decompilers). *Designed; deterministic + LLM source parse built.*
- **Unified Model** — one KDM-shaped code-graph; single source of truth. *Partial (authoring model in code).*
- **Layout engine** — sphere-packing bubbles + Sugiyama/force-directed relational. *Partial (2D/3D harness layout).*
- **Render pipeline** — DOTS/ECS, GPU indirect, octree culling, HLOD, VR stereo/foveation, 90 fps target. *Designed; uGUI/mesh stub today.*
- **Diagram projection** — model region → UML/SysML/BPMN/ERD. *Partial (UML class diagrams built).*
- **Interchange** — XMI/Rose/EA/BPMN + PlantUML/Mermaid/DOT/SVG/PNG. *Partial (PNG/clipboard export).*
- **Authoring core** — UI-agnostic model/rules/commands/controller shared by 2D + 3D. *Built.*
- **CodeGen** — deterministic + LLM code ↔ model bridge. *Built.*

## Data Flow

Pipeline reads left-to-right; editing flows back. Every view points at the one model, so an edit
becomes a model mutation and re-derives all other views (layout, HLOD, projections, generated code)
incrementally from the diff. Source-backed and diagram-backed elements behave identically.

## Technology Stack

Unity 6 (6000.3.18f1), C# (no `System.Text.Json` → `JsonUtility` DTOs), Unity XR/OpenXR; uGUI
today with DOTS/ECS + GPU-driven rendering targeted; OpenAI-compatible LLM endpoint; targeted
ingestion via Roslyn/Clang/JDT/TS/go + tree-sitter/SCIP and ILSpy/CFR/JADX/Ghidra; `make` +
`build-mac.sh` + NUnit EditMode.

## Key Decisions

- Model as single source of truth → non-drifting diagrams, round-trip edits.
- DOTS/ECS over GameObjects → million-element counts in a VR budget (ADR-001).
- Unified internal model, KDM-as-schema; imported diagrams first-class (ADR-002).
- Sphere-packing bubbles over "code city" → volumetric containment + clean LOD (ADR-003).
- Heavy work off the frame loop → render never blocks on analysis.

## Implementation Status

Built end-to-end: code→model→diagram, interactive UML editing (add/connect/move/undo), model→code
(skeleton + LLM), 3D slab view with 6-DOF camera, PNG/clipboard export. Not yet started: DOTS/HLOD/VR
rendering, compiler-grade + decompiler ingestion, identity-preserving interchange, notations beyond
UML class diagrams. See [arch/implementation-status.md](arch/implementation-status.md).
