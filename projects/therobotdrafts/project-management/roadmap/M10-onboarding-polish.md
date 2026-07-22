# M10 — Onboarding, Education & A11y Polish

Close v1 with the onboarding, education, and accessibility polish that turns a capable tool into a
teachable, inclusive one: a one-time coachmark overlay, guided fly-throughs, a simplified classroom
mode, high-contrast and monochrome-safe rendering, and a full WCAG audit pass. This milestone
**completes the accessibility arc opened in M3** — it extends the M3 primitives (keyboard verbs,
non-color encoding, reduced motion, non-color status) rather than re-implementing them — and turns
the `docs/diagrams/` corpus into demo and teaching content. It is the final pre-v1 track on the
M6→M10 branch.

## Entry criteria

- **M6 exit.** Collaboration and sharing landed: presentation mode (US-040), recorded tours (US-041,
  whose playback the guided fly-through reuses), shareable model files (US-085), annotations, and
  BE-RT presence.
- **M3 exit.** Core accessibility shipped — keyboard-driven verbs (US-096), non-color kind/edge
  encoding (US-097), reduced-motion mode (US-098), non-color status feedback (US-100), the verb
  rail, and tooltips. M10 builds on these; it does not redo them.
- The `@noizu/styleguide` YAML token pipeline is available for deriving theme variants.
- Runs concurrently with M7, M8, and M9 as the final track; all four close before v1.

## Gate tasks

Two small freezes, front-loaded.

**M10-FE-SHELL-01 — Onboarding content + step schema** (size: S)
Freeze the coachmark/step model (target selector, copy, order, dismiss-once persistence) and the
classroom-mode configuration (which verbs/panels are shown, step sequence). Unblocks the coachmark
overlay and classroom mode.
depends: M6 exit · stories: US-020, US-088

**M10-INFRA-01 — Contrast + monochrome theme token contract** (size: S)
Define high-contrast and monochrome-safe theme variants as `@noizu/styleguide` token sets: label
contrast floors, non-hue kind/edge encodings, and projector-legibility targets. Unblocks the FE-GL
contrast/monochrome rendering and the FE-SHELL theme switcher.
depends: M6 exit · stories: US-082, US-086, US-099

## Lanes & tasks

### FE-SHELL — onboarding, classroom mode, theming, UI audit fixes

**M10-FE-SHELL-02 — One-time coachmark overlay** (size: M)
An overlay that teaches the core verbs on first run, with dismiss-once persistence, full keyboard
reachability, and reduced-motion-aware transitions.
depends: M10-FE-SHELL-01 · stories: US-020

**M10-FE-SHELL-03 — Simplified classroom mode** (size: M)
A reduced-surface guided mode (fewer verbs, larger targets, stepwise progression) suited to teaching
and demos.
depends: M10-FE-SHELL-01 · stories: US-088

**M10-FE-SHELL-04 — Theme switcher** (size: S)
Surface the high-contrast and monochrome-safe theme variants in settings, persist the choice, and
respect the OS `prefers-contrast` signal.
depends: M10-INFRA-01 · stories: US-082, US-086

**M10-FE-SHELL-05 — WCAG audit fixes (non-3D UI)** (size: M)
Resolve audit findings across the app shell: focus order, ARIA roles/labels, contrast, and form
labeling. Advances the label/contrast stories at the UI (non-renderer) layer.
depends: M10-QA-01 · stories: US-082, US-099

### FE-GL — contrast, monochrome, guided fly-through

**M10-FE-GL-01 — High-contrast labels regardless of hue** (size: M)
Contrast-guaranteed label plates/outlines that stay legible independent of node color and remain
projector-legible.
depends: M10-INFRA-01 · stories: US-082, US-099

**M10-FE-GL-02 — Monochrome-safe rendering** (size: M)
Encode kind and edge type with shape, pattern, and outline so the model is fully readable with hue
removed, driven by the monochrome token set (for projectors and handouts).
depends: M10-INFRA-01 · stories: US-086

**M10-FE-GL-03 — Guided fly-through of a subsystem** (size: M)
A scripted/curated camera tour over a selected subsystem, reusing the M6 recorded-tour playback, with
a reduced-motion fallback (instant cuts instead of sweeps).
depends: M6 exit, M10-FE-SHELL-01 · stories: US-036

