# File Formats & Model Interchange

Specification of the import/export format surface for **The Robot Draft** and the round-trip fidelity strategy that holds it together.

The Robot Draft is a Unity/VR UML-IDE that reverse-engineers code into a model and projects standard diagrams. To interoperate with the established modeling ecosystem, it must read and write the formats used by Sparx Enterprise Architect, IBM Rational Rose, the Eclipse/EMF world, and the domain-specific XML standards (ArchiMate, BPMN, DMN). This document is the authoritative reference for which formats are supported, which direction each flows, whether each carries diagram layout, and how the engine reconciles the dialect and layout gaps that make naïve UML interchange fail in practice.

**Audience:** engineers implementing the import and export pipelines.

**Related specs:**
- [Diagram Catalog](../specs/diagram-catalog.md) — the diagram types the engine projects from the internal model.
- [Reverse Engineering](../specs/reverse-engineering.md) — how source code becomes the internal model that these formats serialize.
- [Architecture](../ARCHITECTURE.md) — the internal-model hub these importers and exporters plug into.

---

## 1. Summary matrix

Standards-body column: **OMG** (Object Management Group), **OG** (The Open Group), **W3C** (World Wide Web Consortium), **Community** (open/community-governed), **Vendor** (proprietary, single-vendor).

| Format | Extension(s) | Standard body | Import | Export | Carries layout (DI)? | Priority |
|--------|--------------|---------------|:------:|:------:|:--------------------:|----------|
| **XMI** (XML Metadata Interchange) | `.xmi`, `.xml` | OMG | Yes | Yes | Partial — under-specified for UML | **P0** |
| **Rational Rose petal** | `.mdl`, `.cat`, `.sub`, `.ptl`, `.ctl` | Vendor (IBM/Rational) | Yes | Optional | Yes (Rose stores coordinates) | P2 |
| **Sparx EA native** | `.qea`, `.eapx`, `.eap`, `.feap` | Vendor (Sparx) | Yes | `.qea` only (P1); others P3 | Yes | **P0** (`.qea`) |
| **Eclipse UML2 model** | `.uml` | OMG (UML2/MOF, EMF-serialized) | Yes | Yes | No (DI is separate `.notation`) | P1 |
| **EMF Ecore metamodel** | `.ecore` | OMG (MOF realization) | Yes | Optional | No (metamodel, not a diagram) | P2 |
| **Visual Paradigm native** | `.vpp`, `.vpproject` | Vendor (Visual Paradigm) | Via XMI | Via XMI | Yes (internally) | P3 |
| **ArchiMate Model Exchange** | `.xml` | **OG** | Yes | Yes | Yes (Diagram section) | P1 |
| **Archi native** | `.archimate` | Community (Archi tool) | Yes | Yes | Yes | P2 |
| **BPMN 2.0 XML** | `.bpmn`, `.bpmn20.xml` | OMG | Yes | Yes | **Yes — BPMN-DI in-file** | P1 |
| **DMN XML** | `.dmn` | OMG | Yes | Yes | **Yes — DMN-DI in-file** | P2 |
| **PlantUML** | `.puml`, `.plantuml`, `.pu`, `.iuml` | Community | Yes | Yes | No (layout delegated to Graphviz) | P1 |
| **Mermaid** | `.mmd`, fenced ```mermaid | Community | Yes | Yes | No (layout computed by renderer) | P2 |
| **Graphviz DOT** | `.dot`, `.gv` | Community | Yes | Yes | Partial (engine emits coords) | P2 |
| **SVG** | `.svg` | **W3C** | No | Yes | N/A (render target) | P1 |
| **PNG / JPG / GIF / BMP** | `.png`, `.jpg`, `.gif`, `.bmp` | W3C / ISO | No | Yes | N/A (raster render target) | P1 |
| **PDF / EMF / WMF** | `.pdf`, `.emf`, `.wmf` | ISO / Vendor | No | Yes | N/A (render target) | P3 |

> **DI = Diagram Interchange.** "Carries layout" means the file format can store visual coordinates (node positions, edge waypoints, sizes) alongside the semantic model. Where this is **No** or **Partial**, the engine must synthesize layout on import — see [§7 Round-trip fidelity strategy](#7-round-trip-fidelity-strategy).

---

## 2. OMG-standard interchange: XMI

**XMI (XML Metadata Interchange)** is the OMG's canonical serialization for UML and MOF-based models. It is the single most important interchange format for The Robot Draft and the one most prone to failure in practice.

### 2.1 Version landscape

| XMI version | Era / metamodel | Tool association |
|-------------|-----------------|------------------|
| 1.0 / 1.1 / 1.2 | UML 1.x, MOF 1.x | Rational Rose era, legacy tools |
| 2.0 / 2.1 | UML2, MOF2 | First UML2-capable exporters |
| 2.4.x | UML2 (intermediate) | Mid-generation EA / MagicDraw |
| 2.5.1 | UML 2.5.1, MOF 2.5.1 | Current target — emit this by default |

Importers must accept the full range; the exporter targets **XMI 2.5.1** by default with a configurable downgrade path.

### 2.2 The dialect problem (critical)

XMI is portable on paper and **non-portable in practice.** The specification leaves enough latitude that every vendor emits a distinct dialect. A file labeled "XMI 2.1" from one tool will not load cleanly in another. Concretely, importers must tolerate variation across:

- **Vendor dialects** — EA XMI, Eclipse UML2 XMI, and MagicDraw XMI differ in element nesting, ID schemes, and use of extension sections (`<xmi:Extension>`).
- **Metamodel namespace versions** — the `xmlns:uml` URI (e.g. UML 2.1 vs 2.4 vs 2.5) changes element and attribute names.
- **ID and href conventions** — `xmi:id` vs `xmi:uuid`, intra-file `idref` vs cross-file `href` proxies.
- **Profile/stereotype encoding** — applied stereotypes serialize differently per tool.

The engine handles this with a **multi-dialect parser plus a normalization layer** (see [§7.1](#71-xmi-dialect-drift)). Never assume a single canonical XMI shape.

### 2.3 The DI gap

UML XMI historically **under-specifies diagram layout.** The OMG Diagram Definition / Diagram Interchange (DD/DI) standard exists, but UML-tool adoption is inconsistent: many exporters omit coordinates entirely or stash them in vendor-proprietary `<xmi:Extension>` blocks. Treat layout as **likely absent** on UML XMI import and plan a layout-synthesis fallback ([§7.2](#72-the-dilayout-gap)).

---

## 3. Tool-native model files

These are the proprietary on-disk formats of the major commercial modeling tools. Reading them directly (rather than requiring the user to pre-export XMI) is a significant interoperability advantage.

### 3.1 IBM Rational Rose — petal files

Rose stores models in a proprietary **LISP-like textual "petal" syntax.** A model is split across several file types:

| Extension | Role |
|-----------|------|
| `.mdl` | Main model file — the root of a Rose model |
| `.cat` | Controlled **category** — a logical package unit under version control |
| `.sub` | Controlled **subsystem** — a component package unit under version control |
| `.ptl` | Petal **export** file |
| `.ctl` | **Control** file |

Petal files **do carry diagram coordinates,** so Rose imports can recover layout. The parser must reassemble a model from its `.mdl` root plus referenced `.cat` / `.sub` fragments. Export to petal is optional (P2) and lower priority than reading legacy Rose models in.

### 3.2 Sparx Enterprise Architect — native repositories

EA stores its repository in a relational database. The on-disk container format has evolved:

| Extension | Underlying store | Notes |
|-----------|------------------|-------|
| `.eap` | MS JET / Access `.mdb` | Legacy. Widest install base in older projects. |
| `.eapx` | Access ACE format | Newer Access-engine variant of `.eap`. |
| `.qea` | **SQLite database** | **Current default (EA 16+). Recommended modern format — read and write this first.** |
| `.feap` | Firebird database | Less common alternative. |

EA can also host the repository in an **external DBMS** — SQL Server, PostgreSQL, MySQL, or Oracle — using the same logical schema. Importers should target the EA logical schema rather than the file container, so the SQLite path (`.qea`) and a future external-DBMS path share table-mapping code.

EA native files carry full diagram layout. Priority: **`.qea` import is P0; `.qea` export is P1; `.eap`/`.eapx`/`.feap` are P3 (read-mostly, legacy).**

### 3.3 Eclipse / EMF

The Eclipse Modeling Framework distinguishes **metamodels** from **model instances,** and both are XMI-serialized:

| Extension | What it is | Layer |
|-----------|-----------|-------|
| `.ecore` | EMF **Ecore** metamodel — EMF's realization of OMG MOF | Metamodel (M2) |
| `.uml` | Eclipse UML2 / MDT model serialization (an XMI-based EMF resource) | Instance (M1) |

`.ecore` files **describe metamodels;** `.uml` files are **instances** of the UML metamodel. Because both are XMI under the hood, they route through the XMI pipeline ([§2](#2-omg-standard-interchange-xmi)) with EMF-specific dialect handling. Note that Eclipse keeps **diagram notation in a separate `.notation` file,** not in the `.uml` model — so a `.uml` import without its companion notation file has no layout.

### 3.4 Visual Paradigm

Visual Paradigm's native project format is `.vpp` / `.vpproject`. The Robot Draft interoperates with Visual Paradigm via **XMI import/export and image export** rather than parsing the proprietary project binary directly (P3).

---

## 4. Domain-specific XML standards (layout-carrying, genuinely portable)

These formats succeed where UML XMI struggles: each is a tightly specified XML schema that bundles the **semantic model and its diagram layout in a single file.** They round-trip reliably and should be treated as first-class, high-fidelity citizens.

### 4.1 ArchiMate Model Exchange File Format — Open Group

A **vendor-neutral exchange format** (`.xml`) conforming to The Open Group's ArchiMate Model Exchange File XSD. It carries the model plus a diagram section with coordinates, so layout survives the round trip.

- **`.xml` (Open Group exchange)** — the portable interchange format. Support import **and** export.
- **`.archimate` (Archi native)** — the Archi tool's distinct internal XML format. Support both; they are **not** the same schema.

### 4.2 BPMN 2.0 XML — OMG

`.bpmn` (also seen as `.bpmn20.xml`). BPMN 2.0 defines **both the semantic model and BPMN-DI (Diagram Interchange) for layout** in one file, so a single document carries process semantics **and** visual coordinates. Genuinely portable — round-trips with high fidelity.

### 4.3 DMN XML — OMG

`.dmn`. Carries the decision model — Decision Requirements Graph (DRG) / Decision Requirements Diagram (DRD), decision tables, **DMN-DI** layout, and **FEEL** expressions — in one file. Like BPMN, it is self-contained and portable.

> **Why these are easier:** because BPMN-DI, DMN-DI, and the ArchiMate Diagram section are mandatory, well-specified parts of each schema, layout is never lost. Contrast with UML XMI ([§2.3](#23-the-di-gap)), where DI adoption is optional and inconsistent.

---

## 5. Diagram-as-code / lightweight text formats

Text DSLs that describe diagrams declaratively and **delegate layout to a graph-drawing engine.** None store explicit coordinates; layout is recomputed on each render. Valuable for code-review-friendly diffs, documentation pipelines, and quick authoring.

| Format | Extension(s) | Engine / runtime | Layout source |
|--------|--------------|------------------|---------------|
| **PlantUML** | `.puml`, `.plantuml`, `.pu`, `.iuml` | PlantUML | Delegates to Graphviz |
| **Mermaid** | `.mmd`, fenced ```mermaid in Markdown | Mermaid (JS) | Computed by the JS renderer |
| **Graphviz DOT** | `.dot`, `.gv` | Graphviz | The DOT layout engine itself |

