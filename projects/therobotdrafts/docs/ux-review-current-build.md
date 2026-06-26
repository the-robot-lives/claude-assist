# UX Review — The Robot Draft (current build)

> Scope: the *implemented* authoring app (`Assets/Scripts/Uml*`, `Uml3D/*`, `Llm/*`, `CodeGen/*`)
> reviewed against Nielsen heuristics, the project's own [`docs/specs/authoring-ux.md`](specs/authoring-ux.md)
> and [`design-conventions.md`](specs/design-conventions.md), and ADR-003.
> Date: 2026-06-26. Reviewer: UX engineer pass.

---

## 0. TL;DR

The build is far more capable than the README's "Coming Soon" framing suggests: a working
3D-slab UML editor with create/connect/edit, per-node rotation, Z-layers, undo/redo, code
import, deterministic skeleton codegen, LLM refinement, and round-trip overlay editing. That's
a lot of real surface.

The UX problems are **not** missing features — they're **discoverability, orientation, feedback,
and a structural divergence from your own design spec.** A new user is dropped into a 3D space
with no visible verbs, learns the entire app from one scrolling hint line, can fly themselves
into empty black space with no easy recovery, and reads node labels that turn to mush as soon as
they zoom out. Each of those is fixable without new architecture.

The single biggest decision to make consciously: **the implementation is a free-positioning
canvas-in-3D; the spec is a packer-owned bubble view (ADR-003).** Everything downstream — placement,
"move", the empty state, spatial memory — branches on that choice. Pick deliberately (§2).

---

## 1. Severity-ranked findings

Ranked by `impact × frequency`. P0 = hits every user on every session.

### P0 — fix first

| # | Finding | Heuristic | Evidence |
|---|---------|-----------|----------|
| P0-1 | **No visible command surface for the authoring verbs.** Add/Connect/Delete/Undo/Redo/Project live in right-click menus + hotkeys only. The spec's slim left verb rail (`authoring-ux §2.2`) was never built; the left rail that *does* exist is the kind-palette. A first-timer sees tabs, a palette, and three HUD buttons — none of which say "this is how you connect two classes." | Recognition over recall; Visibility of system status | `UmlCanvas.cs:3158-3259` (palette), `:1340-1609` (verbs buried in context menus) |
| P0-2 | **The whole app is taught by one hint line + a Help modal.** No tooltips on anything, no mode indicator, no "what tool am I in." Connect-by-drag, Alt-rotate, Ctrl-move, Alt+wheel layer change, WASD fly — all invisible until you open Help. | Help & documentation; Recognition | hint line `UmlCanvas.cs:2998`; Help `:3104-3149`; no `tooltip` anywhere |
| P0-3 | **Lost-in-space.** Free-fly (WASD/QE/RF) + orbit with the *only* recovery being Ctrl/⌘+F "frame all," and no focus-on-selection, no compass/horizon, no "where am I." Easy to end up staring into empty black with all nodes behind you. | User control & freedom; Error recovery | camera `UmlCameraRig.cs`; only reset is `FrameAll()` `:154` |
| P0-4 | **Label legibility collapses with distance.** Fixed 15–18 px raster uGUI text on slab faces, no LOD, no fade, no fog. Past ~40 world units every node is an unreadable pinprick — which directly defeats the "fly through a large system" core promise. | Match between system & real world; the product thesis | `UmlNode3D.cs` face canvas, no LOD; `Uml3DConfig.cs` (3 constants, no LOD knobs) |
| P0-5 | **No hover feedback in 3D, tiny hit targets.** Nodes don't highlight on hover; connect hotspots only appear on hover (so they're undiscoverable at rest); edge waypoint handles are 0.12-unit spheres that you must fly up close to grab. | Visibility; affordance | `UmlNode3D.cs` (no hover state); hotspots `UmlNodeView.cs:194-198`; handles `UmlEdgeHandle3D.cs` r=0.06 |

### P1 — fix next

