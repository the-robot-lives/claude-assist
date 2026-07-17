---
slug: biolume
base_theme: theme-style-guide
status: sketch
revision: 1
---

# Theme Treatise — Biolume

Theme: `theme-biolume/` · Base: `theme-style-guide` · Status: sketch

## 1. Identity

- **Intent:** The neural net taken **biologically** — a fighter's brain as living, bioluminescent
  tissue seen in deep water. Where `neural-neon` renders a machine and `signal` renders an
  instrument, Biolume renders an *organism*: soft glows, flowing connections, synapses that
  breathe. The graph is wondrous, not clinical.
- **Perception:** Within five seconds: "this thing is alive." Calm awe, organic warmth in a cool
  dark, curiosity.
- **Audience:** The Data Artist (P-010) and Creator-Spectator (P-003) who treat the graph as
  identity and art; the Curious Casual (P-002) drawn in by beauty before mechanics.
- **Tone:** Poetic-technical, gentle, unhurried. Copy uses growth/life metaphors ("your fighter
  *evolved*").
- **Keywords:** bioluminescent, organic, synaptic, flowing, alive
- **Variant note:** Inherits `theme-style-guide` structure unchanged. Deltas: violet-black
  palette, soft diffuse glow, organic large-radius shapes, humanist rounded type, breathing
  motion. No structural overrides.

## 2. References & Anchors

- **Anchor — deep-sea bioluminescence & neuron microscopy imagery:** borrow the dark violet
  field with soft teal/magenta light sources and diffuse, blurred glow — light that *emanates*
  rather than beams.
- **Anchor — aurora / nebula gradient meshes:** borrow slow-shifting multi-hue gradient fields
  for backgrounds and empty states.
- **Anchor — organic/generative art (Casey Reas, node-garden visuals):** borrow flowing curved
  connections and node-as-cell forms for the graph editor.
- **Anti-reference — hard neon / `neural-neon`:** never a sharp high-frequency glow or a
  geometric grid. Biolume's light is soft-edged (20–40px blur, low alpha); a crisp 1px neon line
  is off-theme. This is the key split from the sibling dark theme.
- **Anti-reference — clinical light data UI (`signal`):** no thin square grid, no mono readouts
  as the default voice; the organism is felt, not tabulated.
- **Anti-reference — "toxic slime" sci-fi green:** the palette is jewel-like teal/violet, never a
  radioactive yellow-green; keep hues in the 150–290° arc.

## 3. Color Story

- **Temperature & register:** Cool-violet, saturated but **soft** — glows are diffuse and
  ambient, not high-contrast. A deep, calm dark with luminous accents.
- **Hue relationships:** An analogous violet→teal sweep with a magenta pulse — canvas violet
  (~262°), primary bio-teal `#2BF5C6` (~165°, the living-synapse glow, dominant), neuron magenta
  `#C86BF0` (~285°, secondary pulse), deep-sea cyan `#38BDF8` (~200°) as connective tissue.
  Teal leads; magenta accents sparingly.
- **Neutral strategy:** Violet-tinted near-black and grays (270° hue, low sat). Re-seed "black"
  `#0D0A1F`, "white" `#ECE8F5` (soft lilac-white). Surface `#171233`. Pure black/white never
  appear — the violet must be felt in every neutral.
- **Semantic mapping:** Softened and organic — success bio-teal `#2BF5C6`, error a coral-red
  `#FB6E7E` (organic, never a harsh fire-engine red), warning a warm amber `#F5A524` (the one
  warm "firefly" break), info deep-sea cyan `#38BDF8`. Collision rule: success-teal equals the
  brand glow, so success adds a bloom-pulse + label, never teal-color alone.
- **Contrast stance:** Medium-soft for atmosphere, but text holds its floor. Body `#ECE8F5` on
  `#0D0A1F` ≈ 15:1. Glows are ambient (they add mood, not legibility); never rely on a glow to
  carry contrast.
- **Mode strategy:** **Dark is primary** — bioluminescence requires darkness. A light "daylight
  tissue" mode exists as a faithful translation (pale lilac canvas `#F4F1FB`, teal darkened to
  `#0E9E86`, magenta to `#9B3FC4`) for bright-environment play, but is secondary. High-contrast:
  glow removed, accents brightened and text lifted to AAA.

