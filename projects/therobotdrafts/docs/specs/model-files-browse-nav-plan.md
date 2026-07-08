# Plan: Native `.trd-yaml` model files, browse nav, shared elements, whiteboard shapes

**Status:** Proposed (2026-07-08) — scoping + sub-agent decomposition.
**Session:** `9e7c555d-8a08-4e98-93d5-3e939b89d2e1` (project `therobotdrafts`).

> Scope for the five user requests, grounded in the current code. Each section
> ends with the sub-agent assignment that will implement it. The five tracks are
> **mostly parallel**; the only hard dependency is that **Track A (model core)**
> must land its data-model changes before Tracks C/D consume them.

---

## 0. Current state (from code recon — three Explore agents)

| Concept | Where it lives today | Gap vs. goal |
|---|---|---|
| **Runtime model** | `Assets/Scripts/Authoring/Model/AuthoringModel.cs` — element tree + edges. **No geometry, no diagrams.** | No diagram entity; elements single-parent only |
| **Persistence** | `Assets/Scripts/Uml/UmlCanvas.Persistence.cs` — `DiagramDto` via `JsonUtility` → one flat `persistentDataPath/uml-diagram.json`. Extension forced to `.json`. | Single-diagram, flat, JSON not YAML |
| **Interchange IR** | `Assets/Scripts/Authoring/Interchange/InterchangeModel.cs` — `IxModel{Elements,Edges,Diagrams}`, `IxDiagram{Nodes:IxNodePlacement}`, `IxNodePlacement{ElementId,X,Y,W,H}` | **Already multi-diagram-capable + geometry-per-diagram.** This is the spine to converge on |
| **Identity** | `ElementId` = string from `IIdFactory` (`CountingIdFactory` → `e3:Class`). Stable cross-format id = `DeepLinkUuid` (UUIDv5) on `ModelElement`. Import maps `IxElement.ExternalUuid`→`DeepLinkUuid` | No GUID on runtime id; placement indirection not used at runtime |
| **"Diagram"** | NOT a type. A top-level `ElementKind.Package` (no parent) renders as a tab (`UmlCanvas.cs:4257 BuildTabBar`); nested Packages are "pages". `_activePackage` tracks current | Packages are free-floating; no enforced Diagram parent |
| **Tab bar** | `UmlCanvas.cs:4257 BuildTabBar` — one tab per top-level Package + `+` | This is the "diagrams/packages" strip the user sees on load |
| **Menu bar** | `UmlCanvas.MenuBar.cs:18 BuildMenuBar` (File/Edit/Add/Generate/Layout/Export/Settings) | New/Open/Recent not wired beyond single-file open |
| **File pickers** | `Persistence.cs:173 OpenDiagramFile`, `:163 SaveDiagramAs` (`EditorUtility` panels / `osascript` on macOS player) | **No MRU / recent list anywhere** |
| **Node links** | Only `_packageLink` (`PackageNode id → Package id`, persisted `PackageLinkDto`) — a single special-case link | No general "place a link to a node in another diagram" |
| **Drag-drop** | Palette→canvas only (`UmlCanvas.cs:778`). Node handlers are move/resize | No drag-a-node-link path |
| **Whiteboard** | No `DiagramType` enum; "whiteboard" is a palette group (`UmlCanvas.cs:4892`) of element kinds: Frame/Sticky/Card/Text/Circle/Diamond + Cloud/AsyncSend/AsyncReceive/Note | No triangle/rect/cube/decahedron/sphere/cylinder/blob as kinds |
| **3D meshes** | All procedural, `Assets/Scripts/Uml3D/Shapes/Uml3DMeshBuilder.cs` has `AddBox/AddSphere/AddEllipsoid/AddCylinder/AddTorus/AddConvexPrism/AddPrism`. Dispatch `Uml3DNodeShape.cs:36 Build()` | Sphere/box/cylinder meshes exist; decahedron + blob need new geometry |

---

## 1. The one design decision that gates everything

**How do elements appear in multiple diagrams when `ModelElement.Parent` is single-valued?**

Two viable models. This **must** be settled before Track A starts.

- **(A) Placement indirection (recommended).** Elements live once in a global element pool (containment tree stays single-parent — a Package owns its classes). A **Diagram** is a separate object holding a list of **Placements** (`elementId → x,y,w,h`). The same element id can have a placement in many diagrams. This matches the `IxModel` IR exactly (`IxDiagram.Nodes: IxNodePlacement`) and the EA/Sparx mental model. Packages nest under a Diagram because a Diagram *owns* the placements, and a Package element still has its single containment parent.
- **(B) Shared clones.** Clone the node per diagram, link via a `sharedSourceId`. Rejected: violates "copy not clone," drifts, fights the IR.

**Recommendation: (A).** It reuses `IxNodePlacement` verbatim, keeps containment single-parent (packages always nest under a parent — a Diagram is the root scope for placements, Packages are elements with a parent), and makes drag-drop-a-link trivially "create a new Placement referencing an existing elementId."

