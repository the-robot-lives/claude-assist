# Design Conventions

> The Robot Draft has two visual registers. The **3D bubble view** is the tool's novel layer — it
> may invent its own conventions, and this document defines them. The **projected 2D diagrams**
> (UML, BPMN, ArchiMate, and the rest) must look exactly like the standards they implement, so
> they round-trip cleanly and match what Sparx EA or Rational Rose would draw. This document is
> the authoritative reference for both registers: how bubbles look, what colors mean, how edges
> render, how layout is computed, when labels appear, and how a user navigates.

**Audience:** engineers and designers building the renderer, layout engine, and diagram projector.

**Related docs:**

- [`CONCEPTS.md`](../CONCEPTS.md) — the vocabulary (bubble, containment, model vs. projection, HLOD).
- [`diagram-catalog.md`](../specs/diagram-catalog.md) — the diagram types projected from the model.
- [`rendering-and-vr.md`](../specs/rendering-and-vr.md) — the GPU pipeline, LOD system, and VR comfort model that this document's visuals run on top of.
- [`ARCHITECTURE.md`](../ARCHITECTURE.md) — the pipeline these conventions plug into.

---

## 0. The two registers

| Register | What it is | Convention authority |
|----------|-----------|----------------------|
| **3D bubble view** | The packed-sphere navigation space (package → class → method). | This document. The tool owns these conventions. |
| **Projected 2D diagrams** | A model region rendered as standard notation (UML/SysML/BPMN/DMN/ArchiMate/ERD/Rose). | The governing OMG / Open Group / W3C standard. This document only records *which* standard applies. |

**Notation fidelity principle.** When the engine projects a model region to a standard diagram, it
conforms to that notation **precisely** — line styles, arrowheads, decorations, and layout idioms
match the spec so exports are interoperable and round-trip through XMI/BPMN/DMN/ArchiMate exchange.
The 3D bubble view is free to be novel; projections are not. Where this document and a standard
disagree about a projected diagram, **the standard wins**.

---

## 1. Bubble visual language

A bubble is a packed sphere standing for one model element. Three independent channels carry meaning,
and they are kept independent so a user can read each without decoding the others:

