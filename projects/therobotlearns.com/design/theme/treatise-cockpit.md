---
slug: cockpit
base_theme: theme-style-guide
status: sketch
revision: 1
---

# Theme Treatise — Cockpit

Theme: `theme-cockpit/` · Base: `theme-style-guide` · Status: sketch

> **Surface note.** Rendered by Stage C onto a **mocked terminal window**, not a web page.
> "Panel," "pane," and "card" mean box-drawing regions inside a modern TUI; the
> `@noizu/styleguide` CSS theme supplies the colors, meters, and label styling.

## 1. Identity

- **Intent:** A modern, dense TUI "mission control" in the lineage of k9s, btop, and
  lazygit. Cool graphite panes, box-drawing dividers, meter/spark bars, a single electric-
  magenta signal for focus and selection, and a disciplined four-color status set. Every
  pixel is instrumentation; nothing is decoration.
- **Perception:** In five seconds: "this is a professional instrument panel — many live
  panes, one signal color, everything measured and current." Competent, cool, awake.
- **Audience:** Power users running dashboards and consoles in a terminal — the maintainer
  watching KB health, the team lead scanning a fleet, anyone who reaches for `htop` reflexively.
- **Tone:** Clipped instrument labels and status-first copy. `IDX 4.2k · SYNC ok · 3 stale`,
  not "Your index has 4,200 entries and everything looks great."
- **Keywords:** instrument, dense, signal, mission-control, measured
- **New direction (not a restyle of an existing theme):** inherits `theme-style-guide`
  structure unchanged. The delta is a cool multi-signal dark palette, a dual mono+grotesk
  type system, flat box-drawn panes, and meter/spark chrome. Distinct from Phosphor
  (modern/cool/multi-signal vs retro/warm/monochrome) and from Deep Focus (dense instrument
  vs calm minimal); it serves the dashboard and console screens directly.

## 2. References & Anchors

- **Anchor — k9s:** borrow the pane grid, the persistent command/keybind footer, and the
  convention of a highlighted *active pane* with a live selected row.
- **Anchor — btop / bpytop:** borrow the block-glyph meters and sparklines (`▁▂▃▄▅▆▇█`) and
  the willingness to pack graphs and gauges at high density.
- **Anchor — lazygit:** borrow keyboard-driven focus movement between bordered panes and the
  compact status/diff column layout.
- **Anchor — Grafana dark / GitHub dark status palette:** borrow the proven, terminal-legible
  semantic set (green/amber/red/blue) rather than inventing status hues.
- **Anti-reference — Phosphor's monochrome retro CRT:** Cockpit is *modern and cool*, not
  nostalgic — multiple disciplined signal colors on cool graphite, no amber, no CRT filters.
- **Anti-reference — consumer analytics dashboards (big rounded cards, drop shadows, pastel
  gradients):** Cockpit is flat, dense, and box-drawn; there are no floating cards, no
  shadows, no marketing whitespace. Density wins over airiness every time they conflict.
- **Anti-reference — "every metric its own color" rainbow dashboards:** one accent signal
  (magenta) plus exactly four status hues; a fifth decorative color is a bug.

## 3. Color Story

- **Temperature & register:** Cool and crisp. Neutrals are blue-tinted graphite (≈215–220°);
  the one saturated brand element is an electric magenta. Status colors are saturated but
  rationed to their four meanings.
- **Hue relationships:** Graphite monochrome-cool + a single magenta accent `#ff2e88`
  (selection, active focus, primary key). Magenta is deliberately *off* the semantic axis
  (not red/green/blue/amber) so "selected" never reads as "error" or "ok."
- **Neutral strategy:** Cool graphite, not pure gray. Re-seed base `black` to `#0e1116`
  (≈215° hue, very low lightness) and `white` to `#c9d1d9` (cool off-white), so the derived
  ramp stays blue-cool. Pure gray and warm tints never appear.
- **Semantic mapping:** Disciplined and fixed — success `#3fb950`, warning `#d29922`, error
  `#f85149`, info `#58a6ff` (the GitHub-dark set, chosen because it is battle-tested for
  legibility on dark graphite). Each is always paired with a glyph (`✓ ! ✗ i`) so status
  survives grayscale and colorblind viewing. Collision rule: magenta accent must never be
  used for a status meaning, and error-red must not fill a large area adjacent to magenta
  selection (they are close enough in a dense field to need the glyph + position to separate).
