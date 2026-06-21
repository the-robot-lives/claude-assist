---
id: ADR-002
title: "Unified internal model (KDM-shaped code-graph as the hub)"
status: accepted
date: 2026-06-21
---

# ADR-002: Unified internal model (KDM-shaped code-graph as the hub)

## Context

The Robot Draft sits at the intersection of three open-ended sets:

- **Inputs.** Source code in many languages (via tree-sitter parsing plus SCIP/LSP indexes and, where
  available, compiler frontends); compiled binaries (via decompilers); and imported models in XMI,
  BPMN, DMN, ArchiMate exchange, Rose petal, and EA native (see
  [`file-formats.md`](../specs/file-formats.md)).
- **Views.** The 3D bubble world plus every projected diagram type — UML, SysML, BPMN, DMN, ArchiMate,
  ERD, and Rose legacy (see [`diagram-catalog.md`](../specs/diagram-catalog.md)).
- **Exports.** The same interchange formats, written back out for round-tripping.

If each input format were wired directly to each view and each export format, the work scales as
**N × M** — every new importer must understand every view and every exporter, and every new diagram
type must understand every input dialect. That combinatorial explosion is unsustainable, and it
spreads format-specific quirks (especially XMI dialect drift between tools) across the entire codebase.

The architecture already commits to a single source of truth ([`ARCHITECTURE.md`](../ARCHITECTURE.md),
[`CONCEPTS.md`](../CONCEPTS.md) § Model vs. projection). This ADR records *what that model is shaped
like* and *why* it is the hub.

## Decision

All ingestion normalizes into **one internal code-graph model**, and **every view and every export is
derived from it**. Inputs never talk to outputs directly.

The internal model is shaped **conceptually like the OMG Knowledge Discovery Metamodel (KDM)** — a
layered code-graph with, at minimum:

- a **Code** layer — callables, types, members, signatures, and the call/usage/inheritance relations
  among them;
- a **Structure** layer — packages, modules, components, and containment;
- a **Data** layer — data definitions, schemas, and data relationships.

We adopt KDM's **shape** (its layering and the kinds of entities and relations it distinguishes),
**not** its serialization. The in-memory representation is our own, tuned for the layout engine and the
renderer.

The pipeline is therefore:

```
import any  →  normalize to internal code-graph (KDM-shaped)  →  derive any view / export any format
```

- **Importers** are responsible only for mapping their format into the internal model.
- **Projectors and exporters** are responsible only for reading the internal model.
- **XMI dialect drift** (Sparx vs. EMF vs. others) is reconciled **at the normalization boundary** in
  the importer — it never leaks past the hub.

## Consequences

- **The N × M problem collapses to N + M.** Adding an input format means writing one importer; adding a
  diagram or export format means writing one reader. Neither needs to know about the other.
- **Clean separation of model and view.** Bubbles, diagrams, and exports are all derivations; none holds
  authoritative state. This is what makes "project a region to UML, edit it, round-trip it back" sound.
- **Dialect quirks are quarantined.** Format-specific weirdness lives in one importer, at one boundary,
  instead of being smeared across views and exporters.
- **The cost is metamodel design.** The model must be **expressive enough** to losslessly absorb the
  union of all inputs (or to record what it cannot represent), yet **stable enough** that views and
  exporters can depend on it. Getting this metamodel right is the central design risk, and it is hard to
  change once importers and exporters depend on it.
- **Some fidelity is mediated, not direct.** Because everything passes through the hub, an export is
  faithful to the *model*, not byte-faithful to the original file. The round-trip strategy in
  [`file-formats.md`](../specs/file-formats.md) manages this explicitly (e.g. preserving Diagram
  Interchange coordinates).

## Alternatives considered

- **Per-format direct converters (point-to-point).** *Rejected.* This is the N × M explosion. It would
  be faster for the first format pair and ruinous by the fifth; it also duplicates dialect handling
  everywhere.
- **Adopt full OMG ASTM/KDM literally** (the standard metamodels and their XMI serializations as our
  in-memory model). *Rejected.* KDM/ASTM are heavyweight and under-tooled; using them as the live
  representation would burden the renderer and layout engine with a serialization-oriented metamodel.
  We take the **shape, not the serialization** — KDM's layering informs the design without dictating the
  in-memory form or forcing KDM XMI on the runtime.

See also [ADR-003](./ADR-003-sphere-packing-bubble-layout.md), which lays this model out, and
[ADR-001](./ADR-001-unity-dots-rendering.md), which renders it.
