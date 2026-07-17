---
slug: versus
base_theme: theme-style-guide
status: sketch
revision: 1
---

# Theme Treatise — Versus

Theme: `theme-versus/` · Base: `theme-style-guide` · Status: sketch

## 1. Identity

- **Intent:** A brutalist esports-broadcast skin — stark black type on white, hard rules, a
  scoreboard's uncompromising clarity, and exactly one hot signal color. This is competition as
  *broadcast graphics*: rankings, brackets, and match cards that read from across a room. Where
  every other theme adds atmosphere, Versus strips it away.
- **Perception:** Within five seconds: "this is serious competition, and the numbers don't lie."
  Bold, confrontational, absolutely legible.
- **Audience:** The Competitive Grinder (P-005) and Streamer (P-009) — ladder and tournament
  players who want rank and result to hit hard and broadcast clean; the Moderator (P-011) whose
  no-nonsense ops queues suit its clarity.
- **Tone:** Blunt, declarative, all-caps where it counts. Copy is a scoreboard, not a sentence.
- **Keywords:** brutalist, scoreboard, stark, confrontational, decisive
- **Variant note:** Inherits `theme-style-guide` structure unchanged. Deltas: achromatic
  black/white/concrete palette, one blood-orange signal, hard 0px shapes, heavy grotesque type.
  No structural overrides.

## 2. References & Anchors

- **Anchor — esports broadcast overlays (VALORANT / CS majors scoreboards):** borrow the hard-
  edged rank blocks, the giant numerals, and the black/white/one-accent discipline.
- **Anchor — Swiss/brutalist poster design & Helvetica-grid systems:** borrow the 12-column
  black rule grid, oversized type as graphic, and the refusal of decoration.
- **Anchor — printed tournament brackets / sports almanacs:** borrow the tabular, ink-on-paper
  authority of a bracket sheet.
- **Anti-reference — glassy glowing game UIs (`neural-neon`, `biolume`):** zero glow, zero glass,
  zero gradient, zero rounded softness. If a surface shines, it is off-theme.
- **Anti-reference — clinical light instrument (`signal`):** both are light, but Versus is
  **loud** — thick 2–3px black rules, huge heavy grotesque, one shouting accent — not thin
  hairlines and quiet teal. The split is weight and volume.
- **Anti-reference — warm friendly toy (`sandbox`):** no candy, no bounce, no pills; Versus is
  cold, hard, and adult-competitive.

## 3. Color Story

- **Temperature & register:** Achromatic and maximal-contrast — the **only** theme with truly
  neutral (0%-saturation) grays — plus exactly one hyper-saturated hot signal. Register: loud
  through contrast and scale, not through hue count.
- **Hue relationships:** Black + white + concrete gray, and one blood-orange signal `#FF3D00`
  (~14°) that owns 100% of the chromatic budget. A second accent is forbidden; where a "second
  color" is wanted, use black-on-signal or an inverted block instead.
- **Neutral strategy:** Pure neutral grays, no tint. Canvas `#FFFFFF`, panel `#F4F4F5`, concrete
  `#E4E4E7`, ink `#000000`. This purity is a deliberate identity marker versus every other
  theme's tinted neutrals.
- **Semantic mapping:** Minimal and label-driven — win/positive a hard green `#00C853` used
  sparingly, loss/error the signal `#FF3D00`, warning black-on-`#FFD600`. Every semantic state
  carries a **text label**, never color alone (this is the most colorblind-safe theme by design,
  P-008/US-071). Collision rule: signal-orange is loss *and* the brand accent — disambiguate by
  always pairing a word ("DEFEAT", "LIVE").
- **Contrast stance:** Maximum everywhere. Black on white = 21:1; concrete rules on white ≥ 3:1
  (structure is meant to be seen). The theme is never allowed to be subtle.
- **Mode strategy:** **Light is primary** (the broadcast scoreboard / bracket sheet). A dark mode
  exists as a hard inversion (canvas `#000000`, ink `#FFFFFF`, same `#FF3D00`) — a faithful
  negative, not a redesign. No separate high-contrast mode is needed because the base *is* max
  contrast; the only a11y care is that the signal never carries text-size meaning alone.

## 4. Typographic Voice

- **Families:** Heavy grotesque display — Archivo Black or Anton-weight (fallback `'Helvetica
  Neue', Arial, sans-serif`) — uppercase, tight, oversized, used as a graphic element (fighter
  names, ranks, "VS", scores). Body/UI is a neutral grotesque (Inter / Helvetica). Mono (IBM
  Plex Mono) for stat tables, timers, and bracket seeds — tabular figures mandatory.
- **Scale character:** Extreme — display can hit ~4× body (a rank number can fill a third of the
  card). The violent size gap between giant grotesque and small mono *is* the aesthetic.
- **Weight usage:** 400 body, 500 labels, 700 table emphasis, 900 grotesque display. Nothing in
  between softens the jump.
- **Rhythm:** Body line-height 1.4 (tight, tabular); measure ≤ 64ch. Mono for all numerics.
  Uppercase tracking +2% on the display face only.

## 5. Space & Density

- **Spacing philosophy:** 8px base on a strict grid; medium density with hard alignment — every
  edge snaps to the 12-column rule grid. Padding is even (16px) and unfussy; the drama is type
  scale and rules, not whitespace generosity.
- **Density target:** Reference screen is the Ranked Arena leaderboard / tournament bracket — a
  dense list of ranked rows or a full bracket, each row a hard-ruled block with giant rank
  numeral, readable at a glance on a 390×844 phone and legible when cast to a stream.
- **Responsive stance:** Under width pressure, table columns drop right-to-left (least-important
  first) but the rank numeral, fighter name, and result block never compress or wrap; the grid
  holds.

