---
slug: neural-neon
base_theme: theme-style-guide
status: sketch
revision: 1
---

# Theme Treatise — Neural Neon

Theme: `theme-neural-neon/` · Base: `theme-style-guide` · Status: sketch

## 1. Identity

- **Intent:** The game's stated house style, made rigorous — a dark-native cyber-arcade skin
  where the player is *inside the machine*, watching their own neural net light up. Energy and
  competitive spectacle first; the decision graph glows as the hero object on every surface.
- **Perception:** Within five seconds: "this is electric, futuristic, and mine to command."
  Alive with signal, never sterminal-drab.
- **Audience:** The Tinkerer (P-001) and Competitive Grinder (P-005) primarily — engineers and
  ladder-climbers who want app-store-screenshot punch and a graph that reads as living circuitry.
- **Tone:** Confident, kinetic, technical-cool. Copy is short and declarative ("YOU TAUGHT AN AI").
- **Keywords:** electric, synaptic, competitive, nocturnal, kinetic
- **Variant note:** Inherits `theme-style-guide` structure (shells, section set, layouts)
  unchanged. Deltas are chromatic (neon triad on near-black), surface treatment (glassmorphism
  + scanline), type (extended display), and motion (confirm-causality glow). No structural
  overrides.

## 2. References & Anchors

- **Anchor — the project README "NEURAL NEON" spec:** honor its exact seeds (canvas `#0A0A0F`,
  surface `#14141F`, primary mint `#00FFAA`, hot pink `#FF3366`, electric blue `#3366FF`, amber
  `#FFAA00`). This treatise is the reasoning behind those values, not a departure from them.
- **Anchor — TensorBoard / Weights & Biases dark dashboards:** borrow the "watch the metric
  move" dopamine — glowing plotted lines on dark, data as light. The graph editor inherits this.
- **Anchor — competitive fighting-game HUDs (Street Fighter 6 neon UI):** borrow the health-bar
  drama and the single-accent "super meter" charge, not the busyness.
- **Anti-reference — "gamer RGB" rainbow dark themes:** never more than the sanctioned triad +
  amber on one screen; saturation is rationed, not sprayed. If two elements fight for the eye at
  equal glow, one is wrong.
- **Anti-reference — cool-retro-term / CRT phosphor nostalgia:** the machine here is *new*. No
  scanline *bloom*, no green-phosphor kitsch, no flicker. The scanline texture is a whisper
  (≤4% alpha), not a costume. (This is exactly the territory `arcade` owns instead.)
- **Anti-reference — flat Material dark:** surfaces are glass and glow, not matte cards with drop
  shadows; elevation reads as light, not paper.

## 3. Color Story

- **Temperature & register:** Cool and saturated on near-black. Neutrals carry a blue undertone
  (~245° hue, ~30% sat, <8% lightness). The palette lives at the electric end — but only the
  accents; the field stays dark and quiet so the neon can sing.
- **Hue relationships:** A three-point electric triad — mint `#00FFAA` (~162°, the "synapse"
  brand hue, dominant), electric blue `#3366FF` (~225°, defense/utility), hot pink `#FF3366`
  (~345°, aggression/damage) — plus amber `#FFAA00` (~40°) reserved strictly for
  currency/rank/reward. Mint leads; the others are supporting voltage.
- **Neutral strategy:** Blue-black, not gray. Re-seed the ramp so "black" is `#0A0A0F` and
  "white" is `#E8E8F0` (cool off-white); every derived step inherits the cool tint. Pure
  `#000`/`#FFF` never appear. Borders sit at `#2A2A3A`.
- **Semantic mapping:** Harmonize with the game's own language — win `#00FFAA`, loss `#FF3366`,
  warning `#FFAA00`, info `#3366FF` (verbatim from README). Collision rule: "loss pink" and
  "brand pink" are intentionally the same hue (damage = the pink energy) but win-mint (162°) and
  info-blue (225°) must never be adjacent at equal saturation without a shape/label difference.
- **Contrast stance:** Crisp, high-contrast for content; atmospheric for chrome. Body `#E8E8F0`
  on `#0A0A0F` ≈ 15:1. Never let neon carry body-size text where it drops below 4.5:1 (see §9).
