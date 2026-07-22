---
slug: signal
base_theme: theme-style-guide
status: sketch
revision: 1
---

# Theme Treatise — Signal

Theme: `theme-signal/` · Base: `theme-style-guide` · Status: sketch

## 1. Identity

- **Intent:** The graph editor and training tools as a **precision instrument** — a light,
  clinical oscilloscope-on-a-bench aesthetic that treats a fighter's neural net as data to be
  read, measured, and reasoned about. This is the "Minimal Tech" pole of the brief taken to its
  own full theme, where legibility of *numbers* beats spectacle.
- **Perception:** Within five seconds: "this is a serious, accurate tool — I can trust what it
  tells me." Calm, exact, laboratory-clean.
- **Audience:** The AI Researcher (P-006), the Data Artist (P-010), and the Tinkerer (P-001) in
  analysis mode — people who export JSON, read loss curves, and want reproducibility. Also the
  Educator (P-004) who needs credibility in a classroom.
- **Tone:** Neutral, factual, unhurried. Copy names things precisely and never hypes.
- **Keywords:** precise, instrumental, legible, clinical, measured
- **Variant note:** Inherits `theme-style-guide` structure unchanged. The delta is a full
  inversion to a **light** canvas, a single restrained accent, mono-forward data type, and
  thin-line flat surfaces. No structural overrides.

## 2. References & Anchors

- **Anchor — oscilloscope / lab-instrument UIs:** borrow the thin phosphor plot-line on a light
  grid, the tabular numeric readouts, and the "one signal color" discipline.
- **Anchor — TensorBoard / Weights & Biases *light* mode + Observable notebooks:** borrow the
  restrained categorical data palette and the sense that the chart is the content and the chrome
  disappears.
- **Anchor — IBM Carbon / Plex system:** borrow the 2px-grid rigor, the plex-mono numerics, and
  the productive-density spacing.