## 6. Shape & Surface

- **Radius language:** **Hard 0px** — sharp rectangles everywhere. This is the only theme with no
  rounding at all; a rounded corner is off-theme. No pills, no soft chips.
- **Borders:** Thick black rules — 2–3px `#000000` structural borders and dividers define every
  block; the rule grid is the entire surface system.
- **Elevation:** None — perfectly flat. No shadows, no tonal float. Hierarchy is rule weight,
  fill inversion (black block vs white block), and type scale only.
- **Texture & gradient policy:** Forbidden outright — no gradient, no glow, no shadow, no texture,
  no scanline. The single permitted "effect" is a solid signal-orange or solid-black fill block
  used as emphasis. Absolute flatness is the identity.

## 7. Motion & Feedback

- **Animation character:** Hard-cut and instrumental — motion snaps; nothing eases softly. Motion
  exists to register a state change with authority (a result *slams* in).
- **Duration & easing:** Micro 60–120ms; result/VS reveal a hard 120ms cut or a 1-step wipe;
  numbers count up 300ms linear. No easing curves softer than `ease-out`; no spring, no bounce,
  no parallax, ever.
- **Interaction states:** Hover inverts the block (white→black or adds the signal fill); active
  is a hard 1-step press (instant invert); focus is a 3px solid black (or signal on black) outline
  offset 2px; disabled is 40% gray with a diagonal-line hatch (pattern, not just opacity, so it
  reads without color). State changes use inversion + label, never hue alone.

## 8. Component Inflections

- **Buttons:** Hard rectangular blocks — primary is a solid black fill with white uppercase label
  (or signal-orange fill with black label for the single hottest CTA); secondary is a 2px black-
  outline ghost. No radius, no shadow. Inversion on hover.
- **Inputs:** Square 0px fields with a 2px black border, mono value text, a hard black focus
  outline. Labels are uppercase above the field.
- **Cards:** Hard-ruled blocks — 2px black border, 0px radius, 16px padding; the match/rank card
  pairs a giant grotesque numeral with a mono stat strip. Emphasis cards invert to solid black.
- **Navigation:** A top or bottom bar of hard-ruled tabs; the active tab is a solid black (or
  signal) block with inverted label — full inversion, not a tint or underline.
- **At base defaults (deliberately untouched):** tooltips and toast *structure* inherit
  `theme-style-guide`, restyled to hard 0px black-rule blocks via tokens.

## 9. Accessibility Commitments

- **WCAG target:** 2.2 AA, trivially exceeded on text (21:1 black/white); effectively AAA for all
  body and headings. The most inherently accessible theme for contrast; the design risk is
  entirely the single accent.
- **Contrast minimums:** Body far exceeds 4.5:1. The one guarded pair: **signal-orange `#FF3D00`
  on white ≈ 3.7:1** — usable for large text, UI blocks, and fills, but **never body text**, and
  it must always be paired with a label since it is the sole hue (colorblind users rely on the
  word, not the orange). Hard green `#00C853` on white ≈ 2:1 — allowed only as a *fill behind
  black text* or a labeled block, never as text on white.
- **Focus visibility:** 3px solid outline (black on light, signal-on-black on inverted blocks),
  2px offset — impossible to miss by design. Touch targets ≥ 48px on the hard grid.
- **Reduced motion:** `prefers-reduced-motion` removes the count-up and any wipe; results appear
  instantly (the theme barely animates, so it degrades to zero motion with no loss of meaning).

## 10. Facet Mapping Appendix

| Treatise section | Engine facet | Seed hints |
|---|---|---|
| §1 | `branding.yaml` | name "Versus"; intent/perception/audience/tone verbatim; keywords: brutalist, scoreboard, stark, confrontational, decisive; font-url: Archivo Black + Inter + IBM Plex Mono |
| §3 neutrals | `style-guide.vars.yaml` Surfaces | white `#FFFFFF`, black `#000000`, panel `#F4F4F5`, concrete `#E4E4E7` — pure, untinted |
| §3 accent | `style-guide.vars.yaml` Brand | single signal `#FF3D00`; forbid a second brand hue |
| §3 semantics | `style-guide.vars.yaml` Semantic | success `#00C853` (fill-only), error/loss `#FF3D00`, warning `#FFD600` (black text), info black/white block |
| §3 modes | `style-guide.color-modes.yaml` | light primary; dark = hard inversion (canvas `#000`, ink `#FFF`, signal unchanged); no separate high-contrast needed |
| §3 narrative | `style-guide.color-palette.yaml` | groups: Pure Neutrals, Signal Orange; usage rule "one hue, always labeled" |
| §4 | `style-guide.vars.yaml` Typography + `style-guide.typography.yaml` | font-display `'Archivo Black','Helvetica Neue',sans-serif`; font-sans Inter; font-mono IBM Plex Mono tabular; extreme display jump |
| §5 | `style-guide.vars.yaml` Layout + `style-guide.spacing.yaml` | unit 8px; 12-col hard rule grid; even 16px padding; protect rank numeral + name |
| §6 | `style-guide.vars.yaml` radius + `style-guide.css-snippets.yaml` | radius `0`; 2–3px black rule border system; flat (no shadow/gradient/glow); disabled hatch pattern snippet |
| §7 | `style-guide.css-snippets.yaml` / `style-guide.scoped-vars.yaml` | `--motion-micro:100ms`, `--motion-count:300ms linear`; no spring; reduced-motion → instant |
| §8 | `style-guide.css-snippets.yaml` + `style-guide.semantic-classes.yaml` | button/input/card/nav inversion per §8; leave tooltip/toast structure at base (restyled hard) |
| §9 | verification pass, all facets | signal-orange never body text; green fill-only; confirm labels accompany every semantic color |
