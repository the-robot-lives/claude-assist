# Authoring UX Specification

> This document specifies the **authoring layer** of The Robot Draft: the interaction surface for
> *creating and editing* model elements directly in the bubble view — the command surface
> (toolbars / VR radial), the add-node + creation-palette flow, and the connect-nodes / edge-drawing
> flow — at **full desktop ↔ VR parity**. It is the interaction companion to
> [`design-conventions.md`](design-conventions.md): that spec owns the *visual language* (kind hues,
> edge styles, layout, labels) and the *navigation/selection* conventions; this spec owns the
> *authoring verbs* that mutate the model. It is written for Unity and interaction engineers building
> the editing subsystem. Scope for v1 is **UML class/bubble core only** (the element and relationship
> kinds that code→model reverse-engineering produces); the patterns generalize to the other notations
> in a later pass.

Read this alongside [`design-conventions.md`](design-conventions.md) (§2.1 kind palette, §3.1 edge
styles, §6 navigation/selection & parity, §1.3 interaction states, §1.4 HLOD proxies), [`../ARCHITECTURE.md`](../ARCHITECTURE.md)
(the round-trip / edit path — *edit the view, mutate the model, re-derive every view*),
[`../CONCEPTS.md`](../CONCEPTS.md) (what *bubble*, *containment*, *model vs. projection*, *drill*, and
*HLOD proxy* mean), and [`../adrs/ADR-003-sphere-packing-bubble-layout.md`](../adrs/ADR-003-sphere-packing-bubble-layout.md)
(why the packer — not the user — owns element position). This spec **does not redefine** the canvas,
camera, navigation, or selection; it builds on top of them.