> **The user asked us to plan, not implement. I will confirm model (A) vs (B) before dispatching Track A.** Tracks B/E can start regardless.

---

## 2. Track A — Native `.trd-yaml` model core (multi-diagram, nested packages) — **blocks C/D**

**Goal:** a `.trd-yaml` file holds N diagrams; each diagram scopes M packages; packages always nest under a diagram (or another package, ultimately rooted in a diagram).

**Approach:** converge runtime persistence onto the `IxModel` shape rather than `DiagramDto`.

1. **Define the native file as a YAML serialization of `IxModel`.** Add `Assets/Scripts/Authoring/Interchange/TrdYamlReader.cs` + `TrdYamlWriter.cs`. Reuse `YamlLite` patterns (`Assets/Scripts/Styleguide/YamlLite.cs`) or add a small emitter; do **not** pull a heavy YAML dep. Schema:
   ```yaml
   # name.trd-yaml
   name: Payment Service
   elements:       # global pool, single-parent containment via parentId
     - { id: pkg_orders, type: Package, name: Orders }
     - { id: cls_cart,   type: Class,   name: Cart, parentId: pkg_orders }
   edges:
     - { id: e1, from: cls_cart, to: cls_user, type: Association }
   diagrams:       # N diagrams; each scopes placements
     - id: d_orders
       name: Orders Overview
       kind: ClassDiagram
       nodes:                     # placements — elementId can repeat across diagrams
         - { elementId: cls_cart,  x: 120, y: 80,  w: 200, h: 120 }
         - { elementId: pkg_orders,x: 40,  y: 40,  w: 980, h: 620 }
   ```
2. **Enforce "packages nest under a diagram."** Rule: a `Package` element with no `parentId` is invalid in a model file unless it is referenced by ≥1 diagram as a top-level placement; conversely every diagram must name ≥1 top-level Package placement. Validation in a new `TrdModelValidator` + surfaced in `Validity.cs`.
3. **`.trd-yaml` extension registration**: un-force `.json` in `Persistence.cs:168`; add `.trd-yaml` as native, keep `.json` as legacy import.
4. **Round-trip**: `BuildInterchangeModel` (`UmlCanvas.Interchange.cs:641`, currently emits one synthetic diagram `"d1"`) → emit the real diagram set. `MaterializeInterchange` (`:363`) → rebuild placements per diagram.
5. **Migration**: on open, a legacy `uml-diagram.json` / single-`DiagramDto` loads as a one-diagram `.trd-yaml` in memory (no destructive conversion on disk unless user saves).

**Sub-agent:** `npl-tdd-coder`-style implementer (general-purpose). **Files:** `InterchangeModel.cs`, new `TrdYaml{Reader,Writer}.cs`, `UmlCanvas.Persistence.cs`, `UmlCanvas.Interchange.cs`, `Validity.cs`. **Blocked by:** §1 decision.

---

## 3. Track B — Recent files + open/find model on load (UI, parallel)

**Goal:** on load, the top navbar lets you pick a recent model, browse to open any `.trd-yaml`, or start fresh — not just "diagrams/packages."

