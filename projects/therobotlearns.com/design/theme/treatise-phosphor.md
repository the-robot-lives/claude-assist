---
slug: phosphor
base_theme: theme-style-guide
status: full
revision: 2
---

# Theme Treatise — Phosphor

Theme: `theme-phosphor/` · Base: `theme-style-guide` · Status: full
(rev 2 — Stage C built `theme-phosphor/` and rendered all five slice screens; the renders
confirmed the monochrome-amber direction, so the treatise is promoted sketch → full unchanged.)

> **Surface note.** The Robot Learns has no web frontend — its "screens" are a Claude Code
> agent's output in a terminal. Phosphor is authored for that reality: Stage C renders it
> onto a **mocked terminal window**, not a web page. Where this treatise says "chrome,"
> "panel," or "card," read it as box-drawing regions inside a terminal, styled by the
> `@noizu/styleguide` CSS theme.

## 1. Identity

- **Intent:** A single-phosphor amber CRT terminal. One glowing hue on a warm near-black
  void, fixed-width type as the *primary UI face* — not a code accent. The product is a
  machine you talk to; Phosphor dresses that machine as a warm vintage instrument where
  meaning is carried by intensity, not color.
- **Perception:** Within five seconds: "I am at a warm amber terminal — one color, all
  business, slightly alive." Focus and machine-calm, never kitsch.
- **Audience:** CLI-native learners who live in a terminal and want the tool to feel like
  one — vim/emacs users, sysadmins, night-shift operators. They read monospace fluently.
- **Tone:** Terse, machine, monospaced. The UI reports; it does not chat or decorate.
- **Keywords:** amber, monochrome, phosphor, fixed-width, machine
- **New direction (not a restyle of an existing theme):** inherits `theme-style-guide`
  structure (layouts, section set, semantic class names) unchanged. The entire delta is
  chromatic (monochrome amber), typographic (mono-primary), and shape (radius 0, box-drawing
  chrome, zero elevation). No existing theme is monochrome or mono-primary — this fills the
  genuine-terminal gap none of the seven inherited web themes occupy.

## 2. References & Anchors

- **Anchor — amber monochrome monitors (DEC VT220 / IBM 3279 amber, P3 phosphor):** borrow
  the single warm-amber-on-dark discipline and the sense that brightness *is* the palette.
- **Anchor — `less`/`vim`/`mutt` in a one-color terminal:** borrow the information density
  and the convention that structure comes from box-drawing rules and reverse-video, not from
  boxes-with-shadows.
- **Anchor — analog instrument backlighting (amber gauge lamps):** borrow the "one glow
  source in a dark room" restraint — the whole surface is lit by a single amber.
- **Anti-reference — cool-retro-term's skeuomorphic CRT:** *no* scanlines, screen curvature,
  glow-bloom, or flicker as CSS filters. The warmth lives in the palette, not in a fake
  cathode-ray distortion. A phosphor screen that ships a `blur()` glow has missed the point.
- **Anti-reference — green-on-black "hacker" terminals:** amber, not `#00ff00` green. Green
  reads as intrusion/Matrix cliché; amber reads as warm, patient, industrial. No green
  anywhere except the semantic success step, and even that is pushed amber-ward.
- **Anti-reference — rainbow syntax highlighting:** Phosphor is monochrome by rule. Code and
  data differentiate by *weight and intensity*, never by assigning tokens their own hues.

## 3. Color Story

- **Temperature & register:** Warm and monochrome. A single amber hue band (38–45°) is the
  entire chromatic vocabulary; the surface is a warm near-black. Saturation is fixed; the
  design varies *lightness/intensity* to build hierarchy.
- **Hue relationships:** Monochrome-amber. There is no secondary brand hue. Where a second
  distinguishing value is needed, use a brighter or dimmer amber step, never a new hue.
  Amber accent seed: `#ffb000` (classic P3 amber; ±4° hue acceptable).
- **Neutral strategy:** There are effectively no neutrals — the "gray ramp" is an amber ramp.
  Re-seed the base theme's `black` to a warm near-black `#140c00` (≈40° hue, very low
  lightness) and its `white` to a bright amber `#ffb000`, so every derived step inherits the
  amber tint. Pure `#000`/`#fff`/any true gray never appear.
