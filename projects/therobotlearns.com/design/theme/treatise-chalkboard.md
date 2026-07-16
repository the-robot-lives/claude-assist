---
slug: chalkboard
base_theme: theme-style-guide
status: sketch
revision: 1
---

# Theme Treatise — Chalkboard

Theme: `theme-chalkboard/` · Base: `theme-style-guide` · Status: sketch

> **Reverse-engineered** from the shipped `theme-chalkboard/` YAML (Stage A). The treatise
> justifies the on-disk values and flags anything arbitrary. **Surface note:** the product is
> a terminal agent; Stage C renders Chalkboard onto a mocked terminal — its dark-green board
> and colored-chalk accents translate to a warm always-dark terminal skin (a slate the tutor
> writes on), styled by the `@noizu/styleguide` CSS theme.

## 1. Identity

- **Intent:** Capture the magic of a brilliant lecture — the chalkboard after a great teacher
  finishes: diagrams, arrows connecting ideas, margin notes, the "aha" drawn in colored chalk.
- **Perception:** "Warm, academic, personal — the front row of the best class you ever took,
  where the professor draws everything out and it clicks."
- **Audience:** Students, academics, and anyone nostalgic for great classroom teaching —
  people who learn from explanation and demonstration.
- **Tone:** Professorial but warm; think-aloud ("now watch what happens when we…"); underlines
  for emphasis, arrows connecting ideas.
- **Keywords:** chalk, lecture, diagram, underline, explain, blackboard
- **Relationship to base:** inherits `theme-style-guide` structure but overrides heavily (it
  ships `typography.yaml`, `css-snippets`, `globals`). The delta is a full-immersion dark-green
  board surface, chalk-white "ink," hand-printed display type, radius 0, and a 13-color chalk
  palette. Sibling to `workbench` (both hand-drawn teaching themes); Chalkboard is the **dark
  slate board with chalk media**, where workbench is cream paper with pen-and-tape.

## 2. References & Anchors

- **Anchor — an actual green slate chalkboard mid-lecture:** borrow the forest-green surface,
  the dusty desaturated chalk colors, and the convention that emphasis is an underline or a
  drawn arrow, not a bold weight.
- **Anchor — Khan Academy's handwritten explanations:** borrow the "draw it out as you
  explain" pacing and the colored-chalk highlighting of key terms.
- **Anchor — a professor's diagram with margin doodles:** borrow the informal, hand-printed
  labels and the willingness to annotate.
- **Anti-reference — a sterile dry-erase whiteboard:** chalk is warm, dusty, and slightly
  imperfect; nothing here should read as glossy marker on clinical white.
- **Anti-reference — neon "smart board" / digital classroom UIs:** the chalk colors are
  *desaturated* (`#e06060`, not `#ff0000`); saturated neon would break the nostalgic warmth.
- **Anti-reference — `workbench`'s cream paper:** Chalkboard is a dark board, not light paper —
  its "ink" is light chalk on a dark surface, the inverse of its sibling.

## 3. Color Story

- **Temperature & register:** Warm chalk on a cool-dark green board — a deliberate warm/cool
  tension. Chalk colors are all desaturated (dusty), never pure.
- **Hue relationships:** A green board neutral + three primary "chalks" (red `#e06060`, blue
  `#6cb4dc`, yellow `#e8d44c`) expanded into a 13-hue chalk palette, each with a `color-mix`
  light variant blended toward the surface. No single dominant accent — colored chalk is used
  categorically, like a teacher reaching for a different stick.
- **Neutral strategy:** The greens *are* the neutral. Board surface `#2d4a2d` (forest) and
  `#1e2a1e` (near-black green); "ink" is warm chalk `#e8e4d8`. Every neutral is green- or
  chalk-tinted; pure gray never appears.