- **Contrast stance:** High and instrument-crisp everywhere — Cockpit has no "soft" register.
  Data text targets ≥10:1; even dividers stay legible rather than whisper-faint.
- **Mode strategy:** **Dark is primary and the design target** — a cockpit is a dark
  instrument panel. A "daylight instrument" light mode (graphite text `#1c2128` on pale
  `#eef1f4`, magenta darkened to `#c81e6e`) exists as a faithful translation but gets no
  independent design decisions. No high-contrast mode in v1: the dark palette clears AA with
  margin and forced-colors users get system colors.

## 4. Typographic Voice

- **Families:** Dual system. **Mono for all data, values, meters, and tables** — seed
  `'JetBrains Mono', 'IBM Plex Mono', monospace` (its tabular figures keep columns aligned).
  A **tight grotesk for pane titles and field labels only** — seed `'Inter', -apple-system,
  sans-serif`. Rationale: numbers must align (mono), but dense labels read faster in a
  proportional grotesk; the split keeps both jobs sharp. No serif anywhere.
- **Scale character:** Tight instrument scale, ≈1.2 ratio. Pane titles are small-caps-ish
  labels, not large headings; the biggest text on a dashboard is at most 1.5× the data size.
- **Weight usage:** 400 data, 500 labels, 600 pane titles and the active tab. Magenta + weight
  mark the active element; weight alone never carries status.
- **Rhythm:** Line-height 1.35 (dense). Mono runs the data planes; grotesk labels sit on a
  tighter 1.25. Mono is everywhere data lives; grotesk is *only* titles/labels — never body
  prose (Cockpit has almost no prose).

## 5. Space & Density

- **Spacing philosophy:** Tight — base unit 4px, padding spent inside panes (8–10px) with
  minimal gutters (4–6px) between them. The layout is a packed grid of bordered panes, not
  cards floating in whitespace.
- **Density target:** Reference screen is the team-lead dashboard (`18`) / KB-maintenance
  console (`14`): 4–6 panes (status header, meter column, a data table, a log tail, a keybind
  footer) all live on one 120×40 terminal without scrolling. This is the densest of every
  theme here except where Phosphor packs raw rows.
- **Responsive stance:** Under width pressure, panes reflow from side-by-side to stacked;
  full meters degrade to inline sparkbars; the primary data table's columns and the keybind
  footer are protected — legibility of the numbers is never traded for fitting another pane.

## 6. Shape & Surface

- **Radius language:** `0–1px`. Panes are crisp rectangles; 1px is the maximum, reserved for
  small inline chips/badges. No soft corners, no pills.
- **Borders:** 1px box-drawing rules in dim graphite `#30363d` divide panes; the **active
  pane's border is magenta `#ff2e88`** — that border color *is* the focus system. Titled
  panes carry the label in the top rule (`│ KB HEALTH ├───────┤ 4.2k idx ├`).
- **Elevation:** Flat tonal only. The active pane lightens one graphite step (`#161b22`) and
  gains the magenta border; there are no drop shadows except a single soft one under a modal
  overlay (`rgba(1,4,9,0.6)`). Depth is border-and-tone, never shadow.
- **Texture & gradient policy:** No decorative texture or gradient. The only "graphic"
  elements are block-glyph meters and sparklines, and an optional 1px magenta underfill on an
  active meter bar. No noise, no glass, no marketing gradients.

## 7. Motion & Feedback

- **Animation character:** Instrumental — motion means "a value changed." Meters fill, values
  tick, the selected row moves; nothing animates for delight.
- **Duration & easing:** Pane focus and row selection 100–160ms ease-out; live meter fills up
  to 200ms linear; nothing exceeds 250ms. No spring, bounce, or scroll-triggered motion.
- **Interaction states:** Hover highlights the row/pane one graphite step; active/selected is
  a magenta left-edge bar **plus** reverse-or-highlighted row (never magenta text alone);
  focus is a 1–2px magenta outline/underline on the focused control; disabled drops to 40%
  and loses its border. Status changes pair color with a glyph so the change reads without
  hue.

## 8. Component Inflections

- **Buttons:** Compact — a filled magenta primary "action key" (`⏎ APPLY`) is the only
  saturated fill on a screen; secondary actions are dim-graphite bracketed labels with a
  keybind hint. Destructive uses error-red as a bracketed ghost, filling only on confirm.