### QA + content

**M10-QA-01 — Full WCAG audit pass** (size: L)
Integrate axe-core into Cypress across the key flows; run keyboard-only journeys; check contrast on
label plates and UI; confirm reduced motion is honored throughout. Produces the findings that
FE-SHELL-05 and FE-GL fixes close.
depends: M6 exit · stories: US-082, US-086, US-099 (verification)

**M10-QA-02 — Onboarding + classroom e2e** (size: M)
The first-run coachmark appears once, dismisses, and is keyboard-navigable; classroom mode reduces
the surface; the guided fly-through runs and honors reduced motion.
depends: M10-FE-SHELL-02, M10-FE-SHELL-03, M10-FE-GL-03 · stories: US-020, US-036, US-088

**M10-QA-03 — Demo & teaching content from the corpus** (size: M)
Curate the `docs/diagrams/` corpus (per `EXAMPLES-MANIFEST.md`) into loadable demo/teaching
documents and a demo-gallery seed, giving classroom mode and onboarding real content to open.
depends: M10-FE-SHELL-03 · stories: US-088 (supports)

## Integration & exit criteria

**M10-INT-01 — A11y + onboarding integration** (size: M) — joins FE-SHELL, FE-GL, QA.
High-contrast and monochrome themes apply consistently across the shell and the renderer; the
coachmark, classroom mode, and fly-through all work under both themes and reduced motion; the WCAG
audit passes with no critical findings.
depends: all M10 lane tasks · stories: US-020, US-036, US-082, US-086, US-088, US-099

**M10-INT-02 — v1 accessibility readiness gate** (size: S) — joins QA, FE-SHELL, FE-GL.
The WCAG audit is green; the M3 accessibility P0s plus the P1 label-contrast story (US-099) are
verified end-to-end; demo/teaching content loads. This gate, together with M7/M8/M9 exits, releases
v1.
depends: M10-INT-01 · stories: US-099 (verification)

**Exit checklist**
- US-020, US-036, US-082, US-086, US-088, US-099 all demonstrable.
- Full WCAG audit passes with no critical findings; keyboard-only journeys complete.
- Demo and teaching content from the corpus loads in classroom mode and onboarding.
- The accessibility arc is complete: M3 P0s plus the M10 P1 contrast/label stories verified together.

**Demo script.** Launch fresh: the coachmark overlay teaches the verbs and dismisses; switch to the
high-contrast theme and confirm labels stay legible over any node color; switch to monochrome and
confirm kind/edge type are still readable by shape; enter classroom mode, open a corpus example, and
run a guided fly-through of a subsystem with reduced motion on.

## Parallelization notes

- **Workers supported:** ~3–4 (FE-SHELL, FE-GL, QA, plus a light INFRA/content worker).
- **Gate order:** the step schema (FE-SHELL-01) and theme token contract (INFRA-01) freeze first and
  are independent, so they can be authored in parallel.
- **Lane isolation within M10:** FE-SHELL owns `frontend/src/app/` and non-3D `components/`, FE-GL
  owns `frontend/src/renderer/`, QA owns `frontend/cypress/` and the demo fixtures. No shared
  directories inside the milestone.
- **Cross-milestone contention:** FE-GL is shared with M8 and FE-SHELL with M5/M6. Schedule M10's
  FE-GL contrast/monochrome/fly-through work **after** M8's renderer work lands (the same FE-GL
  worker carries both, sequentially), and M10's FE-SHELL work after the M6 shell/collab work it
  extends. This ordering keeps `frontend/src/renderer/` and `frontend/src/app/` single-writer across
  the concurrent tracks.
- **Merge order:** gates → theme + coachmark implementations → WCAG fixes → INT-01 → v1 a11y gate.

## Stories delivered

| ID | Priority | Persona | Title |
|----|----------|---------|-------|
| US-020 | P1 | Marcus | Teach the core verbs with a one-time coachmark overlay |
| US-036 | P2 | Marcus | Take a guided fly-through of a subsystem |
| US-082 | P1 | Elena | Render projector-legible high-contrast labels |
| US-086 | P2 | Elena | Render monochrome-safe for projectors and handouts |
| US-088 | P2 | Elena | Offer a simplified guided mode for the classroom |
| US-099 | P1 | Theo | Read high-contrast labels regardless of hue |
