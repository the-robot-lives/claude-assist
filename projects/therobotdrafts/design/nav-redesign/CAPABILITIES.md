# TRD Capability Catalog (clean-room input — scout report, verified against source/specs)

*Delivered by trd-feature-scout under the clean-room guard (capabilities only; current UI
arrangement never consulted). Supersedes the earlier memory-derived draft.*

Unity 6 (macOS) UML/diagram authoring app. Treats a software system as a navigable 3D
space; reverse-engineers code + DBs into ONE semantic model, edits it in a real 3D scene
(2D is export-only), round-trips model↔code and model↔interchange. Core principle: one
model = source of truth; every diagram/view/export is a re-derivable projection.

## 1. Domain nouns
Model/workspace · Diagram + Page (multi-diagram docs) · Element (~185 built kinds) ·
Member (attrs/ops, columns, widget children) · Edge · Region (boundary cube grouping) ·
Package/namespace · **Placement** (per-(diagram,element) — one element in many diagrams
WITHOUT cloning; unlink-from-one vs remove-everywhere) · **Aspect** (typed/versioned/
sparse) · Source/shadow file · DB schema objects + Liquibase changelogs · Aspect registry ·
breakpoints · trace bubbles · theme tokens · camera state · recents.

## 2. Verbs (all [built] unless noted)
- **Author**: create (kind picker, drag-from-palette, paste element, paste-image-as-node,
  packages/pages, members); edit (rename, stereotype, structured member editor, notes,
  per-element style/color, region color); delete (element/edge/member/diagram/waypoint;
  unlink-vs-remove); connect (drag handle, valid-kind picker, re-type, flip, bends,
  re-pin); move/resize (carries children, per-axis handles, multi-select); undo/redo.
- **Navigate**: Diagrams→Pages→Nodes outline (click-to-frame, drag-to-LINK, search,
  placement badges); recents MRU; zoom/center/Frame-All; Z-layer step/jump; follow
  cross-layer edge; **Trace bubble-IDE**: root trace at element, open call-sites as linked
  code bubbles, Edit + **Debug** (launch/continue/step, breakpoints, line highlight).
- **3D**: 6-DOF camera (orbit/dolly/pan/roll/free-fly/frame/jump-to-face/numeric form);
  selection (click/shift/marquee/**volumetric depth-reach marquee**); manipulation (move,
  grab-spin, slide-Z, resize, constrained handles, edge waypoint handles, region cubes);
  notation-aware silhouette meshes per kind; images/avatars on faces.
- **Import**: PlantUML, XMI, Mermaid (opt LLM color recovery), EA `.qea` (SQLite rw);
  paste source (LLM parse) or recursive folder import (plan/progress modal, pause/resume);
  live Postgres/MySQL → tables/FK edges + baseline; **image → diagram** (vision-LLM →
  PlantUML → review table); legacy `.json` read.
- **Export**: PlantUML, XMI, Mermaid, `.qea`; PNG + OS clipboard snapshot; **3D OBJ+MTL**
  (Blender) + JSON vertices; Liquibase YAML changelog (ERD diff vs baseline, opt LLM
  refine); native `.trd-yaml` save/autosave; selection-only variants.
- **Code round-trip**: generate per-element/selection (deterministic skeleton + opt LLM,
  surgical overlay on original source); **code-export wizard** (elements, language
  C#/TS/Python/Java/Go w/ conversion, output root, audit pass); refactor (rename,
  move-to-file, free-form NL LLM refactor); shadow files (write → edit in VS Code →
  re-ingest edits).
- **Aspects**: per-element editor (fields, emit flags, freeform kv); def registry
  (scope/version/system-owned); revision history + diff.
- **Layout (5)**: grid · force-directed · layered hierarchy · source/package cluster ·
  LLM-assisted.
- **Theming**: styleguide token pipeline (~15 seeds → ~300 tokens) themes HTML wireframe
  export.
- **Standalone**: headless `.puml`→`.trd-yaml` converter (`--check` round-trip, `--stats`,
  `--diff`).

## 3. Diagram families
Built palette/rendering: UML ×14, ERD, C4, flowchart, network, mind-map, wireframe,
whiteboard, SysML, BPMN, DMN, ArchiMate, strategy/EA, UAF/TOGAF/Zachman. [planned] full
projection engine across 47 families (today: UML-class projection + wireframe→HTML only).

## 4. Workflows
1. Codebase→model→3D edit→regen (shadow edits flow back) 2. DB→ERD→Liquibase
3. Image/sketch→model 4. Interchange round-trip 5. Trace & debug bubbles
6. [planned] binary reverse-compile 7. [partly planned] onboarding tours/named views.

## 5. Roadmap to reserve space for
Sphere-packing layout + HLOD (**placement = pick-the-parent; packer owns position** —
re-parent is the only move); compiler-grade ingestion + call-edge provenance; binary
reverse-compile; projection engine + validation; import fidelity report; analysis overlays
(cycles, color-by-metric, version-compare); saved views + fly-through tours; collaboration
(share link, comment threads); headless automation; guided classroom mode; VR (full
desktop↔VR command parity is a hard requirement).

## 6. Hard design constraints
- Every verb keyboard-drivable (a11y + automation + VR parity).
- Non-color status feedback: distinctions encoded ≥2 ways; reserved achromatic+vermillion
  state channel.
- No verb may depend on hover.
- One model, many diagrams: link, don't clone; deletion always distinguishes
  unlink-from-diagram vs remove-from-model.
- 9 personas + 100 user stories exist under project-management/ as validation inputs.

## Platform
Unity 6000.5.x, macOS-first, uGUI harness today (URP/UI-Toolkit/DOTS/XR planned); native
macOS menu bridge exists; shells to osascript/psql/mysql/VS Code; LLM = OpenAI-compatible
client with offline deterministic fallback.