This spec consolidates three reconciled interaction flows authored by Yuki (UX) and one visual system
authored by Lena (graphic design); see [§8](#8-sources--precedence) for the source-of-record mapping.

---

## 0. The authoring registers (read first)

Two facts from the existing design constrain everything below. Designing against either fights the
engine and breaks the product's core guarantees.

1. **The packer owns position, not the user** (ADR-003). The bubble view is *not* a 2D canvas where
   you drop a node at an `xyz`. Containment is spatial: a node's place is derived bottom-up from its
   parent's sphere packing. So **placement is not "pick a coordinate" — it is "pick the parent."** The
   user drops an element *into a container*; the packer positions it and gently re-packs the subtree
   (ADR-003: siblings preserved, no pop). Letting users free-position would destroy the stable-spatial-memory
   guarantee. This is the single most important invariant for feasibility validation ([§7](#7-feasibility-findings--vr-reality-check)).

2. **Authoring is the write half of the round-trip** ([`../ARCHITECTURE.md`](../ARCHITECTURE.md)). Every
   authoring verb mutates the **unified model**, and all projections (bubble view + any 2D diagram) are
   re-derived from that model. There is no "draw on the diagram" that isn't first a model edit. Add,
   connect, rename, re-parent, re-type, and delete are model mutations; each is a single undo step.

---

## 1. The command model (shared across both inputs)

There are two classes of command, and the distinction drives the whole surface:

- **Direct-manipulation commands** — select, multi-select, drill, focus, context-menu. These are
  **already specified** in [`design-conventions.md`](design-conventions.md) §6.1–§6.2. The authoring
  surface only exposes them for *discoverability*; it does **not** own them and they are **never** modes.
- **Authoring verbs** — add-node, connect, delete, undo, redo, project. These the surface owns.
  - `add-node` and `connect` are **spring-loaded modes**: **tap = one-shot** (place/draw one, then
    auto-return to Select); **hold / lock = sticky** (place/draw many until cancel). Default to one-shot
    and make sticky explicit — a mode that silently eats your next click is the most common way diagram
    tools confuse people.
  - `delete`, `undo`, `redo`, `project` are **instantaneous** — they act on the current selection or
    history and are never a mode.
- **Never stranded.** `Esc` (desktop) / **B-button** (VR) cancels any in-progress verb and returns to
  **Select**, which is the home state. The user is never trapped in a mode.

---

## 2. Command surface (toolbar + VR radial)

Source: ticket `1085589f`. Builds on [`design-conventions.md`](design-conventions.md) §6.2 (parity
table) and §6.1 (nav primitives); consumes Lena's verb glyph set ([§5.4](#54-command-verb-icons)) and
reserved UI-state channel ([§5.1](#51-reserved-ui-state-channel-the-critical-call)).

### 2.1 Parity matrix — every authoring command × {desktop, VR}

`†` = reuse design-conventions §6.2 verbatim (listed for completeness/discoverability); the rest are
this spec's authoring surface. **Parity is enforced: no row has an empty cell.**

| Command | Desktop | VR | Surfaced where |
|---|---|---|---|
| Select † | Left-click | Trigger on ray/touch | home state; no button |
| Multi-select † | Shift-click / marquee drag | Grip-hold + trigger | — |
| Drill in † | Scroll-in / Enter | Push-in / teleport-in | — |
| Focus † | Double-click | Double-trigger | — |
| Context menu † | Right-click | Controller menu btn | — |
| **Add-node** | `N` or toolbar → kind palette | Radial → Add sector → kind ring | toolbar Create grp / radial |
| **Connect** | `C` or toolbar; drag handle | Radial → Connect; grip+ray drag | toolbar Create grp / radial |
| **Delete** | `Del` / `Backspace` | Radial → Delete (on selection) | toolbar Edit grp / radial |
| **Undo** | `Ctrl/⌘+Z` | Radial → Undo (non-dominant hand) | toolbar Edit grp / radial |
| **Redo** | `Ctrl/⌘+Shift+Z` | Radial → Redo | toolbar Edit grp / radial |
| **Project→2D** | `P` / toolbar | Radial → Project sector | toolbar Output grp / radial |
| **Rename / edit** | `F2` or double-click label | Trigger on label → keyboard panel | inline ([§3.5](#35-name-on-create)) |
| **Cancel verb** | `Esc` | B-button | global |

Every desktop hotkey has a toolbar twin (discoverability); every toolbar/hotkey command has a radial twin.

### 2.2 Desktop toolbar

A slim **vertical left rail** — a top bar crowds the depth axis and fights the 3D canvas, and the top is
reserved for the §5.2 HUD breadcrumb. 32px hit targets, 24px glyphs (Lena, [§5.5](#55-dual-target-legibility)).
Grouped with dividers:

```
┌──┐  canvas (bubble-view) →
│ ▸ │  Select      (home; lit by default)
├──┤
│ ＋ │  Add-node    ┐ Create group
│ ⤴ │  Connect     ┘ (spring-loaded; lit while active, badge if sticky)
├──┤
│ 🗑 │  Delete      ┐ Edit group
│ ↶ │  Undo        │ (Undo/Redo dim when history empty)
│ ↷ │  Redo        ┘
├──┤
│ □ │  Project→2D  ┐ Output group (disabled until a region is selected)
└──┘
```

- **State rendering** uses the reserved UI channel ([§5.1](#51-reserved-ui-state-channel-the-critical-call)):
  active mode = white→cyan selected rim; sticky mode = a small dot badge; disabled = §1.3 dimmed.
  Hover = tooltip with the hotkey (teaches the keyboard path).
- **Add-node / Connect** open their sub-pickers as **flyout panels anchored to the rail button** (kind
  palette → [§3.1](#31-creation-palette-kind-picker); edge-type picker → [§4.2](#42-edge-typing--choose-after-drawing)).
  The toolbar is the *entry*; the picker belongs to that verb's flow.

### 2.3 VR radial menu

Summoned by the **controller menu button** (design-conventions §6.2 context-menu binding) on the
**dominant hand**; appears wrist-anchored facing the user; dismiss on release or B-button. **Max depth 2** —
deeper rings induce nausea and lose the thumb.

```
        Add ＋
   Project       Connect ⤴
  □      ( Select )      ⤴      ← ring 1: ≤6 primary sectors
   Undo ↶       Delete 🗑
        Redo ↷
  ring 2 (context): Add → kind ring (Lena §C) · Connect → edge-type ring (Lena §D) · Project → notation ring
```

- **Selection mechanic:** **ring-1** uses thumbstick *direction* + trigger to confirm (coarse, comfortable),
  **or** ray-flick at the sector (precise). **Ring-2** (kind / edge-type / notation rings, which carry 7–9
  items) uses **ray-pick into the ring**, not thumbstick — its arcs fall below the mis-tolerant floor (F1),
  with a vertical-list fallback past 8 items. Center = Select/cancel. Releasing the menu on a highlighted
  sector activates it (radial-pie idiom).
- **Handedness:** Undo/Redo bias to the **non-dominant** hand's radial, so one hand authors while the
  other history-corrects (mirrors Ctrl+Z-while-mousing).
- **Reachability:** ring-1 sits at **6** thumbstick-aligned sectors (~60° arcs — validated mis-tolerant on
  Quest Touch, [F1](#7-feasibility-findings--vr-reality-check)); depth-2 is the ceiling.

---

## 3. Add-node + creation palette

Source: ticket `abf97287`. Builds on design-conventions §2.1 kind palette + §6 nav, Lena's §C kind
glyphs, and ADR-003 packing. Invoked from the toolbar/radial **Create** group ([§2](#2-command-surface-toolbar--vr-radial)).
**Placement = pick the parent** ([§0](#0-the-authoring-registers-read-first)), never a free coordinate.

### 3.1 Creation palette (kind picker)

A compact palette of the UML-core kinds; each row = Lena §C glyph + §2.1 hue + label, so **the palette
swatch is what the bubble will look like** (no translation):

| Kind | §2.1 hue | Glyph (2D read of the 3D silhouette) |
|---|---|---|
| Package | slate `#6E7B8B` | dashed circle, nested dots |
| Class *(default)* | blue `#0072B2` | solid filled circle |
| Interface | sky `#56B4E9` | circle + open equatorial band |
| Enum | orange `#E69F00` | hexagon |
| Struct / value | teal `#009E73` | circle + flat-top chord |
| Function / method | green `#2CA02C` | small solid dot |
| Field / property | yellow-green `#BCBD22` | flattened ellipse |

- **`abstract` is a modifier, not a kind** — a toggle on the chip that switches the glyph to
  outline-only/wireframe (echoes UML's italic-for-abstract). It does not consume a palette slot.
- **Containment-filtered:** the palette is filtered by the active notation (UML-core here) **and by what
  is legal in the target parent** (containment rules). An illegal kind (e.g. a Field directly under a
  Package) is **§1.3-dimmed in place with a hover reason — not hidden** — so the rule is taught at
  point-of-use rather than surfaced as a failed drop. This is where containment-awareness lives.
- Keyboard roving-focus through kinds; type-ahead (`c` → Class). The most-recent kind floats to default.

### 3.2 Desktop flow

1. **Enter add-node:** `N` or toolbar `＋` (spring-loaded — tap = one-shot, hold = sticky, [§1](#1-the-command-model-shared-across-both-inputs)).
2. **Target the parent:** as the cursor moves over the bubble field, the bubble under it gets the
   **valid-target affordance** (Lena §B: white rim + ✓ ghost + snap-pulse). A kind illegal in that parent
   shows the **invalid affordance** (vermillion `#D55E00` dashed rim + ✕, no snap). Hovering empty space
   targets the *current drill container* (the working set you are inside) as parent.
3. **Pick kind:** the palette is anchored as a flyout at the toolbar button; pick before or after
   targeting. If a kind is pre-selected, click-on-parent places immediately; if not, click-on-parent opens
   the palette at the cursor.
4. **Place:** click confirms → the packer inserts the child and re-packs the parent's subtree (gentle
   ADR-003 ripple, cross-faded so nothing pops); the camera keeps the parent framed.
5. **Name-on-create** ([§3.5](#35-name-on-create)).

### 3.3 VR flow (parity)

1. **Enter add-node:** radial → Add sector → **kind ring** (Lena §C glyphs as ring sectors).
2. **Target the parent:** point the controller ray; the intersected bubble gets the same §B valid/invalid
   affordance. Ray resting on empty space → the current table-top/drill container is parent.
3. **Place:** trigger confirms at the ray-hit parent. The new bubble eases into its packed slot — **no
   free-hand 6DoF positioning**; the ray only chooses the parent, matching desktop semantics exactly.
4. **Name-on-create** ([§3.5](#35-name-on-create)).
5. **Comfort:** requiring no precision placement is deliberate — ray→parent + packer-places is far more
   comfortable in a headset than hand-positioning a sphere in 3D (counts toward design-conventions §6.3).

### 3.4 Empty-diagram bootstrap

The first node has no parent. Add-node on an empty world places a **root container** (Package by default,
or the notation's root kind) at world origin; subsequent nodes target it or drill into it. The empty state
shows a single ghost `＋` prompt center-world — *"Add the first element"* — so a blank canvas tells the user
the one move.

### 3.5 Name-on-create

The new bubble spawns with an **inline label editor focused** (the §5 SDF label becomes an editable field;
the HUD shows the qualified-name preview `parent.NewClass`):

- `Enter` commits. `Esc` commits with a **deduped default** name (`Class1`, `Class2`, …) — **never block
  placement on naming**. `Tab` commits and immediately starts the next node in the same parent (sticky-mode
  rhythm).
- An empty name renders a ghost placeholder `Class…` in the kind's hue, so an unnamed node still reads as
  its kind.
- **VR:** the §5.2 near-field keyboard panel is the **required input surface** (A2) — it opens with the label
  field focused and **live-mirrors** the typed text onto the in-world SDF label so the result reads in place
  (in-world SDF is display-only; no in-world caret editing). **Voice-to-text is a P2 convenience** (poor on
  code identifiers); the keyboard panel + symbol type-ahead is the **P0** path (A3). Same commit/skip/Tab
  rules. See [§7](#7-feasibility-findings--vr-reality-check).

### 3.6 Re-parent (the only "move")

Moving a node to a different container = select + **drag-into-bubble** (desktop) / **grip-drag onto target
bubble** (VR); same §B valid/invalid affordance; the packer re-packs both the old and new parent. **This is
the only move gesture — there is no free-move, because there is no free space** ([§0](#0-the-authoring-registers-read-first)).
A mis-placed node is one **undo** step, not a stranded orphan.

---

## 4. Connect-nodes / edge drawing

Source: ticket `d6c5a42e`. Builds on design-conventions §3.1 line styles + Lena's §D edge glyphs, §B
affordances, and ADR-003 (edges cross containment; the world draws containment by default and edges
on-demand per §3.3). Invoked from the toolbar/radial **Create** group. v1 edge kinds = UML class
relationships only: association, dependency, generalization, realization, aggregation, composition.

### 4.1 Initiation — two paths, same result

- **Connect mode** (deliberate, repeatable): `C` / toolbar `⤴` / radial → Connect. Spring-loaded
  ([§1](#1-the-command-model-shared-across-both-inputs)): tap = draw one then back to Select; hold = sticky
  for many.
- **Quick handle** (discoverable): a selected bubble shows a small **connect handle** on its rim (Lena §E
  connect glyph); dragging *from the handle* starts an edge without entering mode — the affordance lives on
  the object, for the user who didn't know there was a tool.
- **Parity note:** VR has no hover, so the quick handle appears on **select**, not hover.

Both paths produce the same rubber-band drag ([§4.3](#43-the-drag-desktop--vr)).

### 4.2 Edge typing — choose *after* drawing

Default is **draw first, type second.** You almost always know source→target before you've settled the exact
UML relationship, so kind-choice does not gate starting the gesture.

- On release at a valid target, a compact **edge-type picker** appears at the drop point — Lena §D glyphs,
  where **each picker icon *is* the line + head it draws**, so picker and committed edge are identical:

  | Relationship | Line | Head |
  |---|---|---|
  | Association *(default)* | solid | open arrow |
  | Dependency | dashed | open arrow |
  | Generalization | solid | hollow △ at supertype |
  | Realization | dashed | hollow △ at interface |
  | Aggregation | solid | hollow ◇ at whole |
  | Composition | solid | filled ◆ at whole |

- **Sticky type override:** pre-picking a type (or having just drawn one) makes it the pending default, so a
  run of same-type edges needs no per-edge picker — shown as a badge on the Connect tool. The picker is
  always one keystroke away.
- **VR defaults to sticky-type** (C3): a near-field picker on every edge release breaks the drawing rhythm
  and forces a per-edge look-away, so in VR the pending type persists (badge on the controller/HUD, picker
  one button away) while **desktop keeps draw-then-type**. A comfort-first §6 substitution, not a parity
  break — both modalities can do both. See [§7](#7-feasibility-findings--vr-reality-check).
- **Direction & semantics:** drag direction sets from→to. For generalization the arrow points
  **subtype→supertype**, so the natural gesture is *drag from child to parent* ("this is-a that"). A
  **flip-direction** control in the picker handles a backwards draw — cheaper than redrawing.

### 4.3 The drag (desktop ↔ VR)

| Step | Desktop | VR |
|---|---|---|
| Grab | drag from handle / click source in Connect mode | grip + trigger on source via ray |
| Rubber-band | edge follows cursor, **neutral white dashed** (Lena §B in-progress, "until type chosen") | edge follows controller ray, same render |
| Target feedback | bubble under cursor → §B valid (white rim + ✓ + snap) or invalid (`#D55E00` dashed + ✕) | ray-hit bubble → same §B affordance |
| Snap | endpoint snaps to bubble surface/center | ray endpoint snaps to bubble |
| Release | drop → type picker | release trigger → near-field type picker |
| Cancel | `Esc` / release on empty space | B-button / release on empty |

Releasing on empty space cancels cleanly — no orphan edge, no dialog (the "never stranded" rule).

> **VR ray-drag precision (C1) — the riskiest interaction in the set.** Picking a small, deep child bubble in
> a dense packing needs assists, not raw ray + nearest-hit: an **angular magnetic assist** (snap to the
> nearest *valid* endpoint, with §4.4 kind-validity pruning the candidate set), **dwell-to-confirm with a
> candidate highlight** before commit, **ray stabilization** (one-euro/low-pass to kill tremor), and
> **mandatory peek-expand** for dense/collapsed clusters. These are requirements, not polish, and warrant a
> gated tuning spike before the connect gesture locks. See [§7](#7-feasibility-findings--vr-reality-check).

### 4.4 Validity — kind-aware, felt during the drag

Legality fires the §B **invalid** affordance *during* the drag, before release — you feel the rule instead
of getting an error dialog after:

- generalization: class→class or interface→interface only; realization: class→interface; a Field/Function
  as a generalization endpoint → invalid (✕).
- self-edge: allowed only where the notation permits (reflexive association ✓; self-generalization ✕).
- would-create-cycle in generalization → invalid with a hover reason.

Invalid never blocks the *gesture* — only the *drop*. You keep dragging to a legal target.

### 4.5 Cross-boundary & collapsed endpoints (the ADR-003 hard case)

Edges cross containment freely, so endpoints can sit at **different depths**. The hard case is an endpoint
**inside a collapsed parent** (HLOD proxy, design-conventions §1.4):

- **Hover-hold / ray-rest on a collapsed proxy → it peek-expands** (temporary drill, §6.1) so you can target
  the real child inside; moving away re-collapses it. Deep targets stay reachable without permanently
  exploding the view.
- **Quick release directly on the proxy → attaches to the container itself** (a package-level dependency is
  legal UML), rendered as a container-level edge; on later expand it stays homed to the container, distinct
  from child edges.
- Edges whose endpoints are hidden/bundled obey §3.3–§3.4: when both ends aren't drawn, the relationship
  rides the **bundle** and is revealed on selection/trace. The connect flow hands the edge to that existing
  system; it does not draw a permanent hairline across the world.

### 4.6 Re-target, re-type, delete

- **Select an edge** (§3.3 selection-scoped reveal makes it visible; click/trigger the tube): endpoint
  **handles** appear at both ends.
- **Re-target:** grab an endpoint handle → drag to a new bubble → same §B valid/invalid affordance →
  release re-homes that end. The edge keeps its type.
- **Re-type:** select edge → the §D picker on its context menu changes the relationship in place.
- **Delete:** select + `Del` / radial-Delete; one undo step.

---

## 5. Iconography & affordance system

Source of record: ticket `e94fe1b8` (Lena). **Not a parallel visual system** — every glyph here is the 2D
read of an existing design-conventions §1.1 silhouette + §2.1 Okabe-Ito hue, so the 3D bubble and the 2D
palette/toolbar show the same kind the same way. The flows above *place* these marks; this section is what
each mark looks like and its states.

### 5.1 Reserved UI-state channel (the critical call)

Authoring feedback must **not** reuse kind hues — blue/cyan/green/orange/teal/yellow-green are all
spoken-for, so a green "valid" glow would read as *function*. Reserve an achromatic + single-signal channel
for UI state only:

| State | Reserved color | Shape cue (carries it without color) |
|---|---|---|
| selected / active | white → cyan rim (§1.3) | bright solid outline |
| valid target | white rim + thicken | snap-pulse + ✓ ghost |
| invalid target | **`#D55E00`** (Okabe-Ito vermillion — not a kind hue) | dashed rim + ✕, no snap |
| in-progress | neutral white | dashed "rubber-band" until type chosen |

Okabe-Ito vermillion keeps even the failure state colorblind-safe and palette-consistent while colliding
with zero kinds.

### 5.2 Redundancy contract (design-conventions §2.4: every distinction encoded ≥2×)

- **kind** = hue (§2.1) + silhouette glyph + text label (3×)
- **edge type** = line style (§3.1) + arrowhead/decoration + LOD-gated label
- **affordance state** = icon/shape + the reserved non-kind color channel ([§5.1](#51-reserved-ui-state-channel-the-critical-call)) — never color alone.

### 5.3 Kind glyph set (creation palette + HUD)

See the table in [§3.1](#31-creation-palette-kind-picker). Two additions beyond the seven palette kinds:

- **External / library** — gray `#999999`, host glyph with a dashed outline + lock corner (read-only).
- **abstract (modifier)** — host hue, host glyph rendered outline-only / wireframe ("incomplete").

**Monochrome mode (§2.4.3):** the *shape* column alone separates all nine kinds — meaning survives hue
removal.

### 5.4 Edge glyph set (connect tool + type picker)

`= design-conventions §3.1 verbatim.` See the table in [§4.2](#42-edge-typing--choose-after-drawing). The
picker icon *is* the line + head, so the picker and the drawn edge are identical.

### 5.5 Command (verb) icon set

One mark each, used in **both** the desktop toolbar and the VR radial wedge (parity §6.2):

`add-node` (＋ on bubble) · `connect` (two dots + line) · `select` (arrow) · `multi-select` (marquee) ·
`drill` (⤓ into circle) · `focus` (◎) · `delete` (trash) · `undo`/`redo` (↶/↷) · `project→2D` (bubble→rectangle).

**Mode vs. action:** sticky modes (`connect`, `add-node`) show a **persistent active pill** (reserved
white→cyan rim) while engaged; one-shot actions (`delete`, `undo`) just flash on click. This keeps "am I
still in connect mode?" legible — critical in VR where there is no cursor to remind you.

### 5.6 Dual-target legibility

One SVG per icon → **SDF for VR, raster for desktop** (one file, two outputs — guarantees the toolbar mark
and the radial mark are literally the same source):

- **VR:** render from the same SDF atlas as §5 labels (crisp at any depth/angle, billboarded). Ray/touch
  target ≈ **1.0°** at arm's length (≈20–25 px at Quest-3 ~25 ppd); min stroke ≈ **6–8 arc-min (0.10–0.13°)**
  — the original 3 arc-min (~1 px) aliases and is the first thing Fixed Foveated Rendering eats (F3); bump
  primary actionable wedges to **~1.2–1.5°**. Keep the 1px dark contrast halo so each icon reads against a
  busy multi-hue bubble field.
- **Desktop:** pictograms on a **24px grid** (@2x 48px), integer **2px** stroke, pixel-snapped; hit target
  **≥ 32px** even when the glyph is 24px.
- **Accessibility:** every command carries icon **+ text label** (toolbar tooltip / radial wedge label) —
  icon-only fails low-vision and learnability. Hotkey hints belong on the desktop tooltip.

(The VR angular/stroke minimums above reflect Kenji's F3 finding — [§7](#7-feasibility-findings--vr-reality-check); validate on Quest 3 with Fixed Foveated Rendering on.)

---

## 6. Desktop ↔ VR parity summary

Parity is a hard requirement, not an aspiration. Consolidated invariants:

- Every authoring command exists in both modalities ([§2.1 matrix](#21-parity-matrix--every-authoring-command--desktop-vr)) — no empty cells.
- **Placement semantics are identical:** desktop click-on-parent and VR ray-on-parent both choose a *parent*,
  never a coordinate; the packer positions in both ([§0](#0-the-authoring-registers-read-first)).
- **One icon source** drives both surfaces ([§5.6](#56-dual-target-legibility)).
- **Affordance states are identical** ([§5.1](#51-reserved-ui-state-channel-the-critical-call)) — valid/invalid/in-progress look the same in both.
- **Comfort-first VR substitutions** (radial for hotkeys, near-field keyboard + voice for typing,
  ray→parent for placement) preserve the *command set* while respecting design-conventions §6.3 comfort.
- The only structural VR-vs-desktop difference is **discoverability timing**: hover-triggered affordances
  (quick connect handle, target highlight) move to **select**-triggered in VR, which has no hover.

---

## 7. Feasibility findings → VR reality-check

These are Kenji's Unity/VR feasibility findings for ticket `31036022`, validated against the three concrete
flows and the engine baseline in [`rendering-and-vr.md`](rendering-and-vr.md) (Unity 6.3 LTS, URP + Render
Graph, Entities 1.4.x, OpenXR/XRI, BVH picking, octree HLOD) and [`unity-6.3-baseline.md`](unity-6.3-baseline.md).
Budgets referenced below: **11.1 ms** at 90 Hz, **13.9 ms** at 72 Hz (Quest), fill computed at ~2× display
resolution. Each finding carries a **🟢 green / 🟡 caution / 🔴 red** verdict; where a finding changes design
intent, the implied spec delta is called out and folds back into the cited section.

> **Headline:** nothing in the authoring design fundamentally fights Unity 6.3 / DOTS / OpenXR-XRI. Eight of
> nine are green or caution-with-known-mitigation; the one real risk is **C1** (VR ray-drag endpoint
> precision in a dense packing), which is feasible only with an assist-radius + dwell-confirm + ray
> smoothing and should get a dedicated spike before the connect gesture locks.

**Command surface (toolbar/radial — flow `1085589f`):**

- **F1 — 🟡 caution (keep 6, split the mechanic by ring).** Ring-1 at six thumbstick-aligned sectors gives
  ~60° arcs — comfortably above the ~30–40° floor where stick-direction selection stays mis-tolerant on
  Quest Touch — so **do not cap ring-1 at 4**; six is fine and depth-2 is already the right ceiling. The real
  precision cliff is **ring-2**: the Add → kind ring carries 7–9 kinds, whose arcs fall below ~40° and make
  thumbstick-direction unreliable. **Delta ([§2.3](#23-vr-radial-menu)):** ring-1 = thumbstick-direction
  primary + ray-flick precise alternate (as specced); ring-2 (kind/edge/notation rings) = **ray-pick into the
  ring**, not thumbstick, with a vertical list fallback when a ring exceeds 8 items. Undo/Redo stay on the
  non-dominant hand.
- **F2 — 🟢 green (hand-anchored, not world-anchored).** Anchor the radial to the **non-pointing controller**,
  billboarded to face the user, at a fixed ~0.3–0.4 m focal distance; summon on the menu button, drive with
  the dominant hand. A hand/head-relative panel does **not** induce vection — cybersickness comes from
  *world-relative* optic flow, not from HUD-locked elements that travel with the user — whereas a
  world-anchored menu forces physical reaching/turning and can clip behind geometry. This is the established
  idiom (Tilt Brush / shell). Hold the ~0.35 m focal distance to avoid vergence-accommodation fatigue.
- **F3 — 🟡 caution (targets OK, ~2× the stroke).** At Quest-3 ~25 ppd (use it as the floor; Quest-2 ~20 ppd
  is EOL-ing), Lena's **1.0° ray/touch target ≈ 20–25 px is fine**. The **3-arc-min stroke (0.05°) ≈ 1 px is
  too thin** — it aliases/shimmers and is the first thing Fixed Foveated Rendering eats if the radial sits in
  the periphery. **Delta ([§5.6](#56-dual-target-legibility)):** raise min stroke to **~6–8 arc-min
  (0.10–0.13°)**, keep the 1 px dark contrast halo, render glyphs from the SDF atlas (already specced), and
  bump primary actionable wedges to **~1.2–1.5°**. Mitigating factor: the hand-anchored radial (F2) is where
  the user *looks*, so it lands foveal/para-foveal, not in the FFR-degraded periphery — but validate on Quest
  3 with FFR on.

**Add-node (flow `abf97287`):**

- **A1 — 🟢 green (strongly endorse ray→parent, packer-places).** This is both the correct call for ADR-003's
  stable-address guarantee *and* the more comfortable one: free 6DoF placement in a headset is imprecise (no
  haptic surface, arm fatigue, depth misjudgment). Reducing placement to a single BVH ray-pick (O(log n)) is
  accurate and cheap. Re-pack cost is **off the frame loop** ([`rendering-and-vr.md`](rendering-and-vr.md) §1)
  — only the *animation* of interpolating positions touches the frame, and that is an instance-buffer update,
  trivial. **Comfort caveat → mitigations (fold into [§3.3](#33-vr-flow-parity)):** a large ripple = many
  bubbles moving = peripheral optic flow = mild vection. ADR-003 already localizes the re-pack (stable
  addresses → siblings barely move); additionally (1) animate only the affected subtree, (2) ease-out ≤300 ms,
  (3) keep the parent framed so motion stays parafoveal, (4) for nodes displacing >~10° use alpha
  fade-through instead of slide. One thing to instrument: worst-case displacement when an insert grows a
  parent radius significantly — clamp animation distance there.
- **A2 — 🟡 caution (near-field panel is required for *entry*; in-world SDF for *display*).** SDF labels are
  resolution-independent, so a name reads fine **in place**; but **editing** in-world is the problem — no
  caret precision, the field may be small/angled/self-occluded in a dense packing. **Delta
  ([§3.5](#35-name-on-create)):** commit to the §5.2 near-field keyboard panel as the **input** surface
  (not optional), with a **live mirror** of the typed text onto the in-world SDF label so the user sees the
  result land in place. Voice (A3) is the fast path on top.
- **A3 — 🟡 caution (offer voice, never depend on it).** Quest voice (Meta Voice SDK / Wit.ai dictation) and
  Android XR on-device speech exist, but (1) dictation historically needs connectivity and (2) accuracy on
  **code identifiers** (CamelCase, acronyms, `_`) is poor — "getUserById" dictates badly. **Delta:** voice =
  **P2 convenience** for prose-y names; the keyboard panel + type-ahead from existing symbols is **P0** and
  the reliable path for identifiers. Do not make voice load-bearing.

**Connect (flow `d6c5a42e`):**

- **C1 — 🔴→🟡 the real risk; feasible only with assists.** Raw ray-pick of a *small, deep* child bubble in a
  dense packing is the hardest interaction in the set: ~0.5–1° hand tremor maps to large lateral error at
  distance, small children subtend a tiny solid angle, and spheres self-occlude (ADR-003 known limit). Naive
  ray + nearest-hit will mis-target constantly. BVH cost is not the issue (O(log n)); **accuracy** is.
  **Required (not optional) — fold into [§4.3](#43-the-drag-desktop--vr):** (1) **angular** magnetic assist —
  snap to the nearest *valid* endpoint within an angular radius (scales with distance), with §4.4 kind-validity
  pruning the candidate set so assist only competes among legal targets; (2) **dwell-to-confirm + candidate
  highlight** — show the resolved target on ray-rest before commit; (3) **ray stabilization** — one-euro /
  low-pass filter to kill tremor; (4) **peek-expand/drill mandatory** for dense or collapsed clusters (see C2)
  plus a "get closer / table-top" nudge so the target subtends a larger angle. **Recommend a focused spike to
  tune assist-radius + dwell time on Quest 3 before the connect gesture is locked.**
- **C2 — 🟡 caution (feasible with hysteresis + one-at-a-time).** Peek-expand promotes one HLOD proxy to its
  children — a localized residency/draw change routed through the existing HLOD swap ([rendering §3.2](rendering-and-vr.md))
  and streaming amortization (§3.7): a handful of extra instances, trivial against budget **provided** (a) only
  one proxy peeks at a time, (b) child upload is amortized over a few frames, (c) buffers are pooled (zero
  per-frame alloc). The live edge is just a rubber-band quad — no added cost. **Comfort:** ease the cross-fade
  ≤200 ms, fade-in alpha (no scale-pop), and **re-collapse on ray-leave with hysteresis** so a wobbling ray at
  the boundary doesn't strobe expand/collapse. Hysteresis + one-at-a-time are hard requirements, not polish.
- **C3 — 🟡 caution (make sticky-type the VR default).** A near-field picker on *every* edge release breaks
  the drawing rhythm and forces a look-away-from-canvas context switch per edge — fatiguing across a run.
  **Delta ([§4.2](#42-edge-typing--choose-after-drawing)):** in **VR default to sticky-type** (pending type
  persists; draw a run with no panel), surface the current type as a controller/HUD badge, picker one button
  away. **Desktop keeps draw-then-type** (mouse + nearby picker is cheap). Both modalities can do both — this
  is a comfort-first §6 substitution, not a parity break.

**Cross-cutting parity flags (the dispatch's "desktop-cheap / VR-awkward" ask):**

- **Hover affordances** (valid-target highlight, quick-connect handle) are free on desktop, impossible in VR
  (no hover). The spec already moves them to **select**-triggered in VR ([§4.1](#41-initiation--two-paths-same-result),
  [§6](#6-desktop--vr-parity-summary)) ✅. Implementation note: VR "valid-target highlight" during add/connect
  must come from **ray-rest (dwell pseudo-hover)**, which is the *same* ray-stability machinery as C1 — build
  ray-rest highlighting **once** and reuse it for add-target, connect-target, and peek-expand.
- **Multi-select marquee** (desktop drag) → VR grip+trigger: a 3D volume/lasso select is genuinely awkward and
  is **flagged for its own design pass** (out of v1 authoring scope; the parity matrix row holds, but the VR
  mechanic needs work beyond "grip-hold + trigger").
- Right-click context menu (desktop) ↔ controller menu button (VR): parity holds, no concern.

**Net for the build:** proceed. Implement F2/A1 as specced; apply the F1/F3/A2/A3/C3 deltas above; treat C1
as the gated spike. Section §2–§6 VR behavior stands as written except where a delta above amends it.

---

## 8. Sources & precedence

### 8.1 Source of record

| Section | Source ticket | Author |
|---|---|---|
| §1–§2 command model, toolbar, radial | `1085589f` | yuki-ux (flow) |
| §3 add-node + creation palette | `abf97287` | yuki-ux (flow) |
| §4 connect-nodes / edge drawing | `d6c5a42e` | yuki-ux (flow) |
| §5 iconography & affordance system | `e94fe1b8` | lena-graphic (visual) |
| §7 feasibility | `31036022` | kenji-gamedev |
| Epic | `6b6a5365` | — |

Visual marks and states are **Lena's** (`e94fe1b8`); placement, choreography, and command structure are
**Yuki's** (the three flows); the two are reconciled 1:1 with no parallel system and no structural conflict.

### 8.2 Convention precedence

When this spec and another conflict, resolve in this order (mirrors design-conventions §8):

1. **design-conventions.md** for any *visual* treatment (hue, glyph silhouette, edge style, label, layout)
   and for *navigation/selection* — this spec never overrides them.
2. **ADR-003** for position and packing — the packer owns placement; no authoring gesture may free-position.
3. **This spec** for *authoring verbs and their interaction surface*.
4. **Accessibility rules** (redundancy contract §5.2, reserved UI channel §5.1) are not negotiable down —
   they may only be strengthened.

Anything in §2–§6 describing VR behavior is **subordinate to §7's feasibility findings**, which have landed
(ticket `31036022`) and are folded into the relevant sections above.