- **Semantic mapping:** Monochrome-first. Success, info, and the default state are amber
  *intensities* (info = dim amber `#c88a00`, success = bright amber `#ffd050`), each paired
  with a glyph so meaning never rests on brightness alone. Error is the **one sanctioned hue
  break** — a red-shifted phosphor `#ff5a3c` (≈12°), the only non-amber on any screen — so a
  failure is unmistakable in a monochrome field. Warning stays amber (`#ffb000`) but is
  always prefixed (`! `). Collision rule: nothing amber may sit adjacent to the error red at
  equal size without the `✗` glyph, or the break loses its force.
- **Contrast stance:** High and crisp everywhere; Phosphor is never soft. Primary amber
  `#ffb000` on canvas `#140c00` ≈ 11:1. Box-drawing rules may sit dim (amber at ~25% alpha)
  but text never drops below the 4.5:1 floor.
- **Mode strategy:** **Dark is the only true mode** — a monochrome CRT has no light variant.
  A "paper terminal" light fallback (amber `#a85f00` text on warm cream `#f4ead6`) exists as a
  faithful translation for forced light contexts but receives no independent design. No
  high-contrast mode: the dark palette already clears AA with margin, and monochrome leaves
  nothing to boost but intensity, which the dark mode already maximizes.

## 4. Typographic Voice

- **Families:** A single fixed-width family is the **primary UI face for everything** —
  headings, body, labels, data, chrome. Seed: `'IBM Plex Mono', 'Menlo', monospace`. This is
  the defining trait: there is **no proportional sans anywhere**. Rationale: the product *is*
  a terminal; proportional type would break the character grid that every other decision
  depends on.
- **Scale character:** Terminal-flat, ≈1.15 ratio. Headings distinguish by UPPERCASE +
  underline (box-drawing `─`) + intensity, not by dramatic size jumps; the largest heading is
  at most 1.6× body.
- **Weight usage:** 400 for body and data, 700 for headings and active items. Intensity
  (bright vs dim amber) carries more hierarchy than weight. Never bold whole paragraphs.
- **Rhythm:** Line-height 1.4 (dense terminal rows). Measure capped ≈80ch (the classic
  terminal column). Since the whole UI is mono, "where mono appears" is everywhere; the
  question inverts — a proportional face appears *nowhere*.

## 5. Space & Density

- **Spacing philosophy:** Character-grid. Horizontal rhythm is measured in `ch` (monospace
  cells), vertical in line-rows; the base unit is one cell. Padding is spent as blank
  cells/rows, keeping every column aligned to the grid.
- **Density target:** Reference screen is the session-log viewer (`04`): 30–40 log rows plus a
  status rule visible on an 80×43 terminal without paging. Denser than any web theme here —
  Phosphor packs rows the way `less` does.
- **Responsive stance:** Under width pressure, secondary columns drop and long lines soft-wrap
  at the measure; the character grid and row legibility are protected absolutely — never
  shrink the mono size to fit more columns.

## 6. Shape & Surface

- **Radius language:** `0px` everywhere, no exceptions. A CRT character cell is a rectangle;
  rounded corners would contradict the entire premise.
- **Borders:** Structure is box-drawing (`─ │ ┌ ┐ └ ┘ ├ ┤ ┼`) rendered as 1px amber rules at
  ~25–40% intensity. Titled regions embed the label in the top rule (`┤ SESSION LOG ├`).
  Solid filled borders are avoided; the rule *is* the border.
