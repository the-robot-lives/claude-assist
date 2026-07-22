# TRD — Information Architecture v2 (clean-room)

Direction: **Concept D synthesis** — Cockpit shell + Model Browser rail + palette/contextual
overlays. Nocturne 80 / Minimal-Tech 20. Cyan-teal accent `#37c8c3`; warm glow reserved for
selection; **vermillion reserved exclusively for state/danger** (a11y channel — never
decorative). Every command keyboard-reachable and palette-reachable (VR/automation parity).

## 1. macOS menu bar
Eight menus. Two non-standard menus earn their place: **Code** (round-trip is a first-class
product pillar) and **Go** (navigation/trace in the macOS "Go" convention).

**TheRobotDrafts** — About · Settings… `⌘,` (incl. LLM presets/API key/test-connection,
themes) · Services · Hide · Quit

**File**
- New Model `⌘N` · New Diagram… `⇧⌘N` · New Page
- Open… `⌘O` (`.trd-yaml`, legacy `.json`) · Open Recent ▸
- Save `⌘S` · Save As… `⇧⌘S` · autosave indicator lives in status strip
- Import ▸ — PlantUML… · XMI… · Mermaid… · EA Project (.qea)… · Source Code (paste)… ·
  Source Folder… · Database (Postgres/MySQL)… · **From Image…** (vision transcribe)
- Export ▸ — TRD YAML · PlantUML · Mermaid · XMI · EA Project (.qea) · Snapshot as PNG… ·
  Copy Snapshot `⌃⌘C` · 3D Scene (OBJ + MTL)… · (selection-only toggle inside each dialog)
- Close Diagram `⌘W` · Delete Diagram…

**Edit**
- Undo `⌘Z` · Redo `⇧⌘Z`
- Cut/Copy/Paste/Duplicate `⌘D` · Paste Image as Node
- Delete ▸ — **Unlink from This Diagram `⌫`** · **Remove from Model Everywhere `⌥⌫`**
  (the link-not-clone law made visible)
- Select All `⌘A` · Select Volume (depth marquee) `⇧⌘A` · Deselect `Esc`
- Find Element… `⌘F` · Rename `⏎`

**Model**
- Add Element ▸ — Class · Interface · Enum · Package · Component · Actor · Datastore ·
  Note · Region · More… `⇧⌘K` (full 185-kind browser w/ families)
- Members ▸ — Add Attribute `⌥A` · Add Operation `⌥O` · Edit Members…
- Connect `C` · Relationship Type ▸ (8 core + family-specific, valid-kind filtered)
- Aspects ▸ — Attach… · Edit Aspects… · Registry… · Revision History…
- Style ▸ — Color Swatches… · Attach Image to Face… · Avatar Editor…
- Validate Model `⇧⌘V` · Model Properties…

**Diagram**
- New From Model ▸ — (families: UML ▸ 14 kinds · Data ▸ ERD/C4 · Process ▸ BPMN/DMN/
  Flowchart · Systems ▸ SysML/ArchiMate/Deployment · Sketch ▸ Mind Map/Whiteboard/Wireframe)
- Duplicate Diagram · Diagram Properties… · Pages ▸
- **Link Element Here** (from browser drag or picker — placement without cloning)
- Layout ▸ — Cluster (recommended post-import) · Layered Hierarchy · Force-Directed ·
  Grid · AI Layout… · ✓ Keep Hand Placements
- Previous / Next Diagram `⌘{` `⌘}`