| # | Finding | Heuristic | Evidence |
|---|---------|-----------|----------|
| P1-1 | **Persistence is a single hardcoded file, no naming, no picker.** One `uml-diagram.json` at `persistentDataPath`. You cannot keep two diagrams, name one, or "Save As." Tabs are packages, not documents. | User control; Match to real-world (docs) | `Persistence.cs:103-129` |
| P1-2 | **LLM errors are ephemeral and there's no cancel/spinner.** Failures flash once in the hint line then vanish; a 5–30 s LLM call shows only changing status text (no spinner → reads as frozen); in-flight requests can't be cancelled; folder import can't be aborted. | Visibility of status; User control | CodeGen `:155,276,289`; no cancel; folder import 60 s/file `CodeImport.cs:403` |
| P1-3 | **Plaintext API key in PlayerPrefs, no "Test connection."** Key stored unencrypted; the only way to learn the endpoint is wrong is to run a real generation and watch it fail. | Error prevention; security hygiene | `LlmSettings.cs:25,40`; settings modal `CodeGen.cs:691-726` |
| P1-4 | **No mode/state legibility for spring-loaded actions.** Connect/add have no persistent "active" pill (spec §5.5 explicitly calls for one); active Z-layer changes on Alt+wheel with no HUD readout; per-node rotation accumulates with no indicator. | Visibility of system status | layer scroll `UmlCanvas.cs:597`; no layer HUD |
| P1-5 | **Undiscoverable LLM / import / codegen entry points.** "Import code → elements," "Generate code," "LLM settings" all live behind right-click. A headline feature of the product is invisible. | Recognition | context menu construction `UmlCanvas.cs` / `CodeGen.cs` |
| P1-6 | **Empty state doesn't teach the first move.** Spec §3.4 wants a ghost `＋` "Add the first element"; build instead seeds a sample diagram, then on a truly empty model only flashes a transient string. | Help; onboarding | `RebuildFromModel` flash; spec §3.4 unbuilt |

### P2 — polish

- **Palette has no search/filter** across 13 sections / 40+ items (`UmlCanvas.cs:3158-3227`).
- **Style edits aren't on the undo stack** (creation/deletion are) — pick a wrong color, no Ctrl+Z.
- **Color picker has no live "before/after" + no recent-colors**; hex-only readout.
- **No diff preview before "Approve & save"** on overlay round-trip — you approve a surgical file edit sight-unseen.
- **Multiplicity / type fields accept any string** with no validation until save.
- **Z-move sensitivity 0.01 u/px** is tedious for coarse depth placement (`UmlCanvas.cs:853`).
- **Face canvas can mirror-reverse** if you orbit behind a node or rotate it ~180° (no billboard/flip guard).
- **Code viewer truncates display at 12 KB** (copy is full, but the on-screen cut is silent-ish).

---

## 2. The structural decision (read before P0)

`authoring-ux.md §0` and ADR-003 are emphatic: **the packer owns position; the user picks a
*parent*, not a coordinate.** "There is no free-move, because there is no free space." That
invariant is what buys the product's "stable spatial memory" promise.

The **current build does the opposite**: nodes carry explicit x/y/z, Ctrl-drag free-moves,
Ctrl+Shift-drag moves in Z, manual + force-directed layout (`UmlCanvas.Layout.cs`). It is a 2D
diagram canvas projected onto slabs in 3D — a perfectly reasonable tool, but **not the bubble
view the docs describe.**

This isn't a bug to "fix" blindly — free-positioning is more familiar and may be the right v1.
But it must be a **conscious** choice, because nearly every other recommendation forks on it:

- **If you keep free-positioning:** lean into it — add snap-to-grid, alignment guides, auto-layout
  presets as first-class buttons, and drop the "packer owns position" language from the README so
  the product's story matches the tool.
- **If you commit to the packer/bubble model:** then "move" becomes "re-parent" (spec §3.6),
  the empty state becomes "drop into a container," and placement collapses to one pick — which is
  also what makes the eventual VR story comfortable (spec §7 A1).

**Recommendation:** decide this explicitly and write it as an ADR ("ADR-00x: v1 ships
free-positioning; bubble-packer deferred to v2"), then align README + authoring-ux scope notes.
A reader today cannot tell which product this is.

---

## 3. Recommendations (grouped, actionable)

### A. Make the verbs visible (addresses P0-1, P0-2, P1-4, P1-5)

1. **Build the left verb rail from `authoring-ux §2.2`** — Select / Add / Connect / Delete /
   Undo / Redo / Project, 32 px targets, with the spec's state rendering (active pill, dim when
   disabled). This single change moves the app from "right-click archaeology" to "I can see what I
   can do." Put Import-code and Generate-code on it too (an Output/AI group) — they're headline
   features hiding in a context menu.
2. **Add hover tooltips everywhere**, each showing the hotkey ("Connect — `C` / drag from rim").
   Tooltips are the cheapest, highest-leverage discoverability fix you can ship.