- **Elevation:** **Zero.** No shadows, ever — a terminal is flat. "Layers" are expressed by
  box-drawing enclosure and intensity (an active region's rule brightens to full amber). Even
  modal overlays are flat: a boxed region over a dimmed (40%) background, no drop shadow.
- **Texture & gradient policy:** No gradients, no noise, no halftone. Explicitly **no**
  scanline/glow filters (see §2). The single permitted "texture" is the block cursor and
  reverse-video fills. Everything else is flat amber-on-dark.

## 7. Motion & Feedback

- **Animation character:** A terminal repaints; it does not animate. Motion is near-absent by
  design — the one living element is the cursor.
- **Duration & easing:** State changes are **instant** (0ms) — no transitions, no easing. The
  sole animation is a block-cursor blink: a 1000ms step (square-wave) opacity toggle, no fade.
- **Interaction states:** Hover intensifies amber one step (dim→full) or reverse-videos the
  row; active/selected is a full reverse-video block; focus is a solid amber block cursor or a
  1px full-amber box; disabled drops to ~40% amber and removes any interactive rule. Because
  there is only one hue, **state never depends on color** — it uses intensity, reverse-video,
  and glyph prefixes.

## 8. Component Inflections

- **Buttons:** Bracketed mono labels — `[ RUN ]`, `[ CANCEL ]`. Primary/focused button is
  reverse-video (amber fill, near-black text `#140c00`); others are dim-amber bracket text on
  the void. No fills except reverse-video, no radius.
- **Inputs:** A prompt line — a `> ` or `▓` block-cursor prefix, an amber underline rule for
  the field extent, text typed in full amber. Focus swaps the underline for a live block
  cursor. Placeholder at the 4.5:1 floor (`#c88a00`), never dimmer.
- **Cards:** Box-drawn regions with the title in the top rule and a `key : value` body. No
  background fill (the void shows through); an active card brightens its rule to full amber.
- **Navigation:** A left or top column of mono entries; the active entry is reverse-video; a
  persistent bottom status rule shows keybind hints (`^Q quit  ^R reload`) like a real TUI.
- **At base defaults (deliberately untouched):** tables render as ASCII/box-drawing grids;
  toasts and breadcrumbs inherit `theme-style-guide` behavior with amber tokens applied.

## 9. Accessibility Commitments

- **WCAG target:** 2.2 AA across the (single) dark mode; body amber targets AAA (7:1) since
  long terminal sessions are the use context.
- **Contrast minimums:** Primary `#ffb000` on `#140c00` ≈ 11:1 (pass with margin). Near-the-
  line pairs the fine-tuner must verify: secondary amber `#c88a00` on canvas ≈ 6:1 (safe for
  body); **muted amber `#8a5e00` ≈ 3:1 — decorative/large-UI only, never body text**; error
  red `#ff5a3c` on canvas ≈ 5.5:1 (safe). Recheck all if the canvas lightens.
- **Focus visibility:** A solid full-amber block cursor or 1px amber box on every focusable
  element; against the near-black void it exceeds 7:1. Focus is never removed, only restyled.
- **Monochrome guarantee:** Because the palette is one hue, meaning is **never** encoded by
  color alone anywhere — status uses glyph prefixes (`✓ ! ✗ i`), intensity steps, and
  reverse-video. The single error-red break is *additionally* the brightest-shifted value so
  it survives grayscale.
- **Reduced motion:** `prefers-reduced-motion` freezes the cursor to a static block; nothing
  else moves, so nothing else needs disabling.

## 10. Facet Mapping Appendix

| Treatise section | Engine facet | Seed hints |
|---|---|---|
| §1 | `branding.yaml` | name "Phosphor"; intent/perception/audience/tone verbatim; keywords: amber, monochrome, phosphor, fixed-width, machine |
| §3 neutrals | `style-guide.vars.yaml` Surfaces | black: `#140c00`, white: `#ffb000` (warm seeds — the ramp becomes an amber ramp) |
| §3 accent | `style-guide.vars.yaml` Brand | single brand amber `#ffb000`; do NOT populate a second brand hue |
| §3 semantics | `style-guide.vars.yaml` Semantic | success `#ffd050`, warning `#ffb000`, error `#ff5a3c` (the one hue break), info `#c88a00` |
| §3 modes | `style-guide.color-modes.yaml` | dark primary (canvas `#140c00`, text `#ffb000`); light fallback: cream `#f4ead6`, amber text `#a85f00` |
| §4 | `style-guide.vars.yaml` Typography + `style-guide.typography.yaml` | font-sans AND font-mono both `'IBM Plex Mono', 'Menlo', monospace`; no proportional face |
| §5 | `style-guide.vars.yaml` Layout | document the character-grid (`ch`/row) rule; dense 1.4 line-height |
| §6 | `style-guide.vars.yaml` radius + `style-guide.css-snippets.yaml` | radius `0`; box-drawing rules; zero shadows (no elevation snippets) |
| §7 | `style-guide.css-snippets.yaml` / `style-guide.scoped-vars.yaml` | `--motion: 0ms`; cursor-blink keyframes 1000ms step + reduced-motion guard |
| §8 | `style-guide.css-snippets.yaml` + `style-guide.semantic-classes.yaml` | bracketed buttons, prompt inputs, box-drawn cards, reverse-video active states |
| §9 | verification across all facets | recheck `#c88a00`/`#8a5e00` steps and `#ff5a3c` on any canvas change; enforce glyph-not-hue status |
