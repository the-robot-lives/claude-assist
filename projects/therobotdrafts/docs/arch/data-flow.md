# arch/data-flow.md — Data Flow & Round-Trip

The pipeline reads left-to-right (input → ingestion → model → layout → render; model → projection →
interchange), but **editing flows back**. Because every view points at the one
[Unified Model](unified-model.md), an edit made anywhere updates the model and re-derives every other
view.

## The edit loop

1. **Edit in a view** — rename a method in the bubble world, redraw an association in a projected
   class diagram, or import a revised XMI.
2. **Apply to the model** — the edit becomes a model mutation (the dashed `edits` arrows in the
   pipeline diagram). The model is authoritative; the view was only a lens.
3. **Re-derive dependents** — affected layout, HLOD proxies, open projections, and (for source
   loaded from a repo) generated code are recomputed **incrementally from the diff**.
4. **Export** — when you want a deliverable, project the region and serialize via Interchange.

Source-backed and diagram-backed elements share this loop, which is why a class extracted from
Roslyn and a class imported from XMI behave identically under edit.

## As built

The current code realizes a concrete slice of this loop: **code → model → diagram** (paste source →
`ParsedModel` → materialized UML boxes + edges), **interactive editing** against the shared
authoring core (add containment-filtered elements, draw typed relationships, move/resize, undo/redo
via `Authoring/Commands/UndoStack.cs`), and **model → code** (`UmlCanvas.CodeGen` walks the model
into a `CodeGenContext`, emits a deterministic skeleton, optionally elaborates via the LLM). The
incremental-diff re-derivation across many open projections is designed but not yet built.

One round-trip path **is** built end-to-end via on-disk **shadow files** (`UmlCanvas.Shadow.cs`):
imported/generated source is written to a shadow folder so a node's code opens in an external editor
(VS Code); each opened file is polled for save-time changes, and on save the structural parser
re-reads the edited source and updates the node's members/description — so an edit made *outside*
Unity flows back into the model. LLM-driven refactors (`UmlCanvas.Refactor.cs`) write through the
same path. This is the working instance of "edit anywhere → model mutation → re-derive."

→ Further reading: [implementation-status.md](implementation-status.md), [../ARCHITECTURE.md §The round-trip / edit path](../ARCHITECTURE.md#the-round-trip--edit-path), [../CONCEPTS.md (model vs. projection)](../CONCEPTS.md#model-vs-projection).