- **Anti-reference — Neural Neon (this project's dark house style):** deliberately its opposite
  — no glow, no glass, no dark canvas, no display drama. Where neon *performs* the data, signal
  *reports* it.
- **Anti-reference — "dashboard maximalism" (gradient KPI cards, drop-shadow tiles):** no
  decorative gradients on stat cards, no shadow-stacked tiles. A value sits on the grid in plain
  type; emphasis is weight and position, not chrome.
- **Anti-reference — playful rounded toy UIs:** nothing here is cute; corners are near-square,
  the register is instrument, not toybox (that is `sandbox`'s job).

## 3. Color Story

- **Temperature & register:** Cool, light, low-saturation. The field is near-white; color is
  spent almost entirely on data and a single accent. Chrome is grayscale.
- **Hue relationships:** Monochrome-cool neutrals + one **signal teal** accent (`#0A7C6B`
  ~172° for text-safe use, `#14B8A6` brighter for fills/plot lines). A restrained 5-hue
  categorical set — teal, indigo `#4F46E5`, amber `#B45309`, rose `#BE123C`, slate `#475569` —
  exists **for data series only** (node types, plotted curves), never for chrome.
- **Neutral strategy:** Cool gray tinted ~2% toward blue. Canvas `#F7F9FB`, surface `#FFFFFF`,
  ink `#10151C`, grid/border `#D4DCE4`. Not pure white/black — a faint cool bias keeps it
  instrument-like, not sterile-white.
- **Semantic mapping:** Muted and precise — success teal `#0A7C6B` (harmonizes with the accent),
  warning amber `#B45309`, error `#DC2626`, info `#2563EB`. Collision rule: success-teal and the
  teal accent are the same family, so success states must add an icon/label, never rely on the
  teal alone.
- **Contrast stance:** Crisp and high for anything a user reads as data — ink on canvas ≈ 16:1,
  plot lines ≥ 3:1 against the grid. The one place it is allowed to be quiet is the 1px grid
  itself (`#D4DCE4` ≈ 1.3:1) — structure, not content.
- **Mode strategy:** **Light is primary** and the design target — the instrument on a lit bench.
  A dark mode exists as a faithful translation (a dark-oscilloscope: canvas `#0B0F14`, ink
  `#E6EDF3`, plot teal brightened to `#2DD4BF`) for night analysis, but receives no independent
  design decisions. High-contrast: thickens grid to `#94A3B8`, lifts ink and all data lines to
  AAA.

## 4. Typographic Voice

- **Families:** This is the **mono-forward** theme. Data, values, labels, axis ticks, node
  parameters, IDs, and table cells are set in JetBrains Mono (fallback IBM Plex Mono, `monospace`)
  with tabular figures. Prose, headings, and buttons use a neutral sans — Inter or IBM Plex Sans
  (fallback `-apple-system`). No serif, no display face — the theme has no "shout" register.
- **Scale character:** Tight editorial scale, ~1.2 ratio. The largest heading on a working screen
  is ≤ 1.8× body; hierarchy comes from weight and the mono/sans split, not size jumps.
- **Weight usage:** 400 body/data, 500 labels and column headers, 600 section titles. 700 exists
  only for a single emphasized metric. Never bold a data column wholesale.
- **Rhythm:** Body line-height 1.55; data tables 1.4 with tabular alignment. Measure ≤ 72ch for
  prose/docs. Mono is the *default* voice for anything numeric — the inverse of every other theme.

## 5. Space & Density

- **Spacing philosophy:** 8px base, but the theme runs **denser** than the others — 12–16px card
  padding, 8px between related rows — because the audience wants information density (loss curves,
  heatmaps, JSON diffs) on one screen.
- **Density target:** Reference screen is the Training Gym / analytics — a live performance curve
  + sparring selector + an insights list of 3–5 behavioral findings, all on a 390×844 phone
  without scrolling the primary chart out of view. The densest theme in the set.
- **Responsive stance:** Under width pressure, secondary annotation columns collapse into
  disclosure rows first; the primary chart and its axis labels are protected — never shrink a
  data label below 12px or drop a legend.

## 6. Shape & Surface

- **Radius language:** Near-square precision — 2px on inputs/chips, 4px on cards, 6px maximum.
  No pills anywhere (a pill would read as "app," not "instrument").
- **Borders:** **Visible structural borders are the point** — 1px `#D4DCE4` hairlines define
  every card, table, and panel edge; the grid is the skeleton. This is the one theme that
  separates surfaces by line, not tone or shadow.
- **Elevation:** Flat. No shadows in v1 except a 1px darker hairline under sticky headers.
  Layering is expressed by border + a half-step surface tint, never by drop shadow.
- **Texture & gradient policy:** No gradients on chrome, ever. The only gradient permitted is a
  data encoding — a sequential ramp inside a heatmap cell or a plotted area fill at ≤ 15% alpha.
  No glow, no glass, no scanline.

## 7. Motion & Feedback

- **Animation character:** Instrumental and minimal — motion exists to show a *value changing*
  (a curve extending, a counter ticking), never for decoration.
- **Duration & easing:** Micro-feedback 80–120ms ease-out; plotted lines draw 200ms linear; panel
  transitions ≤ 160ms ease-out. Nothing exceeds 200ms. No spring, no bounce, no parallax.
- **Interaction states:** Hover adds a 1px accent underline or a half-step surface tint; active
  darkens the border; focus is a 2px teal ring; disabled drops to 50% and removes the border
  accent. State changes read through border/weight, never hue alone (P-008, US-071).

## 8. Component Inflections

- **Buttons:** Reserved and rectangular — primary is a solid teal fill (`#0A7C6B`) with white
  text, 4px radius; secondary is a 1px-border ghost on white; tertiary is a plain text button.
  Buttons are the *only* saturated chrome element and are used sparingly.
- **Inputs:** The workhorse — crisp 1px-border fields, 2px radius, mono value text, a persistent
  unit/label suffix. Focus swaps to the teal ring. Number inputs show tabular figures.
- **Cards:** Bordered white rectangles, 4px radius, 12–16px padding, no shadow. A card titled by
  a 500-weight sans label with mono data beneath is the base pattern for every stat/insight tile.
- **Navigation:** A quiet bottom tab bar (light) with 1px top border; active tab = teal glyph +
  teal 2px underline + 600 label. Side/section nav uses a left-rail teal marker.
- **At base defaults (deliberately untouched):** modals, toasts, and breadcrumbs inherit
  `theme-style-guide` behavior, recolored to the cool neutrals.

## 9. Accessibility Commitments

- **WCAG target:** 2.2 AA minimum; AAA for data-table body text and axis labels specifically,
  since reading numbers correctly is the product promise. Strong fit for P-006/P-008 needs.
- **Contrast minimums:** 4.5:1 body, 3:1 large/UI and plot lines against grid. Near-the-line
  pairs to recheck: **signal-teal `#0A7C6B` on white ≈ 4.9:1** (passes body, but do not lighten
  the teal without rechecking); the categorical amber `#B45309` and rose `#BE123C` on white sit
  at ≈ 5:1 and ≈ 6:1 — safe, but as *data lines* they must also clear 3:1 against the `#D4DCE4`
  grid, which amber only barely does — pair with a shape/dash marker.
- **Focus visibility:** 2px teal ring, 2px offset; ≥ 3:1 on both white surface and the grid.
  Never removed.
- **Reduced motion:** `prefers-reduced-motion` makes curves and counters render to final value
  instantly; nothing else animates, so the theme degrades to zero motion cleanly.

## 10. Facet Mapping Appendix

| Treatise section | Engine facet | Seed hints |
|---|---|---|
| §1 | `branding.yaml` | name "Signal"; intent/perception/audience/tone verbatim; keywords: precise, instrumental, legible, clinical, measured; font-url: IBM Plex Sans + JetBrains Mono |
| §3 neutrals | `style-guide.vars.yaml` Surfaces | white(canvas) `#F7F9FB`, surface `#FFFFFF`, ink `#10151C`, border `#D4DCE4` |
| §3 accent | `style-guide.vars.yaml` Brand | single brand teal `#0A7C6B` (text), `#14B8A6` (fill/line); do not add a second brand hue |
| §3 semantics | `style-guide.vars.yaml` Semantic | success `#0A7C6B`, warning `#B45309`, error `#DC2626`, info `#2563EB` |
| §3 data palette | `style-guide.color-palette.yaml` | categorical: teal/indigo `#4F46E5`/amber `#B45309`/rose `#BE123C`/slate `#475569` — data series only, usage rule "never chrome" |
| §3 modes | `style-guide.color-modes.yaml` | light primary; dark faithful (canvas `#0B0F14`, ink `#E6EDF3`, teal `#2DD4BF`); high-contrast grid `#94A3B8` |
| §4 | `style-guide.vars.yaml` Typography + `style-guide.typography.yaml` | font-sans `'IBM Plex Sans',Inter,sans-serif`; font-mono `'JetBrains Mono','IBM Plex Mono',monospace` as the data default; 1.2 scale |
| §5 | `style-guide.vars.yaml` Layout + `style-guide.spacing.yaml` | unit 8px; dense-tooling note (12–16px padding); protect 12px data labels |
| §6 | `style-guide.vars.yaml` radius + `style-guide.css-snippets.yaml` | radius 4px base, 6px max, no pill; 1px hairline border system; flat (no shadow) |
| §7 | `style-guide.css-snippets.yaml` / `style-guide.scoped-vars.yaml` | `--motion-micro:100ms`, `--motion-plot:200ms linear`; reduced-motion → instant |
| §8 | `style-guide.css-snippets.yaml` + `style-guide.semantic-classes.yaml` | button/input/card/nav per §8; leave modals/toasts/breadcrumbs at base |
| §9 | verification pass, all facets | recheck teal-on-white (4.9:1) and amber data line vs grid after any seed change |
