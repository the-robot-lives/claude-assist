# HoloGraph vnext Contracts

These contracts are the M0 freeze point for parallel implementation. Lanes own separate trees and
must code against these shapes unless a later milestone explicitly revs the contract.

## Lanes

| Lane | Owns | Consumes |
| --- | --- | --- |
| BE-CORE | Phoenix domain model, persistence, Liquibase | GraphDocument, PatchBatch |
| BE-API | REST controllers and JSON envelopes | OpenAPI sketch, GraphDocument |
| BE-RT | Phoenix channel protocol | Channel events, PatchBatch |
| FE-SHELL | App routes, panels, command rail, API client | OpenAPI sketch, renderer payload |
| FE-GRAPH | Pure TypeScript layout and graph algorithms | GraphDocument |
| FE-GL | Canvas/WebGL renderer behind `IRenderer` | ScenePayload |
| FE-COLLAB | Socket client and collab widgets | Channel events |
| QA | Fixtures, smoke, perf harness | All contracts |

## Exit Rule

M1 is done when a fixture GraphDocument can be imported/listed, opened, packed into a ScenePayload,
rendered, selected, focused, drilled, recentered, and inspected by an automated smoke path.