## 4. Typographic Voice

- **Families:** Humanist and softly rounded — display/UI is a rounded humanist sans (Figtree or
  Nunito Sans; fallback `-apple-system, sans-serif`) whose open, organic terminals feel grown,
  not drafted. No extended/condensed drama, no serif. Mono (JetBrains Mono) is used **minimally**
  — only for raw exported values — because Biolume speaks in warmth, not readouts.
- **Scale character:** Gentle, ~1.25 ratio, flowing hierarchy; the largest heading ≤ 2.2× body.
  Softer size steps than the combative themes.
- **Weight usage:** 400 body, 500 labels, 600 headings; 700 reserved for a fighter's name. Round
  weights only.
- **Rhythm:** Generous line-height 1.65 (airy, breathing); measure ≤ 66ch. Mono appears rarely
  and never for headings — the theme's default numeric voice is still the humanist sans.

## 5. Space & Density

- **Spacing philosophy:** 8px base, run **airy** — 20–28px internal padding, generous 16px
  gutters; whitespace is part of the calm. The least dense theme in the set.
- **Density target:** Reference screen is the Laboratory / public profile — a hero graph
  visualization with a few floating stat pods and breathing room around each; content should feel
  suspended in dark water, not packed.
- **Responsive stance:** Under width pressure, floating stat pods stack and the graph scales to
  fit first; the graph hero and its glow are protected — never crop the organism to gain a
  column.

## 6. Shape & Surface

- **Radius language:** Soft and organic — 16px base on cards, 20px on large surfaces, full pills
  on chips/buttons; blob/organic SVG shapes allowed for decorative cells. Max 24px + pills. The
  roundest theme alongside `sandbox`, but darker and more flowing.
- **Borders:** Mostly borderless — surfaces separate by a soft violet tone step and an ambient
  glow halo, not lines. Interactive edges get a 1px teal-at-25% glow-border.
- **Elevation:** Diffuse glow instead of shadow — raised surfaces emit a soft 20–40px teal/violet
  glow at low alpha and sit a half-step lighter. Modals add a soft dark violet backdrop, no crisp
  shadow.
- **Texture & gradient policy:** Gradients are core, not forbidden — slow aurora/nebula mesh
  gradients (teal↔violet↔magenta at low alpha) on backgrounds, empty states, and the graph field;
  soft particle "spores" drifting on hero screens. All gated off by reduced-motion. No hard
  texture, no scanline, no noise.

## 7. Motion & Feedback

- **Animation character:** Breathing and flowing — motion is organic and expressive, the theme's
  signature. Active synapses pulse like a living thing.
- **Duration & easing:** Micro 120ms ease-out; flowing transitions 250–400ms ease-in-out; a slow
  bioluminescent **breathing** loop (2.5s ease-in-out, opacity 0.6→1.0) permitted on active
  graph nodes and "training in progress" states. Connections draw along curved paths 350ms. No
  snappy back-ease; everything eases smoothly.
- **Interaction states:** Hover swells the glow halo + lifts a half-step; active gently
  compresses (scale 0.98); focus is a 2px teal glow-ring; disabled dims to 40% and stills the
  breathing. State changes pair glow + scale + label — never hue alone (P-008, US-071).

## 8. Component Inflections

- **Buttons:** Primary is a pill with a soft teal→cyan gradient fill, dark-violet text, and a
  gentle outer glow — the only glowing fill on a screen. Secondary is a glass-violet pill with a
  teal glow-border. Destructive uses coral-red as a glow-border ghost.
- **Inputs:** Rounded 16px fields on a half-step-lighter violet surface, borderless until focus,
  when a teal glow-ring blooms. Placeholder held at the 4.5:1 floor.
