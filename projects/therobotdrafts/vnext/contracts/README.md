# HoloGraph vnext Contracts

These contracts are the M0 freeze point for parallel implementation. Lanes own separate trees and
must code against these shapes unless a later milestone explicitly revs the contract.

TRD vnext's primary product surface is a 3D UML workspace with Unity-parity scene semantics.
Flat UML diagrams are projections/exports from the model, not the main renderer.

## Primary 3D Invariants

- `GraphDocument.modelKind` defaults to `uml` for TRD authoring workflows.
- `GraphDocument.view.projection` defaults to `trd-3d-uml` for the main workspace.
- Nodes may carry UML compartments in `node.uml.attributes` and `node.uml.operations`.
- Nodes may carry Unity/Web parity placement in `node.trd3d.position`, `dimensions`, `layer`, and `shape`.
- Edges may carry UML relationship metadata in `edge.uml` and 3D route waypoints in `edge.trd3d`.
- Renderers consume a `GraphDocument -> Trd3dScene` mapping seam before drawing.

## Lanes

| Lane | Owns | Consumes |
| --- | --- | --- |
| BE-CORE | Phoenix domain model, persistence, Liquibase | GraphDocument, PatchBatch |
| BE-API | REST controllers and JSON envelopes | OpenAPI sketch, GraphDocument |
| BE-RT | Phoenix channel protocol | Channel events, PatchBatch |
| FE-SHELL | App routes, panels, command rail, API client | OpenAPI sketch, renderer payload |
| FE-GRAPH | Pure TypeScript layout and graph algorithms | GraphDocument |
| FE-GL | WebGL/WebGPU 3D renderer behind `IRenderer` | Trd3dScene |
| FE-COLLAB | Socket client and collab widgets | Channel events |
| QA | Fixtures, smoke, perf harness | All contracts |

## Exit Rule

M1 is done when a fixture 3D UML GraphDocument can be imported/listed, opened, mapped into a
Trd3dScene, rendered with real 3D nodes/edges/camera controls, selected, focused, drilled,
recentered, and inspected by an automated smoke path.