- **Semantic mapping:** Semantics map onto the chalk palette — success green-chalk `#50b878`,
  warning yellow-chalk `#d8b840`, error red-chalk `#e06060`, info blue-chalk `#6cb4dc`. All
  share the same dusty desaturation so they read as one chalk set. Collision rule: because red
  chalk *is* both a brand primary and the error color, error must be reinforced with an
  underline/icon so "error" isn't confused with an ordinary red-chalk highlight.
- **Contrast stance:** High for chalk-on-board; chalk `#e8e4d8` on board `#2d4a2d` ≈ 8:1.
  Colored chalks are lighter and must be verified at text size (see §9).
- **Mode strategy — honest flag:** the theme defines `light` and `dark` blocks, but **both are
  dark-toned** — `light` = forest green `#2d4a2d`, `dark` = near-black green `#1e2a1e`. The
  labels do **not** map to conventional light/dark luminance; this is an *always-dark*
  chalkboard offering a "board green" vs "darker board" pair, not a true light theme. There is
  no genuine light mode and no high-contrast mode; a fine-tuner should treat both blocks as
  dark variants and not expect a pale surface.

## 4. Typographic Voice

- **Families:** Body/UI is Patrick Hand (a hand-printed casual face — chalk handwriting);
  display/headings/board-labels is Architects Daughter (a looser hand-drawn face — the drawn
  title); code/equations is Roboto Mono. Rationale: the whole board is "written by hand," so
  even body copy is a handwriting face — a rare choice that commits fully to the metaphor.
- **Scale character:** Generous and readable — `font-size-base` is **18px** (larger than a
  typical UI) with line-height **1.65**, because handwriting faces need size and air to stay
  legible. Display uses Architects Daughter at the large end.
- **Weight usage:** Effectively single-weight (400) across faces — hand lettering doesn't
  bold; emphasis comes from underline, color chalk, and size, per the tone.
- **Rhythm:** 1.65 body line-height (roomy); mono for equations, code, and technical values
  only. **Honest flag:** `font-url` imports *Roboto Slab* (400–700) but no font var references
  it — a dead/unused import; recommend removing it or wiring it to a purpose.

## 5. Space & Density

- **Spacing philosophy:** Roomy — chalk needs space; the 18px/1.65 rhythm sets a low-density
  baseline. Regions are separated by dashed chalk rules (`card-separator-style: dashed`,
  `rgba(232,228,216,0.3)`), like sections drawn on a board.
- **Density target:** Reference screen is the knowledge-article viewer as a "board": one
  diagram-plus-explanation region per view, generously spaced — a lecture panel, not a data
  table.
- **Responsive stance:** Under width pressure, chalk regions stack vertically; the 18px body
  size and line-height are protected (shrinking handwriting type destroys legibility first).

## 6. Shape & Surface

- **Radius language:** `0px` — a slate board is flat and rectangular; rounded corners would
  contradict the board metaphor.
- **Borders:** Dashed chalk rules separate regions (the `card-separator` dashed style); solid
  hard borders are avoided in favor of drawn/dashed chalk lines.
- **Elevation:** Flat — a board has no depth. "Cards" are chalk-outlined regions on the same
  board plane; shadows (`rgba(0,0,0,0.2–0.35)`) are used sparingly, only where an overlay must
  lift off the board.
- **Texture & gradient policy:** **Texture is sanctioned here** (unlike most themes) — chalk
  dust, faint eraser smudges, and drawn arrows are on-brand and live in `css-snippets`/
  `globals`. Constraint: texture must never drop text contrast below the §9 floors; a smudge is
  decoration, not a scrim over content.

## 7. Motion & Feedback

- **Animation character:** Didactic — motion imitates drawing/writing on a board (a "chalk-on"
  reveal for headings or diagram strokes), matching the think-aloud tone. Used sparingly.
- **Duration & easing:** Reveal/write-on 200–400ms ease-out (slower than a tool theme, because
  "drawing" reads as deliberate); micro-feedback ~120ms. Nothing frantic.
- **Interaction states:** Hover brightens the chalk/underlines the item; active presses;
  focus is a chalk-outline ring; disabled fades to a smudged ~40%. Emphasis and state lean on
  underline + chalk brightness, not on a hue swap alone.