- **Cards:** Soft rounded 16px surfaces, borderless, separated by tone + a faint glow halo,
  20–28px padding. The graph-visualization card is the hero — full-bleed dark field with the
  living graph glowing inside.
- **Navigation:** Bottom tab bar floating on the dark field; active tab = teal glyph with a soft
  glow bloom + 600 label (glow + weight, not color alone).
- **At base defaults (deliberately untouched):** tables, tooltips, and breadcrumbs inherit
  `theme-style-guide`, recolored to violet neutrals.

## 9. Accessibility Commitments

- **WCAG target:** 2.2 AA; AAA for body text in dark mode (the calm-reading promise). High-
  contrast mode strips glow so nothing depends on it.
- **Contrast minimums:** 4.5:1 body, 3:1 large/UI, measured on the **base color with glow
  removed**. Near-the-line pairs to recheck: **neuron magenta `#C86BF0` on `#0D0A1F` ≈ 6:1** and
  **coral-red `#FB6E7E` ≈ 6:1** (both safe, but do not darken); bio-teal ≈ 13:1 sits comfortably.
  Because the theme is low-contrast by mood, the fine-tuner must guard against secondary text
  drifting below 4.5:1 to "feel softer" — it may not.
- **Focus visibility:** 2px teal glow-ring, 2px offset, whose *solid* core (not the glow) clears
  3:1 on every violet surface; survives high-contrast with the glow removed.
- **Reduced motion:** `prefers-reduced-motion` stops all breathing, drifting spores, and gradient
  motion; active nodes become a static brighter state + label. Curved connection draws become
  instant.

## 10. Facet Mapping Appendix

| Treatise section | Engine facet | Seed hints |
|---|---|---|
| §1 | `branding.yaml` | name "Biolume"; intent/perception/audience/tone verbatim; keywords: bioluminescent, organic, synaptic, flowing, alive; font-url: Figtree + JetBrains Mono |
| §3 neutrals | `style-guide.vars.yaml` Surfaces | black `#0D0A1F`, white `#ECE8F5`, surface `#171233` (violet-tinted ramp) |
| §3 accents | `style-guide.vars.yaml` Brand | brand-1 bio-teal `#2BF5C6`, brand-2 magenta `#C86BF0`, brand-3 cyan `#38BDF8` |
| §3 semantics | `style-guide.vars.yaml` Semantic | success `#2BF5C6`, error `#FB6E7E`, warning `#F5A524`, info `#38BDF8` |
| §3 modes | `style-guide.color-modes.yaml` | dark primary; light "daylight tissue" (canvas `#F4F1FB`, teal `#0E9E86`, magenta `#9B3FC4`); high-contrast glow off + AAA |
| §3 narrative | `style-guide.color-palette.yaml` | groups: Violet Neutrals, Bioluminescent Teal, Neuron Magenta; usage: glow ambient not contrast |
| §4 | `style-guide.vars.yaml` Typography + `style-guide.typography.yaml` | font-sans `'Figtree','Nunito Sans',sans-serif`; font-mono JetBrains Mono (minimal); 1.25 scale, line-height 1.65 |
| §5 | `style-guide.vars.yaml` Layout + `style-guide.spacing.yaml` | unit 8px; airy 20–28px padding; protect graph hero + glow |
| §6 | `style-guide.vars.yaml` radius + `style-guide.css-snippets.yaml` | radius 16px base, pills; borderless + glow-halo snippets; aurora mesh gradient + spore particles (a11y-gated) |
| §7 | `style-guide.css-snippets.yaml` / `style-guide.scoped-vars.yaml` | `--motion-micro:120ms`, `--motion-flow:350ms ease-in-out`, `--breathe:2.5s`; reduced-motion guard stills breathing |
| §8 | `style-guide.css-snippets.yaml` + `style-guide.semantic-classes.yaml` | button/input/card/nav per §8; leave tables/tooltips/breadcrumbs at base |
| §9 | verification pass, all facets | measure all pairs glow-OFF; guard secondary text ≥ 4.5:1; recheck magenta/coral after any seed change |
