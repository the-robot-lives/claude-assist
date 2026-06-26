# arch/unified-model.md — Unified Model

The Unified Model is a single in-memory **code-graph** that every other subsystem reads from. It
is the one rule the whole architecture rests on: **the model is the single source of truth** —
bubbles, diagrams, and exports are all *views*, and nothing carries authoritative state outside it.

## Shape

Conceptually organized like the OMG **KDM** (Knowledge Discovery Metamodel) layers — Code,
Structure, Data — but populated by mature tooling (compiler frontends, decompilers, importers)
rather than a KDM-conformant extractor. KDM is the *organizing schema*, not the import format.

| Element | Examples |
|---------|----------|
| **Entities** | packages, namespaces, modules, types, methods, fields, variables |
| **References** | symbol uses, imports, inheritance/implementation links |
| **Call edges** | caller → callee, including virtual/dynamic dispatch candidates |
| **Type edges** | declared type, generic instantiation, parameter and return types |
| **CFG** | per-method control-flow graphs (for sequence/activity projection) |

## Properties

- **Imported diagrams are first-class.** An XMI file, a Rose petal model, or a BPMN document lands
  in the model as entities and edges — not a sidecar. A class imported from XMI and one extracted
  from Roslyn occupy the same graph and can be related, laid out, and re-exported identically. This
  is what makes round-trip and cross-source comparison possible.
- **Stable under re-ingestion.** Re-analyzing a changed file produces a *diff* against the existing
  graph rather than a wholesale rebuild, so views and camera position survive edits.

## As built

The current Unity code implements the model as an in-memory **authoring model**: elements with a
kind, name, containment parent, and modifiers; stable ids; and relationship kinds — under
`Assets/Scripts/Authoring/Model/`. The full KDM-shaped graph (references, call edges, CFG) is
designed but not yet populated.

→ Further reading: [../ARCHITECTURE.md §2](../ARCHITECTURE.md), [../CONCEPTS.md (model vs. projection)](../CONCEPTS.md#model-vs-projection), [decisions.md](decisions.md) (ADR-002).