## 8. Component Inflections

- **Buttons:** Chalk-outlined labels on the board (drawn box), filling to a solid chalk color
  on primary/active; hand-printed text. No radius.
- **Inputs:** A chalk underline (drawn line) for the field, with the label written above;
  focus brightens/thickens the underline. Placeholder in muted chalk at the contrast floor.
- **Cards:** Dashed-outline board regions with a hand-drawn title; separated by dashed chalk
  rules rather than boxes-with-shadows.
- **Navigation:** Written board labels; the active item is underlined in a bright chalk color +
  slightly larger, like the current topic circled on the board.
- **At base defaults (deliberately untouched):** toasts, breadcrumbs, and modal structure
  inherit `theme-style-guide`, recolored through the chalk tokens.

## 9. Accessibility Commitments

- **WCAG target:** 2.2 AA on the (always-dark) board surface.
- **Contrast minimums:** Chalk `#e8e4d8` on board `#2d4a2d` ≈ 8:1 (pass). Near-the-line pairs
  the fine-tuner must verify at text size: **text-secondary `#c8c0a8` ≈ 5:1 (ok), text-muted
  `#90886c` ≈ 2.7:1 — decorative/large only, never body;** colored chalks (blue `#6cb4dc`,
  yellow `#e8d44c`, green `#50b878`) as text on `#2d4a2d` land ~4–6:1 — keep at label size or
  larger and verify each, since desaturated chalk hues sit close to the line.
- **Focus visibility:** A bright-chalk outline ring on every focusable element; against the
  green board it exceeds 3:1. Never removed.
- **Non-color emphasis:** Because red chalk is both brand and error, and hues are close in
  value, meaning is reinforced with underline/icon — never chalk color alone.
- **Reduced motion:** `prefers-reduced-motion` disables the chalk write-on/draw animations;
  content appears statically, no strokes.

## 10. Facet Mapping Appendix

| Treatise section | Engine facet | Seed hints |
|---|---|---|
| §1 | `branding.yaml` | name "The Robot Learns — Chalkboard"; intent/perception/audience/tone verbatim; keywords: chalk, lecture, diagram, underline, explain, blackboard |
| §3 neutrals | `style-guide.vars.yaml` Surfaces | white `#e8e4d8` (chalk), black `#1e2a1e` (board); board-green surfaces |
| §3 palette | `style-guide.vars.yaml` / `color-palette.yaml` | 13 desaturated chalk hues + `color-mix` light variants; brand red/blue/yellow `#e06060`/`#6cb4dc`/`#e8d44c` |
| §3 semantics | `style-guide.vars.yaml` Semantic | success `#50b878`, warning `#d8b840`, error `#e06060`, info `#6cb4dc` |
| §3 modes | `style-guide.color-modes.yaml` | BOTH blocks dark: light `#2d4a2d`/text `#e8e4d8`, dark `#1e2a1e`/text `#d8d0bc` — no true light mode |
| §4 | `style-guide.typography.yaml` + `vars.yaml` | font-sans Patrick Hand, font-display Architects Daughter, font-mono Roboto Mono; base 18px/1.65; **drop dead Roboto Slab import** |
| §5 | `style-guide.vars.yaml` Layout | roomy 18px/1.65 rhythm; dashed chalk separators |
| §6 | `style-guide.vars.yaml` radius + `css-snippets.yaml` | radius `0`; dashed separators; flat (no elevation); sanctioned chalk-dust texture |
| §7 | `style-guide.css-snippets.yaml` | write-on/draw keyframes 200–400ms; reduced-motion guard |
| §8 | `style-guide.semantic-classes.yaml` | chalk-outline buttons, underline inputs, dashed-region cards, underlined active nav |
| §9 | verification across facets | verify colored-chalk-on-board and `#90886c`/`#c8c0a8` steps; enforce underline+icon on error |
