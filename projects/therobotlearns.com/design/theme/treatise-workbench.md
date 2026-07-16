---
slug: workbench
base_theme: theme-style-guide
status: sketch
revision: 1
---

# Theme Treatise — Workbench

Theme: `theme-workbench/` · Base: `theme-style-guide` · Status: sketch

> **Reverse-engineered** from the shipped `theme-workbench/` YAML (Stage A). The treatise
> justifies the on-disk values and flags anything arbitrary. **Surface note:** the product is
> a terminal agent; Stage C renders Workbench onto a mocked terminal — its cream-paper canvas
> and taped-note motifs translate to a warm light terminal skin (a maker's reference sheet),
> styled by the `@noizu/styleguide` CSS theme.

## 1. Identity

- **Intent:** Learning as hands-on tinkering — pin ideas to the board, sketch connections,
  tape references together. The messiness is the method.
- **Perception:** "Tactile, informal, creative — a workshop where someone brilliant has been
  prototyping all night. Organized chaos that makes sense."
- **Audience:** Makers, tinkerers, visual thinkers, and project-based learners who think best
  with their hands.
- **Tone:** Casual, encouraging, slightly messy — scribbled margin notes over formal
  paragraphs; "Try this!" over "Note that."
- **Keywords:** hands-on, sketch, build, pin, tinker, workshop
- **Relationship to base:** inherits `theme-style-guide` structure and ships the heavier tier
  (`typography.yaml`, `css-snippets`, `globals`). The delta is a warm cream-paper canvas, brown
  ink, a printed geometric sans for body paired with a handwritten face for annotations, a
  slight 3px radius, and a Flat-UI clay palette. Sibling to `chalkboard` (both hand-drawn
  teaching themes); Workbench is the **light cream-paper maker bench** with pen-and-tape, where
  chalkboard is the dark slate with chalk.

## 2. References & Anchors

- **Anchor — a cork board of pinned notes, polaroids, and tape (per `meta.yaml`):** borrow the
  "cards float as pinned paper" layout — separated by shadow and space, not by ruled lines.
- **Anchor — a maker's physical workbench:** borrow the tactile, slightly-irregular
  arrangement and the mix of *printed* reference sheets with *handwritten* margin notes.
- **Anchor — the Flat UI color system:** the palette (`#e74c3c`, `#2980b9`, `#f1c40f`,
  `#27ae60`, `#9b59b6`…) is drawn straight from Flat UI Colors — borrow its friendly clay
  saturation, distinct from chalkboard's dusty desaturation.
- **Anti-reference — `chalkboard`'s dark slate:** Workbench is light paper, not a dark board —
  brown ink on cream, the inverse surface of its sibling.
- **Anti-reference — a sterile minimal productivity tool:** the theme embraces organized mess —
  handwritten Caveat titles, taped corners, a little rotation; a clinical flat-design tool
  would strip out exactly the personality that defines it.
- **Anti-reference — a polished corporate design system:** no pristine grid, no uniform
  shadows; imperfection (a note pinned slightly askew) is a feature.

## 3. Color Story

- **Temperature & register:** Warm and light-primary. Cream paper `#f5f0e8` (≈40° warm) with
  brown ink `#2c2416`; accents are friendly Flat-UI clay tones — saturated but earthy.
- **Hue relationships:** A warm-neutral paper base + a categorical clay palette (13 hues), with
  orange `#e67e22` as the recurring accent border color and blue `#2980b9` as the link/primary.
  Like chalkboard, color is used *categorically* (pin colors, marker colors), not as a single
  dominant brand hue.
- **Neutral strategy:** Warm cream and tan — every neutral is paper-tinted (`#f5f0e8`,
  `#ebe4d6`, borders `#d4c9b5`). Pure gray never appears; the darks are warm browns
  (`#2c2416`, `#5d4e37`).
- **Semantic mapping:** Flat-UI set — success `#27ae60`, warning `#f39c12`, error `#e74c3c`,
  info `#2980b9`. They harmonize with the clay palette. Collision rule: error red `#e74c3c` is
  also `brand-red`, so error states pair the color with an icon/label so a red pushpin isn't
  read as a failure.
- **Contrast stance:** High for ink-on-paper (brown `#2c2416` on cream `#f5f0e8` ≈ 12:1); clay
  accents are mid-value and must be verified at text size (see §9).
- **Mode strategy:** **Light is primary and the design target** — a bright paper workbench. A
  dark mode exists as a faithful translation (a "dark wood bench": surface `#2c2416`, text
  `#e8dfd0`, same clay accents) but receives no independent design. No high-contrast mode in
  v1 — light-mode ink-on-cream clears AA with wide margin.

## 4. Typographic Voice

- **Families:** Body/UI/buttons is Outfit (a clean geometric sans — the *printed* reference
  sheet, the typed label); display/titles/sticky-note text/annotations is Caveat (a handwritten
  script — the *scribbled* margin note); code/tokens is Source Code Pro. Rationale: the
  printed-vs-handwritten pairing *is* the theme — formal content is typed, personal asides are
  hand-scrawled. `font-url` cleanly imports exactly these three (no dead imports).
- **Scale character:** Moderate for body (Outfit), expressive for display (Caveat set larger
  with a slight negative letter-spacing at the big end). Headings gain personality from the
  handwritten face, not from extreme size.
- **Weight usage:** Outfit 400–700 (body 400, labels 500–600, emphasis 700); Caveat 400–700
  for titles/annotations. **Honest flag:** `typography.yaml` defines Display, H1, H2, and Label
  classes but **no `Body` class** (it jumps H2 → Label) — body text falls back to base
  defaults; recommend adding an explicit Body class (Outfit 400) so body rhythm is intentional,
  not inherited.
- **Rhythm:** Comfortable body line-height; Caveat annotations sit tighter. Mono for code,
  token values, and metadata only.

## 5. Space & Density

- **Spacing philosophy:** Casual and slightly irregular — cards read as pinned notes with air
  around them (`card-separator-style: none`; separation by space/shadow, not rules). Padding is
  generous inside notes.
- **Density target:** Reference screen is a project/settings board: several pinned "note" cards
  arranged on the cork surface, comfortably spaced — a corkboard, not a data grid.
- **Responsive stance:** Under width pressure, note cards reflow (re-pin) from a multi-column
  board to a single column; card padding and the handwritten label legibility are protected.

## 6. Shape & Surface

- **Radius language:** `3px` — a slight, cut-paper/taped-corner softness; not crisp-square, not
  round. The smallest non-zero radius among this project's soft themes.
- **Borders:** Card separators are **none** — notes are delineated by shadow and whitespace,
  like paper lifted off cork, not by ruled boxes. Where a line is needed, it is a warm tan.
- **Elevation:** **Workbench uses shadow deliberately** (unlike the flat terminal themes) — soft
  warm-brown shadows (`rgba(44,36,22,0.12)`) lift note cards off the board; typically two steps
  (resting note vs raised/dragged note).
- **Texture & gradient policy:** **Texture is sanctioned** — cork, paper grain, tape strips, and
  pushpins are on-brand (in `css-snippets`/`globals`). Constraint: texture stays behind content
  and must not reduce text contrast below §9 floors.

## 7. Motion & Feedback

- **Animation character:** Tactile and playful-but-restrained — pin/unpin, a slight tilt-and-
  settle when a card lands, a Caveat "write-on" for annotations.
- **Duration & easing:** Settle/pin 200–300ms with a gentle ease-out (a hint of overshoot is
  allowed here, unlike the tool themes); micro-feedback ~120ms. Nothing exceeds ~350ms.
- **Interaction states:** Hover lifts the card (raise shadow one step) and may tilt ~1°;
  active/press "pins" it (drop shadow, settle); focus is a clay-colored outline; disabled fades
  to ~45% like an old note. State pairs elevation/tilt with color — never color alone.

## 8. Component Inflections

- **Buttons:** Outfit-labeled, filled in a clay accent (blue primary `#2980b9` / orange
  `#e67e22`) with a 3px radius; secondary is a taped/bordered ghost on paper.
- **Inputs:** Fields read like lined note paper — a warm underline or light box on cream; focus
  swaps to a clay outline. Labels may be handwritten (Caveat) above the printed field.
- **Cards → pinned notes:** The workhorse surface — cream note with a soft lift shadow, no
  border, optional slight rotation and a pushpin/tape motif; the title may be handwritten.
- **Navigation:** Tabs or a rail styled as taped labels; the active item is marked with a clay
  underline/highlight + weight, like a highlighted tab on a binder.
- **At base defaults (deliberately untouched):** toasts, breadcrumbs, and modal structure
  inherit `theme-style-guide` with the clay/paper tokens applied.

## 9. Accessibility Commitments

- **WCAG target:** 2.2 AA across both modes; ink-on-cream clears AAA in light mode.
- **Contrast minimums:** Brown `#2c2416` on cream `#f5f0e8` ≈ 12:1 (pass). **Near-the-line
  pairs the fine-tuner must verify: text-secondary `#5d4e37` ≈ 6:1 (ok), text-muted `#a08e72`
  ≈ 2.7:1 — decorative/large only, never body; border-accent orange `#e67e22` ≈ 2.8:1 on cream
  — a border/large-UI color, not text.** Clay semantics (`#e74c3c` error, `#2980b9` info) as
  text on cream land ~3.5–4.5:1 — verify each and prefer them at label size or as fills with
  the ink text on top.
- **Focus visibility:** A clay-colored outline (≥2px) on every focusable element; verify it
  clears 3:1 on cream (the orange accent alone does not — use blue `#2980b9` or a darker clay
  for the focus ring). Never removed.
- **Non-color guarantee:** Because red is both brand and error and clay hues are mid-value,
  status pairs color with an icon/label — never hue alone.
- **Reduced motion:** `prefers-reduced-motion` disables tilt/settle/pin animations and the
  Caveat write-on; cards appear placed, not dropped.

## 10. Facet Mapping Appendix

| Treatise section | Engine facet | Seed hints |
|---|---|---|
| §1 | `branding.yaml` | name "The Robot Learns — Workbench"; intent/perception/audience/tone verbatim; keywords: hands-on, sketch, build, pin, tinker, workshop |
| §3 neutrals | `style-guide.vars.yaml` Surfaces | white `#f5f0e8` (paper), black `#2c2416` (brown ink); warm tan borders |
| §3 palette | `style-guide.vars.yaml` / `color-palette.yaml` | 13-hue Flat-UI clay palette; accent orange `#e67e22`, primary/link blue `#2980b9` |
| §3 semantics | `style-guide.vars.yaml` Semantic | success `#27ae60`, warning `#f39c12`, error `#e74c3c`, info `#2980b9` |
| §3 modes | `style-guide.color-modes.yaml` | light primary (cream `#f5f0e8`/ink `#2c2416`); dark: surface `#2c2416`, text `#e8dfd0` |
| §4 | `style-guide.typography.yaml` + `vars.yaml` | font-sans Outfit, font-display Caveat, font-mono Source Code Pro; **add missing Body class (Outfit 400)** |
| §5 | `style-guide.vars.yaml` Layout | casual spacing; `card-separator: none`; corkboard reflow |
| §6 | `style-guide.vars.yaml` radius + `css-snippets.yaml` | radius `3px`; soft warm shadows (2 steps); sanctioned cork/tape/pushpin texture |
| §7 | `style-guide.css-snippets.yaml` | pin/settle keyframes 200–300ms (slight overshoot ok); reduced-motion guard |
| §8 | `style-guide.semantic-classes.yaml` | clay-fill buttons, note-paper inputs, pinned-note cards (shadow, no border), taped-label active nav |
| §9 | verification across facets | verify clay semantics + `#a08e72`/`#e67e22` on cream; use blue/dark-clay (not orange) for focus ring |