| Channel | Encodes | Mapping |
|---------|---------|---------|
| **Size** (radius) | Magnitude — contained mass or significance | Members: scaled by LOC / statement count. Containers: derived bottom-up from packed children (see [`CONCEPTS.md`](../CONCEPTS.md) § Containment). |
| **Hue** | Element **kind** (and, in modeling-language regions, standard layer color) | See [§2 Color system](#2-color-system). |
| **Shape / silhouette + material** | Element kind redundantly, plus state | See the kind table below. |

Color alone never carries kind — it is always paired with a silhouette cue and (at sufficient LOD) an
icon or label, so the view is legible to colorblind users and at distance. This is the redundancy rule:
**every semantic distinction is encoded at least twice.**

### 1.1 Kind → shape & material

| Kind | Silhouette | Material | Notes |
|------|-----------|----------|-------|
| **Package / namespace / module** | Smooth sphere, translucent shell | Frosted, see-through (so children read inside) | Container; its volume *is* its contents. |
| **Class** | Smooth sphere, opaque shell | Solid matte | Container for members. |
| **Interface** | Sphere with a dashed/hollow equatorial band | Solid matte, lighter rim | Mirrors UML's «interface» / hollow convention. |
| **Enum** | Faceted sphere (low-poly, gem-like) | Solid matte | Faceting reads as "discrete values." |
| **Struct / record / value type** | Sphere with a flat polar cap | Solid matte | Distinguishes from class without color. |
| **Function / method** | Small sphere | Solid, slightly emissive | Leaf node; lives inside its owner. |
| **Field / property** | Smallest sphere, flattened | Solid, low emission | Leaf node. |
| **Abstract type** | Any of the above, wireframe overlay | Material + wireframe lattice | "Incomplete" reads as wireframe. |

### 1.2 Metrics → surface treatment

Metrics modulate the material **without** stealing the hue channel:

| Metric | Treatment |
|--------|-----------|
| **Cyclomatic complexity** | Surface roughness / displacement — smooth = simple, jagged = complex. |
| **Churn / recency** | Emissive warmth — recently edited bubbles glow faintly warmer; cold code sits matte. |
| **Test coverage** | Rim-light intensity — well-covered bubbles have a clean bright rim; uncovered ones are dull-edged. |
| **Defect / smell density** | Sparse particulate "haze" around the bubble (off by default; toggled overlay). |

Treat these as **overlays** the user toggles, not always-on. Stacking all of them at once is illegible;
the default view shows kind + size only.

### 1.3 Interaction states

| State | Treatment |
|-------|-----------|
| **Default** | Full hue, normal material. |
| **Hover** | Subtle outline glow + tooltip / HUD entry. |
| **Selected** | Bright contrasting outline (white or cyan), held until deselected. |
| **Focused** (the drill target) | Outline + the camera/foveation budget centers here; siblings dim. |
| **Dimmed** (out of focus context) | Desaturated, alpha reduced ~40%, never fully hidden — context must persist. |
| **Traced** (on an active edge path) | Outline tinted to the edge's relationship color; non-path bubbles dim further. |

### 1.4 Collapsed-package HLOD proxy

When a container is too far or too small to draw its children, the renderer substitutes a **HLOD proxy**
(see [`rendering-and-vr.md`](../specs/rendering-and-vr.md)):

- A single sphere at the container's size and **dominant child hue** (area-weighted blend, biased toward the
  package's own layer color if it has one).
- A short stacked label: the container name + child count (`auth/ · 214`), shown only if it wins the
  label budget ([§5](#5-label--text-conventions)).
- Surface carries a faint **packed-texture imposter** — a baked image of the child packing — so the proxy
  still reads as "a full thing," not an empty ball. The imposter is generated once per container and cached.
- A proxy expands into real children when the camera crosses its LOD threshold; the transition cross-fades
  to avoid VR pop.

---

## 2. Color system

Color is keyed first to **element kind**, and overridden by **standard layer color** inside any region
governed by a modeling language that dictates one. Standards win because matching them is what makes a
projected diagram look correct on export.

### 2.1 Base kind palette (3D bubble view, language-neutral code)

Colorblind-safe (Okabe-Ito-derived); each hue is paired with the silhouette from [§1.1](#11-kind--shape--material).

| Kind | Hue | Hex (approx.) |
|------|-----|---------------|
| Package / namespace | Slate / neutral | `#6E7B8B` |
| Class | Blue | `#0072B2` |
| Interface | Sky / cyan | `#56B4E9` |
| Enum | Orange | `#E69F00` |
| Struct / value type | Teal | `#009E73` |
| Function / method | Green | `#2CA02C` |
| Field / property | Yellow-green | `#BCBD22` |
| External / library (read-only) | Desaturated gray | `#999999` |

### 2.2 ArchiMate layer colors (mandatory in ArchiMate regions)

The Open Group's standard layer colors. Use these exactly in ArchiMate projections **and** when the bubble
view is showing an ArchiMate model:

| Layer | Color | Hex |
|-------|-------|-----|
| **Business** | Yellow | `#FFFF99` |
| **Application** | Blue | `#99CCFF` |
| **Technology** | Green | `#99FF99` |
| **Motivation** | Purple | `#CC99FF` |
| **Implementation & Migration** | Pink | `#FFCC99` |
| Strategy | Orange | `#F5DEB3` |
| Physical | Green (Technology variant) | `#AFFFAF` |

### 2.3 UML stereotype coloring

UML has no mandated palette, but profiles routinely color stereotypes (e.g. «entity»/«control»/«boundary»,
or Rational Rose's BCE coloring). When a profile or imported model defines stereotype colors, **honor the
source's colors** on import and preserve them on export. When the engine assigns them, use the base kind
palette and surface the stereotype as a «guillemet» label, never as color alone.

### 2.4 Accessibility rules

1. **Never rely on color alone.** Pair every hue with a silhouette ([§1.1](#11-kind--shape--material)) and,
   at LOD, an icon or text label.
2. Use the **colorblind-safe base palette** above for tool-assigned colors; standard palettes (ArchiMate)
   are used verbatim even where not optimal, because fidelity outranks contrast there.
3. Provide a **high-contrast / monochrome mode** that drops to shape + icon + label only, for low-vision
   users and grayscale export.
4. Maintain a minimum luminance contrast between a bubble and its background and between nested shells.

---

## 3. Edge conventions

Edges are relationships that cross containment: calls, dependencies, generalization, realization,
aggregation, composition, type usage. They are **not all drawn at once** — see [§3.3](#33-on-demand-reveal--bundling).

### 3.1 Line style per relationship (UML, applied in projections and the bubble view)

| Relationship | Line | Arrowhead / decoration |
|--------------|------|------------------------|
| **Association** | Solid | Open arrow (if navigable) or none |
| **Dependency** | Dashed | Open arrow |
| **Generalization** (inheritance) | Solid | Hollow (unfilled) triangle at the supertype |
| **Realization** (implements) | Dashed | Hollow triangle at the interface |
| **Aggregation** | Solid | Hollow (unfilled) diamond at the whole |
| **Composition** | Solid | Filled diamond at the whole |
| **Call / data flow** (tool-specific) | Solid, thin | Small filled arrow, animated flow direction on trace |

In projected UML diagrams these match the OMG UML notation exactly. In the 3D view the same vocabulary
applies, rendered as tubes (see [§3.4](#34-lod-degradation)).

### 3.2 Arrowheads, multiplicity, role labels

- **Multiplicity** (`0..1`, `*`, `1..*`) sits at each association end, near the bubble it qualifies.
- **Role names** label the end they belong to.
- **Navigability** arrows follow UML rules; an undecorated end is "unspecified," not "not navigable."
- These decorations are **LOD-gated** ([§3.4](#34-lod-degradation)): they vanish before the line does.

### 3.3 On-demand reveal & bundling

The default world shows **containment only**. Edges appear when summoned:

- **Selection-scoped:** selecting a bubble reveals its incident edges (in/out, configurable).
- **Hop-limited:** "show calls within N hops" expands a local neighborhood, not the whole graph.
- **Trace mode:** highlights a single path (call chain, inheritance chain) and dims everything else.
- **Edge bundling:** in dense regions, parallel edges between the same clusters are routed together using
  **Hierarchical Edge Bundling** along the containment hierarchy, collapsing a hairball into a few legible
  ribbons. A bundle is selectable and expands to its constituent edges on demand.

### 3.4 LOD degradation

Edges degrade gracefully as detail drops — they never simply blink out at full strength:

```
tube  →  line  →  bundle  →  hidden
```

| LOD | Edge rendering |
|-----|----------------|
| **Near** | 3D **tube** with full decorations (arrowheads, diamonds, multiplicity, role labels). |
| **Mid** | Flat **line**; decorations reduced to arrowheads only. |
| **Far** | Routed into a **bundle**; individual edges merge into a ribbon whose thickness ~ edge count. |
| **Distant** | **Hidden**; the relationship is implied by the HLOD proxies and revealed only on demand. |

---

## 4. Layout conventions

The bubble view's primary layout is sphere packing (see [ADR-003](../adrs/ADR-003-sphere-packing-bubble-layout.md)).
Directed and tabular diagram types use the layout idiom their notation expects, both in 3D drill-downs and in
2D projections.

| Diagram / region | Layout | Rules |
|------------------|--------|-------|
| **Primary bubble view** | Nested sphere packing | Strict containment; one parent per child; bottom-up sizing; sibling stability across edits. |
| **Class / dependency drill-down** | **Sugiyama** (layered) | Ranked flow; generalization points "up" toward supertypes; minimize crossings. |
| **Large dependency cloud** | Force-directed (Barnes-Hut / octree) | For unranked relationship masses; settles, then freezes for stability. |
| **BPMN / Activity** | **Swimlanes & pools** | One lane per participant/role; left-to-right token flow; pools group lanes; message flow crosses pool boundaries dashed. |
| **Sequence** | **Lifeline lanes + time axis** | Vertical lifelines; downward time; activation bars; messages as horizontal arrows ordered by time. |
| **Timing** | Lifeline lanes + **shared horizontal time axis** | State/value on the vertical, time on the horizontal, aligned across lifelines. |
| **State machine** | Ranked / nested | Composite states nest; initial/final pseudostates per UML. |
| **ERD** | Ranked or grid | Entities as tables; relationships with crow's-foot or UML multiplicity per chosen notation. |
| **UAF / Zachman / matrix views** | **Grid** | Fixed rows × columns (aspect × viewpoint); cells hold elements; no force layout. |

For directed flows, default orientation is **left-to-right** (BPMN, Activity) or **top-down** (generalization,
state); follow the governing standard's convention where one exists.

---

## 5. Label & text conventions

Text is expensive in VR and easy to over-draw. Labels are **budgeted**, not free.

- **SDF text.** All in-world labels render from signed-distance-field atlases so they stay crisp at any zoom
  and any angle without per-glyph geometry.
- **LOD-gated.** A bubble shows no label until it is near/large enough; decorations (multiplicity, roles)
  follow the edge LOD ladder in [§3.4](#34-lod-degradation).
- **Budget-capped, top-K.** Each frame a fixed label budget is spent on the **top-K** bubbles ranked by a
  blend of **centrality**, **focus proximity**, and **gaze** (foveation, [§6](#6-interaction-conventions)).
  Bubbles outside the budget show no label even if near. The budget is a frame-time guarantee.
- **Naming display.** In-world labels use the **short name** (`login`); the **qualified name**
  (`auth.Session.login`) appears in the HUD ([below](#52-the-2d-hud)) and on hover. Drilling into a container
  makes its children's short names unambiguous within that context.
- **Anti-collision.** Labels billboard toward the camera and resolve overlaps by the same top-K ranking — the
  lower-ranked label yields.

### 5.2 The 2D HUD

Detail that is hard to read floating in 3D lives in a **screen-space 2D HUD**: full qualified name, signature,
metrics, doc-comment, stereotypes, and the current selection/trace breadcrumb. The HUD is the reliable place
for dense text; the world carries only what survives the budget. In VR the HUD is a comfortable near-field
panel or a wrist/table-top surface (see [§6.3](#63-comfort--locomotion)).

---

## 6. Interaction conventions

### 6.1 Navigation primitives

| Primitive | What it does |
|-----------|--------------|
| **Zoom** | Move the camera in/out; crosses LOD thresholds and expands/collapses HLOD proxies. |
| **Drill** | Enter a container bubble; its children become the working set. |
| **Focus** | Designate a bubble as the center of attention; siblings dim, label/foveation budget centers on it. |
| **Trace** | Follow a relationship path (calls, inheritance) in trace mode ([§3.3](#33-on-demand-reveal--bundling)). |
| **Project** | Send the current region to a standard 2D diagram ([§7](#7-diagram-projection-conventions)). |

### 6.2 Selection & desktop / VR parity

Every action is reachable on both desktop (mouse + keyboard) and VR (controllers), with matched semantics:

| Action | Desktop | VR |
|--------|---------|-----|
| Select | Left-click | Trigger on ray/touch |
| Multi-select | Shift-click | Grip-hold + trigger |
| Focus | Double-click | Double-trigger / point-and-hold |
| Drill in | Scroll-in / Enter | Push in / teleport into |
| Context menu | Right-click | Controller menu button |
| Project to diagram | Toolbar / hotkey | Radial controller menu |

Parity is a requirement: no capability is VR-only or desktop-only.

### 6.3 Comfort & locomotion

- **Teleport locomotion** is the default VR movement (point → teleport), avoiding smooth-motion nausea.
- **Table-top mode** shrinks a region to a miniature on a virtual table the user stands over — the comfortable
  default for browsing; "dive in" scales the user into full-size space for immersion.
- **Gaze-driven foveation** ([`rendering-and-vr.md`](../specs/rendering-and-vr.md)) drives both render detail
  **and** the label budget: what the user looks at gets sharper and gets labels first.

---

## 7. Diagram projection conventions

When a model region is projected to a standard 2D diagram, the projector emits that notation **exactly** as the
governing standard specifies — so the result matches Sparx EA / Rational Rose output and round-trips through the
interchange formats ([`file-formats.md`](file-formats.md)).

| Projection | Standard | Governing body |
|------------|----------|----------------|
| UML (class, sequence, state, activity, component, …) | UML 2.x | OMG |
| SysML (bdd, ibd, req, parametric) | SysML | OMG |
| BPMN | BPMN 2.0 | OMG |
| DMN (decision requirements, decision tables) | DMN | OMG |
| ArchiMate | ArchiMate | The Open Group |
| ERD | IE / crow's-foot or UML | (notation choice) |
| Rational Rose legacy diagrams | Rose notation | Vendor (IBM/Rational) |

What "exactly" means in practice:

- **Line styles, arrowheads, and decorations** from [§3.1](#31-line-style-per-relationship-uml-applied-in-projections-and-the-bubble-view) match the standard's glyphs.
- **Layout idioms** match the standard's expectations ([§4](#4-layout-conventions)) — swimlanes for BPMN,
  lifelines for sequence, layered for generalization.
- **Colors** follow the standard where it mandates them (ArchiMate, [§2.2](#22-archimate-layer-colors-mandatory-in-archimate-regions)) and the source model where it carries them.
- **Layout coordinates** preserve imported Diagram-Interchange positions where the source provided them, and
  synthesize standard-conformant layout where it did not (see [`file-formats.md`](file-formats.md) round-trip strategy).

See [`diagram-catalog.md`](../specs/diagram-catalog.md) for the full list of supported diagram types and their
projection rules.

---

## 8. Convention precedence (summary)

When conventions conflict, resolve in this order:

1. **Governing standard** for a projected/exported diagram (OMG / Open Group / W3C).
2. **Source-model-carried** visual data on import (stereotype colors, DI coordinates).
3. **Accessibility rules** ([§2.4](#24-accessibility-rules)) — redundant encoding, never color alone.
4. **Tool conventions** in this document for the 3D bubble view.

The bubble view is where the tool is free to be itself. Everything that leaves the tool as a standard diagram
must look like the standard.
