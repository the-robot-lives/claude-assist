---
slug: comic
base_theme: theme-style-guide
status: sketch
revision: 1
---

# Theme Treatise — Comic

Theme: `theme-comic/` · Base: `theme-style-guide` · Status: sketch

> **Reverse-engineered** from the shipped `theme-comic/` YAML (Stage A). **Render-deferral
> note:** Comic is a graphic-novel-panel aesthetic — heavily illustrative and the least
> terminal-natural direction here. In a terminal-first product it is treatise-only for this
> render pass (`status: deferred` in `stage_c.themes`); the intent below is captured in full.

## 1. Identity

- **Intent:** Make every page a visual conversation — speech bubbles explain concepts,
  characters react, callout boxes grab attention. Learning should feel like reading your
  favorite graphic novel.
- **Perception:** "Energetic, visual, alive — every screen has personality; panels break the
  grid, sound effects punctuate big ideas."
- **Audience:** Visual learners and younger audiences; people who learn better from HeadFirst
  than from O'Reilly.
- **Tone:** Conversational, punchy, dramatic — speech bubbles, breaking the fourth wall,
  concepts-as-characters. POW!
- **Keywords:** visual, panels, speech, POW, characters, action
- **Relationship to base:** inherits `theme-style-guide` and ships the heavy tier
  (`typography.yaml`, `css-snippets`, `globals`). The delta is a loud high-saturation ink-
  outline comic system: radius 0, thick black borders, a comic-lettering display face, and
  uppercase. The polar opposite of `atlas` (loud vs contemplative) and the loudest theme here.

## 2. References & Anchors

- **Anchor — the "Head First" book series (named in `branding.yaml`):** borrow the visual-
  conversation pedagogy — speech bubbles, callouts, characters explaining code.
- **Anchor — classic comics / graphic novels:** borrow thick black ink outlines, halftone/
  Ben-Day dot shading, hard-offset panel shadows, and onomatopoeia lettering (POW/BAM).
- **Anchor — bold flat-vector comic UI:** borrow the primary-triad palette (red/blue/yellow)
  used at full saturation with black outlines.
- **Anti-reference — muted, sophisticated editorial (`atlas`):** Comic is the inverse — loud,
  saturated, ink-outlined; restraint would kill it.
- **Anti-reference — calm dark tool themes (`deep-focus`):** nothing here is quiet; energy is
  the product.
- **Anti-reference — subtle gradient/soft-shadow UI:** Comic uses *hard* offset shadows and
  flat fills; a soft blurred shadow reads as the wrong genre entirely.

## 3. Color Story

- **Temperature & register:** Vibrant, high-saturation, light-primary — a bright cream page
  (`#fffef5`) as the panel paper, primaries at full strength.
- **Hue relationships:** A comic primary triad — red `#ff3366`, blue `#3366ff`, yellow
  `#ffcc00` — expanded to a 13-hue high-saturation palette. Black ink `#1a1a1a` is structural
  (outlines/borders), not a neutral to be tinted. No single dominant accent; color is bold and
  categorical.
- **Neutral strategy:** Neutrals are nearly absent — the system is bold flats plus black
  outlines. The "gray" is really black line + cream paper; secondary text `#444444`, muted
  `#888888`.
- **Semantic mapping:** Saturated set — success `#00cc66`, warning `#ffaa00`, error `#ff3366`,
  info `#3366ff`. Collision rule: error `#ff3366` **is** the brand red, so an error must be
  reinforced with an icon/label (a "!" burst), or it reads as ordinary comic red.
- **Contrast stance:** Maximal — thick black outlines everywhere, saturated fills on cream.
  Comic has no soft register. *Caution:* saturated fills like yellow `#ffcc00` are low-contrast
  as text (see §9) and must carry black text on top.
- **Mode strategy:** **Light is primary** (bright cream panels). A dark mode exists as a
  faithful translation — canvas `#1a1a1a`, text `#f5f5f0`, outlines invert to white
  (`border #f5f5f0`), primaries unchanged. No high-contrast mode: contrast is already maximal.

## 4. Typographic Voice

- **Families:** Display is Bangers (`'Bangers', 'Impact', sans-serif`) — comic lettering for
  titles, callouts, and sound effects, always UPPERCASE with wide tracking and tight
  line-height (0.95). Body is Nunito (rounded, friendly, speech-bubble text); code is Fira Code.
  The Bangers/Nunito split is the theme's voice: shouted headings, warm readable body.
- **Scale character:** Dramatic display jumps — Bangers titles are large and loud against
  Nunito body; H1/H2 are uppercase Bangers at big sizes.
- **Weight usage:** Nunito 400–800; buttons are heavy (`btn-font-weight: 800`) and uppercase
  with letter-spacing — the UI shouts a little. Bangers is single-weight display.
- **Rhythm:** Body line-height ≈1.7 (Nunito reads roomy); display line-height ≈0.95–1.05
  (stacked comic titles). Mono for code/terminal output only.

## 5. Space & Density

- **Spacing philosophy:** Panel-based — content sits in bounded panels and speech bubbles with
  bold gutters; energetic, not cramped.
- **Density target:** Reference screen is a lesson page as comic panels: 3–5 panels/bubbles per
  view, each a discrete beat — moderate density, high visual punch.