1. **MRU list**: `PlayerPrefs`-backed (JSON array) recent-files ring (~10). Updated on successful open/save. New `RecentFiles.cs` under `Assets/Scripts/Uml/`.
2. **Menu wiring**: add **File ▸ Open Recent ▸ (list)**, **File ▸ Open…**, **File ▸ New Model** to `UmlCanvas.MenuBar.cs:18 BuildMenuBar`. Reuse `OpenDiagramFile`/`SaveDiagramAs` (`Persistence.cs`), broaden to `.trd-yaml`.
3. **First-run / empty state**: if no recent + no autosave, show an Open/New/Import panel instead of seeding the sample diagram (`UmlCanvas.cs:210` branch).
4. **Tab bar stays** as the per-model diagram switcher (one tab per Diagram now, not per Package — depends on Track A's diagram entity, so this micro-piece soft-depends on A; the MRU/open work does not).

**Sub-agent:** general-purpose. **Files:** new `RecentFiles.cs`, `UmlCanvas.MenuBar.cs`, `UmlCanvas.Persistence.cs` (ext + open path). **Parallel-safe** with all other tracks.

---

## 4. Track C — Browse nav window (tree, right-click edit, drag-drop links) — **depends on Track A**

**Goal:** a navigable tree of diagrams → packages → nodes; right-click to edit properties; drag-drop to insert a **link** (placement, not clone) into the same or another diagram.

1. **New outline panel** `Assets/Scripts/Uml/BrowseNavPanel.cs` (uGUI, matches existing imperative style in `UmlCanvas.cs`). Tree built from: Diagrams → their top-level Package placements → child elements.
2. **Right-click context menu**: Edit Properties (reuse existing property editor path), Rename, Delete, Find in Diagram, Add Placement Here.
3. **Drag-drop a link**: drag a node from the tree → drop on a diagram canvas creates a **new `IxNodePlacement`** referencing that `elementId` (this is the "copy not clone" — element stays single-owner, placement multi-diagram). Requires Track A's placement model.
4. **Cross-diagram/cross-model drop**: dropping onto a different diagram tab creates the placement there. Cross-model (different file) = copy element into target model then place (explicit, since ids don't span files).

**Sub-agent:** general-purpose. **Files:** new `BrowseNavPanel.cs`, `UmlCanvas.cs` (DnD host + panel dock), `AuthoringController.cs:83 EnterAddNode` (add a "link placement" mode). **Blocked by:** Track A placements.

---

## 5. Track D — Shared element scopes (actors, notes in whiteboard) — **depends on Track A**

**Goal:** actors, notes, etc. reusable across diagrams (esp. whiteboard) without cloning.

1. Track A's placement model **already delivers this** — an Actor element gets a placement in any diagram. This track is the **UX/polish** layer:
2. **Palette unification**: add Actor + Note to the whiteboard palette group (`UmlCanvas.cs:4892`) so they're insertable into whiteboards. Their containment already permissive (`Validity.cs:99`).
3. **"Existing element" picker**: when adding to a diagram, option to pick an already-defined Actor/Note (creates placement) vs. create new. Reuses Track C's tree.
4. **Shared-element badge**: visual marker on placements that point at an element used in >1 diagram (hover → "also in: …").

**Sub-agent:** general-purpose. **Files:** `UmlCanvas.cs:4892` palette, `Validity.cs`, new `SharedElementBadge.cs`. **Blocked by:** Track A; pairs with Track C.

---

## 6. Track E — Whiteboard primitive shapes — **fully parallel**

**Goal:** triangle, rectangle, cube, decahedron, sphere, cylinder, blob as whiteboard shapes.

Per the recon, adding a primitive is a **repeatable 14-touchpoint pattern** (see agent findings). Meshes for sphere/box/cylinder/ellipsoid/torus/prism already exist in `Uml3DMeshBuilder`; decahedron + blob need new geometry.

1. **New kinds**: `WhiteboardTriangle, WhiteboardRectangle, WhiteboardCube, WhiteboardSphere, WhiteboardCylinder, WhiteboardDecahedron, WhiteboardBlob` appended to `ElementKind` (`Kinds.cs:8-304`, after L303 to keep ordinals stable). Possibly reuse a single `WhiteboardPrimitive` kind + a `Shape` attribute to avoid enum bloat — **sub-agent to pick and note the tradeoff.**
2. **Registration touches** (from findings): `KindInfo.Hue`, `IsWhiteboardNode` (`:615`), `Uml3DNodeShape.Build` (`:36`) + `Face` (`:117`), `UmlNodeView.ShapeFor` (`:395`) + `UmlShape` enum (`:999`), `WhiteboardDefaultSize` (`UmlCanvas.cs:2539`), palette (`:4892`), 3D + 2D icon PNGs.
3. **New geometry**: `Uml3DMeshBuilder.AddDecahedron` (regular pentagonal, reuse `AddConvexPrism` extrusion or build from vertices) and `AddBlob` (metaball/sphere with noise, or a squashed subdivided sphere — sub-agent judges fidelity vs. cost).
4. **Triangle/rectangle** are 2D-flat in whiteboard; their 3D form = thin prism / extruded plate.

**Sub-agent:** general-purpose (Unity/C#). **Files:** `Kinds.cs`, `Uml3DNodeShape.cs`, `Uml3DMeshBuilder.cs`, `UmlNodeView.cs`, `UmlCanvas.cs`, new icon PNGs (or generated). **Parallel-safe immediately.**

---

## 7. Dispatch plan & parallelism

```
Time ─▶

Track A (model core) ──────────────▶ done
Track B (recent/open UI) ────▶ done                  (parallel with A)
Track E (whiteboard shapes) ─────▶ done              (parallel with A)
Track C (browse nav)              └──▶ starts after A (needs placements)
Track D (shared scopes)           └──▶ starts after A (needs placements)
```

- **Wave 1 (now):** A, B, E in parallel.
- **Wave 2 (after A lands):** C, D in parallel.
- Sequencing enforced by placement model from §1. A's data-model diff is the merge gate.

---

## 8. Risks / open questions

- **§1 model A vs B** — must confirm before A starts. (Recommendation: A.)
- **YAML without a dep** — `YamlLite` is a hand-parser for theme files; a full `IxModel` YAML round-trip may need a slightly richer emitter. Sub-agent to extend `YamlLite` rather than add a package, matching repo convention.
- **Stable ids across save/load** — `CountingIdFactory` ids are positional and can collide across files. The placement model keys on `elementId`; for cross-file drag we copy-and-remint. Within a file, ids are stable across save/load today — verify in Track A.
- **Backwards compat** — keep `.json`/`DiagramDto` readable (one-diagram projection) so existing autosaves survive.