- **PlantUML** — text DSL covering class, sequence, state, component, and more; layout is delegated to Graphviz.
- **Mermaid** — JS text-to-diagram supporting flowchart, sequence, class, state, ER, and gantt; commonly embedded as fenced ` ```mermaid ` blocks in Markdown.
- **Graphviz DOT** — the DOT language and its layout engine; it is the **underlying layout engine for PlantUML and many other tools,** which makes it the natural choice for the engine's own layout-synthesis fallback ([§7.2](#72-the-dilayout-gap)).

Because these formats carry no stored layout, importing them produces a semantic graph whose positions are synthesized; exporting them discards The Robot Draft's stored coordinates and emits pure structure.

---

## 6. Export / render targets

Pixel- and vector-output formats. **Render targets are export-only** — the engine does not reverse-engineer a model from an image.

| Format | Extension(s) | Standard body | Use |
|--------|--------------|---------------|-----|
| **SVG** | `.svg` | **W3C** | **Preferred** vector / archival / interactive render |
| **PNG** | `.png` | W3C / ISO | Default raster render |
| **JPG / GIF / BMP** | `.jpg`, `.gif`, `.bmp` | ISO / community | Alternate raster targets |
| **PDF** | `.pdf` | ISO 32000 | Print / document embedding |
| **EMF / WMF** | `.emf`, `.wmf` | Vendor (Microsoft) | Office / Windows vector embedding |

**SVG is the preferred render target** for vector, archival, and interactive use; PNG is the default raster export. PDF, EMF, and WMF are companion targets (P3).

---

## 7. Round-trip fidelity strategy

Two risks dominate interoperability. Both are addressed by routing every format through a single **internal-model hub.**

### 7.1 XMI dialect drift

**Risk:** XMI is non-portable in practice ([§2.2](#22-the-dialect-problem-critical)). Vendor dialects and metamodel namespace versions mean no single parser handles all XMI.

**Mitigation — multi-dialect parsing + normalization layer:**

1. **Detect** the dialect on import — inspect the `xmlns:uml` / `xmlns:xmi` namespaces, the XMI version attribute, and vendor `<xmi:Extension>` markers to classify the source (EA, Eclipse UML2, MagicDraw, Rose-era, …).
2. **Parse** with a dialect-specific reader that understands that tool's nesting, ID scheme (`xmi:id` vs `xmi:uuid`), and stereotype encoding.
3. **Normalize** the parse result into the unified internal model — one canonical element vocabulary independent of any source dialect.
4. **Emit** from the internal model through a dialect-specific writer (default XMI 2.5.1), so export shape is decoupled from whatever was imported.

The normalization layer is the contract: importers and exporters never talk to each other, only to the internal model.

### 7.2 The DI / layout gap

**Risk:** layout availability is uneven. BPMN-DI, DMN-DI, and the ArchiMate Diagram section carry coordinates; Rose petal and EA native carry coordinates; **UML XMI and the diagram-as-code formats often do not.** A model imported without coordinates cannot be projected into VR without positions.

**Mitigation — layout-engine fallback:**

| On import, layout is… | Action |
|-----------------------|--------|
| **Present** (BPMN/DMN/ArchiMate/EA/Rose/explicit DI) | Preserve source coordinates verbatim; store in the internal model. |
| **Absent** (UML XMI without DI, PlantUML, Mermaid, DOT, `.uml` without `.notation`) | **Synthesize** layout with a graph-layout engine — Graphviz or ELK (Eclipse Layout Kernel) — and flag positions as engine-generated. |

Synthesized positions are marked as such so a later round trip can distinguish authored layout from generated layout and avoid overwriting a user's hand-placed coordinates.

### 7.3 Internal-model-as-hub

The engine never converts format-to-format directly. Every path goes **import any → normalize to the internal model → export any:**

```
                       ┌─────────────────────────┐
  XMI (all dialects) ─▶│                         │─▶ XMI 2.5.1
  Rose petal         ─▶│                         │─▶ EA .qea
  EA .qea/.eap*      ─▶│   INTERNAL MODEL (hub)  │─▶ ArchiMate exchange
  Ecore / .uml       ─▶│                         │─▶ BPMN / DMN
  ArchiMate / Archi  ─▶│   - canonical elements  │─▶ PlantUML / Mermaid / DOT
  BPMN / DMN         ─▶│   - normalized layout   │─▶ SVG / PNG / PDF
  PlantUML/Mermaid/  ─▶│     (authored vs synth) │
    DOT              ─▶│                         │
                       └─────────────────────────┘
                              ▲           ▲
                   layout synthesis   reverse-engineering
                   (Graphviz / ELK)   (see reverse-engineering.md)