- **Responsive stance:** Under width pressure, panels stack vertically (like a webtoon scroll);
  outline thickness and title legibility are protected.

## 6. Shape & Surface

- **Radius language:** `0px` — comic panels are sharp rectangles; rounding contradicts the
  panel metaphor (speech bubbles get their shape from `css-snippets`, not border-radius).
- **Borders:** Thick **black ink outlines** (`#1a1a1a`/`#000`) are the defining structural
  element — every panel, button, and card is outlined. `border-accent #ff3366` for emphasis.
- **Elevation:** **Hard-offset shadows** (solid black, no blur) — the comic "pop" — never soft
  blurred shadows. Depth is a crisp offset, like a sticker lifted off the page.
- **Texture & gradient policy:** **Halftone / Ben-Day dots are sanctioned** (per `meta.yaml`)
  for shading and backgrounds, in `css-snippets`. No soft gradients — flat fills plus halftone.

## 7. Motion & Feedback

- **Animation character:** Punchy and action-driven — pop-in, shake, a "POW" burst on key
  actions. This is the one theme where expressive motion is on-brand.
- **Duration & easing:** Snappy with permitted overshoot/bounce — 150–300ms with spring easing
  on emphasis; micro-feedback ~100ms. Big moments may pop harder, but nothing loops endlessly.
- **Interaction states:** Hover lifts/enlarges slightly and may thicken the outline; active
  "presses" the hard shadow flat; focus is a bold outline/burst; disabled goes flat gray. State
  pairs motion + outline weight, not color alone.

## 8. Component Inflections

- **Buttons:** Thick black-outlined, saturated fill, uppercase Nunito 800 with letter-spacing,
  a hard-offset shadow that flattens on press — the loudest button in the project.
- **Inputs:** Black-outlined fields on cream, 0 radius; focus thickens the outline / adds an
  accent burst. Labels may be uppercase.
- **Cards → panels/bubbles:** The workhorse surface — a thick-outlined panel or a speech bubble
  (shaped via snippet) with a hard shadow; titles in Bangers.
- **Navigation:** Bold outlined tabs; the active tab is a filled saturated color with black
  outline + heavier shadow, like the selected panel.
- **At base defaults (deliberately untouched):** toasts and breadcrumbs inherit
  `theme-style-guide` recolored; the character/sound-effect flourishes live in `css-snippets`.

## 9. Accessibility Commitments

- **WCAG target:** 2.2 AA; high-contrast outlines make most pairings easy, but saturated fills
  need care.
- **Contrast minimums:** Ink `#1a1a1a` on cream `#fffef5` ≈ 18:1. **Hard flags: yellow
  `#ffcc00` and warning `#ffaa00` as text on cream are well below 4.5:1 — use black text on
  yellow fills, never yellow text; error/brand red `#ff3366` on cream ≈ 3.3:1 — use at large/
  UI size or as a fill with light text, not as body text.** Verify every saturated fill's text
  as black-on-fill.
- **Focus visibility:** A bold outline + accent burst on every focusable element; the thick
  black outline already exceeds 3:1 on all surfaces. Never removed.
- **Non-color guarantee:** Because error red is the brand red and hues are loud, status is
  reinforced with icons/bursts and labels — never hue alone.
- **Reduced motion:** `prefers-reduced-motion` disables pop/shake/POW animations; panels and
  states appear instantly (the visual punch survives in the outlines and color, not motion).

## 10. Facet Mapping Appendix

| Treatise section | Engine facet | Seed hints |
|---|---|---|
| §1 | `branding.yaml` | name "The Robot Learns — Comic"; intent/perception/audience/tone verbatim; keywords: visual, panels, speech, POW, characters, action |
| §3 neutrals | `style-guide.vars.yaml` Surfaces | white `#fffef5` (panel paper), black `#1a1a1a` (ink outline); border = black |
| §3 palette | `style-guide.vars.yaml` / `color-palette.yaml` | primary triad `#ff3366`/`#3366ff`/`#ffcc00`; 13-hue high-saturation set |
| §3 semantics | `style-guide.vars.yaml` Semantic | success `#00cc66`, warning `#ffaa00`, error `#ff3366`, info `#3366ff` |
| §3 modes | `style-guide.color-modes.yaml` | light primary (cream `#fffef5`, ink `#1a1a1a`); dark: canvas `#1a1a1a`, text `#f5f5f0`, white outlines |
| §4 | `style-guide.typography.yaml` + `vars.yaml` | font-display Bangers (uppercase, LH 0.95), font-sans Nunito, font-mono Fira Code; btn 800/uppercase |
| §5 | `style-guide.vars.yaml` Layout | panel-based; 3–5 panels/view; bold gutters |
| §6 | `style-guide.vars.yaml` radius + `css-snippets.yaml` | radius `0`; thick black outlines; HARD offset shadows; sanctioned halftone |
| §7 | `style-guide.css-snippets.yaml` | pop/shake/POW keyframes 150–300ms spring; reduced-motion guard |
| §8 | `style-guide.semantic-classes.yaml` | outlined uppercase-800 buttons, outlined inputs, panel/bubble cards, filled active tabs |
| §9 | verification across facets | black-on-fill for yellow/red; error carries icon; muted `#888888` decorative |