- **Inputs:** Single-line fields with a grotesk label prefix and a magenta caret; a filter/
  command input mimics k9s's `:`-prompt at the pane top. Focus swaps the graphite underline
  for magenta.
- **Cards → panes:** The workhorse surface is a box-drawn pane with a titled top rule, a
  `key : value` or tabular body, and an optional meter/sparkline row. No background fill
  beyond the one-step-lighter active tone; no border unless it is a pane (everything is).
- **Navigation:** A top tab/status strip and a persistent bottom keybind footer (`[1]health
  [2]index [3]log  :cmd  ?help`); the active tab is 600-weight + magenta underline. Content
  panes carry the selected-row magenta bar.
- **At base defaults (deliberately untouched):** toasts, breadcrumbs, and modal *structure*
  inherit `theme-style-guide`, recolored through graphite+magenta tokens only.

## 9. Accessibility Commitments

- **WCAG target:** 2.2 AA across both modes; data text targets AAA (7:1) in dark mode since
  operators scan numbers for long stretches.
- **Contrast minimums:** Data `#c9d1d9` on canvas `#0e1116` ≈ 12:1 (pass with margin). Status
  on graphite the fine-tuner must verify: error `#f85149` ≈ 6:1, info `#58a6ff` ≈ 6.5:1,
  success `#3fb950` ≈ 6:1, **warning `#d29922` ≈ 4.7:1 — the near-the-line pair; keep it at
  label size or larger, never sub-body**. Magenta `#ff2e88` on canvas ≈ 6:1 (safe for UI/
  large; not for body text).
- **Non-color status guarantee:** Every status is a color **and** a glyph (`✓ ! ✗ i`) and,
  where possible, a position — critical in a dense multi-pane field and for colorblind
  operators. Selection (magenta) is always reinforced by the edge bar/highlight, never hue
  alone.
- **Focus visibility:** Magenta 1–2px outline on the focused control and magenta border on the
  focused pane; both exceed 3:1 against every graphite surface. Focus is never removed.
- **Reduced motion:** `prefers-reduced-motion` replaces meter-fill animations with instant
  value swaps and disables the selected-row slide; the data (the number, the bar length)
  always survives — only the animation is dropped.

## 10. Facet Mapping Appendix

| Treatise section | Engine facet | Seed hints |
|---|---|---|
| §1 | `branding.yaml` | name "Cockpit"; intent/perception/audience/tone verbatim; keywords: instrument, dense, signal, mission-control, measured |
| §3 neutrals | `style-guide.vars.yaml` Surfaces | black: `#0e1116`, white: `#c9d1d9` (cool graphite seeds); surface-alt `#161b22`, border `#30363d` |
| §3 accent | `style-guide.vars.yaml` Brand | single brand magenta `#ff2e88`; keep it off the semantic axis |
| §3 semantics | `style-guide.vars.yaml` Semantic | success `#3fb950`, warning `#d29922`, error `#f85149`, info `#58a6ff` (GitHub-dark set) |
| §3 modes | `style-guide.color-modes.yaml` | dark primary (canvas `#0e1116`, text `#c9d1d9`); light: canvas `#eef1f4`, text `#1c2128`, magenta `#c81e6e` |
| §4 | `style-guide.vars.yaml` Typography + `style-guide.typography.yaml` | font-mono `'JetBrains Mono', 'IBM Plex Mono', monospace` (data); font-sans `'Inter', -apple-system, sans-serif` (labels only); 1.2 scale |
| §5 | `style-guide.vars.yaml` Layout | unit 4px; tight-gutter/dense-pane rule; 1.35 line-height |
| §6 | `style-guide.vars.yaml` radius + `style-guide.css-snippets.yaml` | radius `1px` max; box-drawing pane rules; active-pane magenta border; overlay shadow only |
| §7 | `style-guide.css-snippets.yaml` / `style-guide.scoped-vars.yaml` | `--motion-micro: 140ms`, `--motion-meter: 200ms`; meter-fill keyframes + reduced-motion guard |
| §8 | `style-guide.css-snippets.yaml` + `style-guide.semantic-classes.yaml` | magenta primary key, k9s-style prompt input, titled box-drawn panes, keybind footer, selected-row bar |
| §9 | verification across all facets | recheck warning `#d29922` at text sizes; enforce glyph+color status; magenta focus ≥3:1 |
