# arch/projection-and-interchange.md — Diagram Projection & Interchange

These two subsystems bridge the 3D model world and the conventional deliverables engineers still
need to read, review, and ship.

## Diagram projection

Projection turns a **region of the model** into **standard diagram notation**. It takes a selected
sub-graph (e.g. "this package and its callers") plus a target notation and produces a 2D diagram laid
out by the relational [layout engine](layout.md). Projection is **non-destructive** — it reads the
model and produces a view — and the *same* region can be projected into *different* notations (a
method's CFG becomes a UML sequence diagram or a BPMN process, depending on the lens).

Supported families: **UML 2.5.1** (all 14 diagram types), **SysML / BPMN 2.0 / DMN / ArchiMate**,
**ERD / DDL**, and legacy **Rational Rose** models. A **UI-wireframe** family also projects a
Screen/Panel region — its ordered widget tree — into a low-fidelity mockup, targeting PlantUML
`salt` as the interchange vocabulary.

## Interchange

Interchange moves models across the tool boundary. **Import** parses an external format into the
Unified Model (imported elements are first-class). **Export** serializes a model region, usually
after projection.

| Direction | Formats |
|-----------|---------|
| **Import** | XMI, Rose petal files, EA native repositories, BPMN/DMN/ArchiMate exchange XML |
| **Export** | XMI, BPMN/DMN/ArchiMate exchange XML, PlantUML, Mermaid, DOT, SVG, PNG |
| **Round-trip** | XMI and the exchange-XML families preserve identity for re-import |

Text formats (PlantUML, Mermaid, DOT) and raster/vector renders (SVG, PNG) are export-oriented —
good for docs and review, lossy on re-import. Identity-preserving formats (XMI, the exchange XMLs)
are what the round-trip path relies on.

## As built

Projection is implemented for **standard-UML class diagrams** only: classifier boxes with
stereotype/attributes/operations compartments (`Uml/UmlNodeView.cs`), UML arrowheads and end
decorations (`UmlEdgeView.cs`), and member-visibility glyphs (`UmlMemberSignature.cs`). A second
projection target is built: **UI wireframes** — a Screen/Panel region's widget tree projects to a
standalone **HTML mockup** and a **PlantUML `salt`** block (`CodeGen/WireframeSkeleton.cs`,
`WireframeContext.cs`), both offline/deterministic. The HTML export can be themed by the resolved
**styleguide** engine (`Assets/Scripts/Styleguide/`, a port of the Noizu styleguide css-gen
pipeline) so the mockup carries real design tokens as a `:root{}` variable block.

Interchange is otherwise limited to **export**: PNG snapshot pushed to the OS clipboard
(`Uml/UmlImageClipboard.cs`, macOS `osascript`) and diagram save/load (`Uml/UmlCanvas.Persistence.cs`).
No XMI/Rose/EA/BPMN import or export yet, and no diagram notations beyond UML class diagrams + the
wireframe path.

→ Further reading: [../specs/diagram-catalog.md](../specs/diagram-catalog.md), [../specs/file-formats.md](../specs/file-formats.md), [../ARCHITECTURE.md §5–§6](../ARCHITECTURE.md).