- **Mode strategy:** **Dark is the only designed mode in v1** — the game is dark-native. There is
  no light mode in v1 (a forced light environment falls back to system-inverted neutrals, not a
  bespoke palette). High-contrast: a "Clarity" toggle drops all glow/scanline, lifts text to
  AAA, and thickens borders to `#3A3A52` — treated as a real accessibility mode, not an
  afterthought (P-008).

## 4. Typographic Voice

- **Families:** Display is an **extended** heavy face — Monument Extended, falling back to Space
  Grotesk Black — uppercase, tight tracking, for fighter names, arena titles, season banners.
  Its wide geometry signals "machine nameplate." UI/body is Inter (fallback DM Sans, then
  `-apple-system`). Mono is JetBrains Mono (fallback `'Menlo', monospace`) for node parameters,
  confidence values, and data readouts. No serif anywhere.
- **Scale character:** Dramatic display jump for hero names (up to ~3× body), tight 1.2 ratio
  for the working UI beneath. The contrast between huge nameplate and calm UI *is* the drama.
- **Weight usage:** 400 body, 500 UI labels, 600 active/emphasis, 800+ only in the extended
  display. Never set paragraphs in the display face.
- **Rhythm:** Body line-height 1.5; mono blocks 1.5, tabular figures on for stat columns. Measure
  ≤ 60ch on mobile. Mono appears for values, IDs, confidence, timers — never headings or prose.

## 5. Space & Density

- **Spacing philosophy:** 8px base unit (inherited). Mobile-first: generous internal padding
  (16–20px) inside glass panels, tight 8–12px gutters between them so the bento hub reads as one
  lit console.
- **Density target:** Reference screen is the Home/Hub — fighter hero card + three bento quick-
  actions + season banner + tab bar, all above the fold on a 390×844 phone with no scroll. Denser
  than a marketing page, looser than the graph editor (which is pan/zoom, not packed).
- **Responsive stance:** Under width pressure the bento grid drops to a single column and the
  fighter card shrinks its stats row first; touch targets and body legibility are protected and
  never fall below 48px / 4.5:1.

## 6. Shape & Surface

- **Radius language:** Soft-tech: 12px on cards/panels, 8px on inputs/buttons, 20px on the pill-
  shaped primary CTA and status chips; 24px maximum (the hero fighter card). No sharp 0px corners.
- **Borders:** 1px `#2A2A3A` structural hairlines; interactive edges get a 1px mint-at-30%
  border that intensifies on focus. Structure comes from glass tone + border together.
- **Elevation:** Glassmorphism — overlays and modals are frosted dark glass (`#14141F` at ~60%
  with 12–16px backdrop blur). Three depth steps: canvas, glass surface, raised glass. Shadows
  are soft and cool (`rgba(10,10,15,0.6)`), used only under overlays.
- **Texture & gradient policy:** Two sanctioned effects: (1) a barely-there horizontal scanline
  overlay at ≤4% alpha on app-shell backgrounds only — the "inside the machine" whisper; (2)
  neural-pathway gradients (mint→blue at low alpha) drawn as connecting lines in backgrounds,
  loaders, and transitions. No noise, no photographic texture.

## 7. Motion & Feedback

- **Animation character:** Motion confirms causality and celebrates outcome — a node connection
  *draws* a glowing line so you see cause; a win *pulses*. Reuse the README motion table as the
  contract.
- **Duration & easing:** Node connection 200ms ease-out; battle hit = screen shake + color flash
  100ms; training generation tick 300ms; win = glow pulse + confetti 800ms spring; loss =
  desaturate + static grain 400ms ease-in; menu = horizontal parallax slide 250ms ease-in-out.
  Nothing routine exceeds 300ms; the 800ms win is the one permitted flourish.
- **Interaction states:** Hover/press lifts glass one step and intensifies the mint edge; active
  compresses 1px (translate); focus is a 2px mint outline offset 2px; disabled drops to 45%
  opacity and removes the glow edge. **State never relies on hue alone** — pair glow with
  outline/elevation (P-008, US-071).

## 8. Component Inflections

- **Buttons:** Primary is the only fully neon-filled element on a screen — mint fill, near-black
  `#0A0A0F` text, 20px pill, subtle outer glow. Secondary is a glass ghost with a 1px mint-30%
  border. Destructive is a hot-pink ghost that fills only on confirm.