```

Benefits:

- **N importers + M exporters,** not N×M converters.
- A single normalization contract is the only place dialect knowledge lives.
- Layout provenance (authored vs synthesized) is tracked once, centrally.
- New formats plug in by writing one importer and/or one exporter against the hub.

See [Architecture](../ARCHITECTURE.md) for the internal model's structure and [Reverse Engineering](../specs/reverse-engineering.md) for the code-to-model path that also feeds the hub.

---

## 8. Recommended import/export priority tiers

Priority reflects ecosystem reach and round-trip value, not implementation difficulty.

### P0 — Must ship first

| Format | Direction | Rationale |
|--------|-----------|-----------|
| **XMI** (multi-dialect import, 2.5.1 export) | Import + Export | The universal interchange; nothing else interoperates broadly without it. |
| **Sparx EA `.qea`** | Import (+ P1 export) | Dominant commercial tool; SQLite format is the modern default and carries full layout. |

### P1 — High value, layout-rich

| Format | Direction | Rationale |
|--------|-----------|-----------|
| **EA `.qea` export** | Export | Completes the EA round trip. |
| **Eclipse `.uml`** | Import + Export | Large open-source/EMF user base. |
| **ArchiMate Model Exchange (`.xml`)** | Import + Export | Open Group standard; self-contained layout. |
| **BPMN 2.0 XML** | Import + Export | OMG standard; BPMN-DI gives lossless round trips. |
| **PlantUML** | Import + Export | Code-friendly authoring and docs pipelines. |
| **SVG / PNG** | Export | Core render deliverables. |

### P2 — Valuable, defer if needed

| Format | Direction | Rationale |
|--------|-----------|-----------|
| **Rational Rose petal** (`.mdl`/`.cat`/`.sub`) | Import (export optional) | Legacy model recovery; declining but high-value archives. |
| **EMF `.ecore`** | Import (export optional) | Metamodel awareness; supports profile/stereotype fidelity. |
| **DMN XML** | Import + Export | OMG standard; pairs with BPMN. |
| **Archi `.archimate`** | Import + Export | Common ArchiMate authoring tool. |
| **Mermaid** | Import + Export | Lightweight docs/diagram-as-code. |
| **Graphviz DOT** | Import + Export | Also the layout-synthesis engine. |

### P3 — Long tail / legacy

| Format | Direction | Rationale |
|--------|-----------|-----------|
| **EA `.eap` / `.eapx` / `.feap`** | Import (read-mostly) | Legacy EA containers; map to the same logical schema as `.qea`. |
| **Visual Paradigm `.vpp` / `.vpproject`** | Via XMI | Interop through XMI rather than native parsing. |
| **PDF / EMF / WMF** | Export | Print and Office-embedding companions. |

---

## Appendix A — Standards-body reference

| Body | Standards owned (relevant here) |
|------|--------------------------------|
| **OMG** (Object Management Group) | UML, SysML, BPMN, DMN, UAF/UPDM, **XMI**, **MOF** (Ecore is EMF's MOF realization) |
| **The Open Group** | ArchiMate, TOGAF, **ArchiMate Model Exchange File Format** |
| **W3C** | **SVG** |
| **Community / open** | PlantUML, Mermaid, DOT/Graphviz |
| **Vendor** | Rose petal (IBM/Rational), EA native (Sparx), Visual Paradigm native, EMF/WMF (Microsoft) |
