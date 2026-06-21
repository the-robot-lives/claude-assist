# Concepts

> The Robot Draft asks you to think about a codebase as a *place*. This document defines the
> vocabulary that makes that work: what a bubble is, how containment nests, the difference
> between the model and the views you see, and why level-of-detail matters. It is conceptual —
> the implementation lives in [`ARCHITECTURE.md`](ARCHITECTURE.md) and the [`specs/`](specs/).

If you only read one thing here, read [Model vs. projection](#model-vs-projection). Most confusion
about the tool comes from conflating the two.

---

## The bubble

A **bubble** is a packed sphere that stands for one element of your software. A method is a
bubble. The class that owns it is a bigger bubble that physically *contains* the method bubbles.
The package that owns the class is a bigger bubble still, containing its class bubbles.

The point of a bubble is that **containment is spatial, not labeled**. In a file tree, "method X
belongs to class Y" is a line of indentation you read. In The Robot Draft, the method bubble is
literally inside the class bubble's volume. You don't parse the relationship — you see it, and you
can fly into it.

```
Package bubble
  └── Class bubble
        ├── Method bubble
        ├── Method bubble
        └── Field bubble
```

A bubble has a size (roughly, how much it contains or how significant it is), a position assigned
by the layout engine, and a visual treatment defined in
[`specs/design-conventions.md`](specs/design-conventions.md). What it does *not* have is authority:
a bubble is a rendering of a model element, never the element itself.

---

## Containment and nesting

Bubbles nest by **strict containment**: a child bubble is fully inside its parent's volume, and a
bubble has exactly one parent. This mirrors the ownership hierarchy in the model — a method is
owned by one type; a type is declared in one package.

Containment is computed bottom-up. Members are sized and packed into their type's bubble; types
are packed into their package's bubble; packages are packed into the workspace. This ordering
means a local change (adding a method) re-packs only the affected type and ripples upward gently,
rather than reshuffling the entire world. Sibling stability is a deliberate property: your mental
map of "where things are" survives edits.

Containment is the bubble view's structural backbone, but it is not the only relationship that
matters — calls, type usage, and inheritance cross containment boundaries freely. Those are
**edges** (below), drawn as connections rather than nesting.

---

## The hierarchy

The containment hierarchy maps directly onto how software is organized. Each level is a bubble
that holds the next:

| Level | Bubble holds… | Example |
|-------|---------------|---------|
| **Workspace** | modules / packages | the whole loaded repo or artifact set |
| **Module / package** | types | `com.acme.billing`, a .NET namespace, a Go package |
| **Type** | members | a class, struct, interface, enum |
| **Member** | (leaf) | a method, field, property, constructor |

Language differences (namespaces vs. packages vs. modules) are normalized into this shape by
Ingestion, so the hierarchy looks the same whether you loaded C#, Java, Go, or a decompiled JAR.
The mapping rules live in [`specs/reverse-engineering.md`](specs/reverse-engineering.md).

---

## Model vs. projection

This is the central distinction in the whole tool.

The **model** is the semantic graph — the entities, references, call edges, type edges, and
control flow extracted from your code (or imported from a diagram). It is abstract: it has no
geometry, no colors, no notation. It is the truth.

A **view** (or **projection**) is *a particular rendering of part of the model*. The bubble world
is a view. A UML class diagram is a view. A BPMN process is a view. A PlantUML export is a view.
None of them is the model; each is a lens onto it.

> **Example.** A method's control-flow graph is one thing in the model. You can project it as a
> UML *sequence* diagram, a UML *activity* diagram, or a BPMN *process* — three different views,
> one model element. Editing any view edits the model; the others update to match.

Two consequences follow, and they explain most of the tool's behavior:

- **There is no "the diagram."** There is the model, and as many projections of it as you care to
  open. Diagrams never drift from code, because they are derived on demand, not stored.
- **Edits round-trip.** Because every view points at the one model, changing a name in the bubble
  world and changing it in a projected class diagram are the same operation. See the round-trip
  path in [`ARCHITECTURE.md`](ARCHITECTURE.md).

In short: the model is *what the system is*; a projection is *one way of looking at it*.

---

## Navigation primitives

You move through the model with a small set of primitives. Everything the interface offers is a
composition of these.

- **Zoom** — change scale continuously, from whole-system overview down toward a single member.
  Zoom does not change *what* you're looking at, only how close you are.
- **Drill-in** — enter a bubble and make its children your working context. Drilling into a class
  bubble surfaces its method bubbles. This is a context shift, not just a camera move.
- **Focus** — isolate a bubble and what it relates to, dimming everything else. Focus answers
  "show me this and what touches it" without leaving the spatial view.
- **Trace an edge** — follow a relationship (a call, an inheritance link, a type usage) from one
  bubble to another, even across containment boundaries. Tracing is how you read behavior that
  containment alone can't show.
- **Project-to-diagram** — take the current region and render it as standard notation (UML, SysML,
  BPMN, …). This is the hand-off from exploration to a conventional deliverable, defined in
  [`specs/diagram-catalog.md`](specs/diagram-catalog.md).

These compose: focus a class, trace its callers, then project the result as a UML communication
diagram.

---

## Edges

An **edge** is a non-containment relationship between bubbles — a call (caller → callee), a type
usage, an inheritance or implementation link, a reference. Where containment is shown by nesting,
edges are shown by **connections** drawn between bubbles, and by the relational projections.

Edges are why the bubble view alone is not enough. Containment tells you *what owns what*; edges
tell you *what talks to what*. A call from a method in one package to a method in another is an
edge that crosses two containment boundaries — invisible to nesting, central to understanding.
When you **trace an edge** or **project to a diagram**, you are working with edges rather than
containment.

---

## Level of detail as a first-class concept

Level of detail (LOD) is not a rendering afterthought here — it is part of the conceptual model,
because you genuinely cannot look at a million bubbles at once.

A **collapsed** bubble is one whose interior you are not currently inside. A collapsed package
bubble does not draw its thousands of descendants; it draws as a single **HLOD proxy** — one
impostor bubble standing in for everything it contains. As you drill in, the proxy expands into
its real children; as you pull back, children collapse back into proxies.

> **Example.** A 40,000-class monorepo, viewed from the top, is a few dozen package proxies —
> cheap to render and easy to read. Fly into one and it unpacks into its classes; the rest of the
> system stays collapsed.

HLOD proxies are what let the overview be both honest (every element is *represented*) and fast
(most elements are not *drawn*). The proxy is a real, navigable object — you focus it, trace edges
to it, and project it. The rendering mechanics are in
[`specs/rendering-and-vr.md`](specs/rendering-and-vr.md); conceptually, just hold onto this:
**a collapsed package = one HLOD proxy**.

---

## Prior art: "code city" vs. bubbles

The Robot Draft is not the first tool to put code in 3D. The best-known prior metaphor is the
**code city**: a package is a *district*, a class is a *building*, and a building's height or
footprint encodes a metric (lines of code, method count). Code city is a real, validated idea, and
it shares The Robot Draft's core bet — that spatial layout makes large systems comprehensible.

The Robot Draft chooses **sphere-packing bubbles** instead, for specific reasons:

- **Containment is volumetric, not adjacency.** In a city, a building sits *next to* others in a
  district; the "belongs to" relationship is implied by a flat ground plane. Packed spheres make
  containment a true nesting — child *inside* parent — which extends cleanly to arbitrary depth
  (member in type in package in module).
- **Continuous LOD.** Spheres collapse into a single proxy sphere naturally; a district of
  buildings has no equally clean single-object collapse. HLOD falls out of the bubble metaphor.
- **VR fly-through.** Flying *into* nested volumes is a more natural head-mounted motion than
  navigating a ground plane of buildings, and it matches the zoom/drill primitives.

The trade-off is that buildings make a single scalar metric (height) very legible, while bubbles
encode magnitude through size and containment. The Robot Draft accepts that trade to get true
nesting and clean LOD. The rationale is recorded in the [ADRs](adrs/).

---

## Glossary

| Term | Definition |
|------|------------|
| **Bubble** | A packed sphere representing one model element (package, type, or member). A rendering, never the element itself. |
| **Model** | The semantic code-graph — entities, references, calls, type edges, CFG. The single source of truth. |
| **Projection** | A rendering of a model region into a specific notation (UML, SysML, BPMN, …) or layout. Synonym for a derived view. |
| **View** | Any rendering of the model: the bubble world, a diagram, a PlantUML export. None is authoritative. |
| **Containment** | Strict spatial nesting — a child bubble lives inside its single parent's volume; mirrors ownership in the model. |
| **Edge** | A non-containment relationship between bubbles: call, reference, inheritance, type usage. Shown as a connection. |
| **Workspace** | The top of the containment hierarchy — the whole loaded repo or artifact set. |
| **Drill (drill-in)** | Enter a bubble and make its children the working context. |
| **Focus** | Isolate a bubble and its related elements, dimming the rest, without leaving the spatial view. |
| **Trace** | Follow an edge from one bubble to another, across containment boundaries. |
| **Zoom** | Continuous change of scale; how close you are, not what you're looking at. |
| **LOD** | Level of detail — how much of a region is actually drawn at the current distance. A first-class concept. |
| **HLOD proxy** | The single impostor bubble that stands in for a collapsed bubble's entire contents. A collapsed package = one HLOD proxy. |
| **Lifeline** | In a projected UML sequence diagram, the vertical line representing one participant's lifetime; the sequence projection of a control-flow path. |
| **Reverse-compile** | Lifting bytecode, IL, or native binaries back toward readable source/model so source-less dependencies become navigable. |
| **Round-trip** | Editing a view, applying the change to the model, and re-deriving all other views (and code/exports) from it. |

---

## Related documents

- [`ARCHITECTURE.md`](ARCHITECTURE.md) — the pipeline that produces and renders these concepts
- [`specs/diagram-catalog.md`](specs/diagram-catalog.md) — how model regions project to each notation
- [`specs/rendering-and-vr.md`](specs/rendering-and-vr.md) — bubble layout and HLOD mechanics
- [`specs/reverse-engineering.md`](specs/reverse-engineering.md) — how source/binaries map to the hierarchy
- [`specs/design-conventions.md`](specs/design-conventions.md) — bubble sizing, color, and interaction rules
- [`README`](../README.md) — product overview