- **Inputs:** Recessed glass (one step darker than their surface), 8px radius; focus swaps the
  border for the 2px mint ring. Placeholder held at the 4.5:1 floor.
- **Cards:** The workhorse — frosted glass, 12px radius, 16–20px padding, mint edge only when
  interactive. The fighter card is the hero: 24px radius, houses the 3D model + rank + W/L.
- **Navigation:** Bottom tab bar on canvas; active tab gets a mint glyph + 2px mint underline +
  600 weight (icon *and* label change, never color only). Content floats on glass above.
- **At base defaults (deliberately untouched):** tables, tooltips, breadcrumbs, and toast
  structure inherit `theme-style-guide`, recolored through tokens only.

## 9. Accessibility Commitments

- **WCAG target:** 2.2 AA across the app; AA for the neon-on-dark UI, with the Clarity
  high-contrast mode reaching AAA body text (7:1). Mobile game a11y is a first-class persona
  (P-008), not a checkbox.
- **Contrast minimums:** Body 4.5:1, large/UI 3:1. Verified near-the-line pairs the fine-tuner
  must recheck after any seed change: **electric blue `#3366FF` on `#0A0A0F` ≈ 3.2:1** — large
  UI / icons only, *never* body text; **hot pink `#FF3366` on canvas ≈ 5:1** — safe for large,
  verify at body size; mint and amber sit comfortably (>9:1). Muted text `#6B6B80` fails on
  canvas (~3.4:1) and is banned for anything smaller than 16px semibold — lift to `#8A8AA0`.
- **Focus visibility:** 2px mint outline, 2px offset, on every focusable element; exceeds 3:1 on
  all three glass steps. Focus is restyled, never removed. Touch targets ≥ 48px (US-073).
- **Reduced motion:** `prefers-reduced-motion` disables screen shake, confetti, static grain,
  and scanline shimmer; the win/loss outcome survives as an instant color+label state. All
  transitions clamp to ≤ 100ms instant swaps.

## 10. Facet Mapping Appendix

| Treatise section | Engine facet | Seed hints |
|---|---|---|
| §1 | `branding.yaml` | name "Neural Neon"; intent/perception/audience/tone verbatim; keywords: electric, synaptic, competitive, nocturnal, kinetic; font-url: Space Grotesk + Inter + JetBrains Mono |
| §3 neutrals | `style-guide.vars.yaml` Surfaces | black `#0A0A0F`, white `#E8E8F0`, surface `#14141F`, border `#2A2A3A` |
| §3 accents | `style-guide.vars.yaml` Brand | brand-1 mint `#00FFAA`, brand-2 blue `#3366FF`, brand-3 pink `#FF3366`, accent amber `#FFAA00` |
| §3 semantics | `style-guide.vars.yaml` Semantic | success `#00FFAA`, error/loss `#FF3366`, warning `#FFAA00`, info `#3366FF` |
| §3 modes | `style-guide.color-modes.yaml` | dark primary only; high-contrast "Clarity" (no glow, AAA text, border `#3A3A52`); no v1 light |
| §3 narrative | `style-guide.color-palette.yaml` | groups: Blue-Black Neutrals, Electric Triad, Amber Reward |
| §4 | `style-guide.vars.yaml` Typography + `style-guide.typography.yaml` | font-display `'Monument Extended','Space Grotesk',sans-serif`; font-sans Inter; font-mono JetBrains Mono; 1.2 UI scale, dramatic display jump |
| §5 | `style-guide.vars.yaml` Layout + `style-guide.spacing.yaml` | unit 8px; tight-gutter/generous-panel note; 48px min target |
| §6 | `style-guide.vars.yaml` radius + `style-guide.css-snippets.yaml` | radius 12px base; glassmorphism blur snippet; scanline ≤4% + neural-line gradient snippets |
| §7 | `style-guide.css-snippets.yaml` / `style-guide.scoped-vars.yaml` | `--motion-micro:100ms`, `--motion-menu:250ms`, `--motion-win:800ms`; reduced-motion guard |
| §8 | `style-guide.css-snippets.yaml` + `style-guide.semantic-classes.yaml` | button/input/card/nav per §8; leave tables/tooltips/breadcrumbs at base |
| §9 | verification pass, all facets | recheck blue-on-canvas (3.2:1), pink-on-canvas (5:1), muted-text after any seed change |