**Code**
- Generate for Selection `⌘G` · Code Export Wizard… `⇧⌘G` (language C#/TS/Python/Java/Go)
- Refactor ▸ — Rename Symbol… · Move to File… · AI Refactor…
- Shadow Files ▸ — Open in Editor `⇧⌘O` · Re-ingest Edits · ✓ Watch for Changes
- Database ▸ — Connect… · Diff vs Baseline · Emit Liquibase Changelog…

**Go**
- Command Palette `⌘K` (also full command search)
- Jump to Element… `⌘J` · Back `⌃[` · Forward `⌃]`
- Frame Selected `F` · Frame All `Home`
- Z-Layer ▸ — Up `⌥↑` · Down `⌥↓` · Jump… · Follow Edge Across Layers `⌥⏎`
- Trace ▸ — **Start Trace Here `⌘T`** · Open Call Site as Bubble · Close Trace ·
  Debug ▸ (Launch `⌘R` · Continue `⌃⌘Y` · Step `F7` · Toggle Breakpoint `⌘\`)

**View**
- Model Browser `⌥⌘1` · Inspector `⌥⌘2` · Outline `⌥⌘3` · Status Bar
- Camera ▸ — Controls… `⇧⌘C` · Presets (Overview/Focus/Top/Face) · Drag Mode cycle `⌥M`
  (orbit/pan/axis) · Reset
- Appearance ▸ — Grid ✓ · Depth Cues ✓ · Labels ✓ · Trace Neighbors ✓ · Regions ✓ ·
  Theme ▸ (Dark ✓ / Light / tokens…)
- Overlays ▸ — (reserved: Color by Metric · Dependency Cycles · Version Compare)
- Focus Mode `⌃⌘F` · Enter Full Screen

**Window** — Minimize · Zoom · window list  ·  **Help** — Search · Docs · Shortcuts `⌘/` ·
Sample Models ▸ · Guided Tour (reserved: classroom mode)

## 2. Toolbars

**Context toolbar** (single slim row)
- Left: browser toggle ‹ · drill breadcrumb `model ▸ package ▸ diagram` (each segment
  clickable = Go)
- Center: mode segmented **Select | Connect | Place** (`V C P`) — Connect reveals
  relationship dropdown; Place reveals element-kind chip (last used + More…). *Place =
  pick-the-parent when the packer lands; free-drop on the layer plane until then.*
- Right: Layout dropdown (5 algorithms) · Camera · Snapshot · Trace `⌘T` · ⌘K

**Left rail → Model Browser** (collapsed 44 px rail / expanded 264 px)
- Rail icons: Browser · Outline · Search · Palette · Aspects · Code · Import/Export
- Panel tabs: **Files** (models) · **Outline** (Diagrams→Pages→Nodes, click-to-frame,
  drag-to-LINK into viewport, placement-count badges) · **Recents**

**Element Palette** (operator-requested; always available while authoring)
- Slim vertical dock on the viewport's left edge (right of the browser), ~64 px: element
  chips (icon + label) for the active diagram family — Class · Interface · Enum · Package ·
  Component · Actor · Datastore · Note · Region · **More… `⇧⌘K`** (full kind browser)
- **Click** a chip = arm Place mode with that kind (next viewport click places);
  **drag** a chip into the 3D scene = place at drop point (projected onto layer plane;
  becomes pick-the-parent when the packer lands)
- Chips reorder by recency of use; family switches with active diagram kind; collapsible
  via View ▸ Element Palette `⌥⌘4`

**Inspector** (right 272 px, sections)
Element · Members (structured editor) · Relationship (typed, multiplicities, flip) ·
Aspects (+ emit flags) · Style (swatches, image, avatar) · Metrics · Notes
— Edge-selected and Region-selected variants swap the section set.

**Contextual selection toolbar** (floats at selection; summon `⌘.`; VR: wrist-anchored)
Connect-from-here · Edit · Frame · Trace · Unlink/Delete (long-press or ⌥ for
remove-everywhere)

**Status strip**
Mode chip (cyan; **Connect = warm; Debug = vermillion**) · breadcrumb · selection summary ·
Z-layer indicator · camera pose · autosave/version · background-task spinner (imports,
LLM ops — click opens progress modal with pause/resume/cancel)

## 3. Overlays
- **⌘K palette**: every command, fuzzy, recents first, shows shortcut + menu path
- **Kind browser `⇧⌘K`**: searchable 185-kind picker grouped by family
- **Trace bubbles**: linked code bubbles float in-scene; debug controls dock into the
  context toolbar while active (vermillion accent)
- **Focus mode**: panels collapse; palette + contextual toolbar remain

## 4. Interaction laws
1. Every verb: menu + shortcut + palette (+ VR affordance later). No hover-only.
2. Distinctions ≥2 encodings (color + icon/text); vermillion = state/danger only.
3. Destructive = undoable; unlink vs remove always explicit.
4. Mode changes echo: segmented control + status chip + hint line.
5. Long ops: progress modal w/ pause/resume/cancel; never a frozen viewport.
6. Panels remember state per model; Focus mode is a view state.