3. **Persistent mode/state HUD:** a small status chip — current tool, active Z-layer (`layer 2/5`),
   and a sticky-mode badge. The spec already designed the reserved white→cyan state channel (§5.1);
   use it.
4. **Show connect affordance at rest, not just on hover** — a faint rim dot on selected nodes
   (spec §4.1 "quick handle on select"), so connecting is discoverable without the hunt-and-hover.

### B. Keep the user oriented in 3D (P0-3, P0-4, P0-5)

5. **`F` = focus/frame selection** (industry-standard in every 3D DCC tool), `Home` = reset to
   default view, plus a HUD "Recenter" button. Today only Ctrl+F frames *everything*.
6. **Distance LOD for labels:** swap raster text for SDF/TextMeshPro and add a 3-tier LOD —
   full card → name-only billboard → colored dot — so a zoomed-out system stays legible. This is
   the one that makes the core "fly through a large codebase" promise actually deliver. (Also the
   prerequisite the spec's §5/§7 already anticipate via the SDF atlas.)
7. **Hover highlight + bigger/scaling hit targets:** lift a node's emissive on raycast-hover;
   scale edge handles with camera distance so they stay grabbable; add a 1-frame highlight on the
   resolved target before commit (also future-proofs the VR dwell-confirm in spec §4.3 C1).
8. **Subtle horizon/grid plane or origin gizmo** so "down" and "home" are always readable; consider
   a soft depth fog to reinforce the Z-layer recession the bubble metaphor depends on.

### C. Documents & files (P1-1)

9. **Real document model:** named diagrams, a recent-files list, New / Open / Save / Save-As, and
   a sensible on-disk folder. Tabs should be documents (or at least decouple "package" from "file").
   Even a minimal in-app file list beats one invisible hardcoded path.
10. **Autosave + restore-last** with a visible "saved ✓ / unsaved •" indicator in the title area.

### D. LLM & round-trip workflow (P1-2, P1-3, P2)

11. **Async with real feedback:** an animated spinner/progress (not just mutating text), a
    **Cancel** button on every LLM operation, and an abortable folder import.
12. **"Test connection" button** in LLM settings that pings the endpoint/model and reports
    pass/fail before the user relies on it.
13. **Persistent, dismissible error surface** (a small toast stack or a log panel) instead of a
    one-shot hint flash — LLM/network/parse failures currently vanish before they're read.
14. **Diff preview before "Approve & save"** on overlay edits — show the surgical change to the
    source file; approving an unseen file rewrite is the scariest moment in the round-trip.
15. **Don't store the key in plaintext** — at minimum obfuscate at rest and document that it's
    local-only; ideally read from an env/secret the way the rest of the Noizu stack does.

### E. Onboarding & first-run (P1-6, P2)

16. **Build the spec's empty-state bootstrap (§3.4):** a center-world ghost `＋` "Add your first
    element," and a one-time 4-step coachmark overlay (Add → Connect → Import code → Generate).
17. **Palette type-ahead / search** so the 40-item kind list is reachable without scroll-hunting.
18. **First-run "Import a repo" CTA** — the import→model→fly-through path is the product's wow
    moment and should be the first thing offered, not a context-menu item.

---

## 4. What's already good (keep)

- Connect-by-drag with green/red valid-target tinting is the right idiom and well executed
  (`UmlCanvas.cs:1520-1530`).
- Deterministic skeleton codegen *before* the LLM call — instant result, LLM only refines — is
  exactly the right latency-hiding pattern (`CodeGen.cs:138-189`).
- Rich per-member UML editing with Rose/Sparx visibility notation, language quick-picks, and
  doc-comments is genuinely powerful.
- Undo/redo, copy/paste, marquee multi-select, edge route handles, syntax-highlighted code viewer
  — solid bones to build the discoverability layer on top of.

---

## 5. Suggested sequence

1. **Verb rail + tooltips + mode/layer HUD** (A1–A3) — biggest discoverability win, low risk.
2. **Focus/Home/recenter + hover highlight** (B5, B7) — kills the lost-in-space and dead-target pain.
3. **SDF label LOD** (B6) — unlocks the core "large system" promise; bigger lift, do it deliberately.
4. **LLM async polish + Test-connection + error toasts** (D11–D13).
5. **Document model + autosave** (C9–C10).
6. **Empty-state bootstrap + first-run import CTA** (E16, E18).
7. In parallel: **write the ADR that resolves §2** so 1–6 are built against a decided product.
