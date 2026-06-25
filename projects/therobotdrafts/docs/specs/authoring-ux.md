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
   guarantee. This is the single most important invariant for feasibility validation ([§7](#7-open-feasibility-questions--vr-reality-check)).

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

- **Selection mechanic:** thumbstick *direction* highlights a sector + trigger confirms (coarse,
  comfortable), **or** ray-flick at the sector (precise). Center = Select/cancel. Releasing the menu on a
  highlighted sector activates it (radial-pie idiom).
- **Handedness:** Undo/Redo bias to the **non-dominant** hand's radial, so one hand authors while the
  other history-corrects (mirrors Ctrl+Z-while-mousing).
- **Reachability:** ring-1 sectors sit at 8-way thumbstick positions; **never more than 6** in ring 1 so
  each gets a wide, mis-tolerant arc. (Cap-at-4 is a live feasibility question — [F1](#7-open-feasibility-questions--vr-reality-check).)

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
- **VR:** a near-field keyboard panel (§5.2 HUD surface) opens with the label field focused; **voice-to-text**
  is offered as the comfortable VR default. Same commit/skip/Tab rules. (In-world SDF-field editing vs.
  always-panel is a feasibility question — [A2](#7-open-feasibility-questions--vr-reality-check).)

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
  target ≈ **1.0°** at arm's length; min stroke ≈ **3 arc-min** to survive foveation periphery; a 1px dark
  contrast halo so each icon reads against a busy multi-hue bubble field.
- **Desktop:** pictograms on a **24px grid** (@2x 48px), integer **2px** stroke, pixel-snapped; hit target
  **≥ 32px** even when the glyph is 24px.
- **Accessibility:** every command carries icon **+ text label** (toolbar tooltip / radial wedge label) —
  icon-only fails low-vision and learnability. Hotkey hints belong on the desktop tooltip.

(The §5.6 VR angular/stroke minimums are pending hardware validation — [F3](#7-open-feasibility-questions--vr-reality-check).)

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

## 7. Open feasibility questions → VR reality-check

These are the explicit hand-offs to Kenji's Unity/VR feasibility investigation (ticket `31036022`). **This
section is pending Kenji's findings** — the questions below are carried verbatim from the three flows; the
answers, once posted, fold back into the relevant sections. Until then, the VR specifics above are the
*design intent*, not validated-on-hardware commitments.

**Command surface (toolbar/radial — flow `1085589f`):**
- **F1** — Is a 6-sector ring-1 + ray-flick selection reliable on Quest controllers, or should ring-1 cap at
  4 with the rest on the non-dominant hand? ([§2.3](#23-vr-radial-menu))
- **F2** — Wrist-anchored vs. world-anchored radial: which holds steady without smooth-motion discomfort?
- **F3** — Confirm or retune Lena's §5.6 angular minimums (1.0° target, 3-arc-min stroke) for radial glyphs
  against foveated periphery. ([§5.6](#56-dual-target-legibility))

**Add-node (flow `abf97287`):**
- **A1** — Validate the **ray→parent, packer-places** model vs. any expectation of free 6DoF placement: is
  "you don't position, you parent" the right call for Quest, and does the re-pack cross-fade stay comfortable
  when a deep subtree ripples? ([§0](#0-the-authoring-registers-read-first), [§3.3](#33-vr-flow-parity))
- **A2** — Inline in-world label edit vs. forcing the HUD panel: is SDF-field editing legible enough at
  bubble scale, or is the near-field panel always required? ([§3.5](#35-name-on-create))
- **A3** — Voice-to-text availability for naming on target hardware.

**Connect (flow `d6c5a42e`):**
- **C1** *(riskiest VR interaction in the set)* — VR ray-drag precision for picking a *specific small child
  bubble* as an endpoint in a dense packing: is ray + snap accurate enough, or do we need a magnetic "assist"
  radius / dwell-to-confirm? ([§4.3](#43-the-drag-desktop--vr))
- **C2** — Peek-expand-on-ray-rest of a collapsed proxy mid-drag: performance + comfort of the cross-fade
  while an edge is live. ([§4.5](#45-cross-boundary--collapsed-endpoints-the-adr-003-hard-case))
- **C3** — Is "draw-then-type" (release opens a near-field picker) comfortable in VR, or should sticky-type
  be the VR default to avoid a per-edge panel? ([§4.2](#42-edge-typing--choose-after-drawing))

---

## 8. Sources & precedence

### 8.1 Source of record

| Section | Source ticket | Author |
|---|---|---|
| §1–§2 command model, toolbar, radial | `1085589f` | yuki-ux (flow) |
| §3 add-node + creation palette | `abf97287` | yuki-ux (flow) |
| §4 connect-nodes / edge drawing | `d6c5a42e` | yuki-ux (flow) |
| §5 iconography & affordance system | `e94fe1b8` | lena-graphic (visual) |
| §7 feasibility | `31036022` | kenji-gamedev *(pending)* |
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

Anything in §2–§6 describing VR behavior is **subordinate to §7's feasibility findings** once those land.
