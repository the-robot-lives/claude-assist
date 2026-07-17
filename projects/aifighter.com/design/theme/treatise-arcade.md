---
slug: arcade
base_theme: theme-style-guide
status: sketch
revision: 1
---

# Theme Treatise — Arcade

Theme: `theme-arcade/` · Base: `theme-style-guide` · Status: sketch

## 1. Identity

- **Intent:** A warm CRT fighting-cabinet skin — the neon-lit arcade of the late '80s/'90s, where
  "VS" slams onto a scanline screen and the KO flashes. Where `neural-neon` is a *new* machine,
  Arcade is a *remembered* one: warm phosphor, cabinet bezels, insert-coin energy.
- **Perception:** Within five seconds: "this is a fight, and it's fun." Nostalgic heat, high
  stakes, a grin.
- **Audience:** The Competitive Grinder (P-005) and Curious Casual (P-002) who came for battles;
  the Streamer (P-009) who wants a screen that reads as *hype* on a broadcast.
- **Tone:** Loud, playful-competitive, a little cocky. Copy shouts short ("ROUND 1 — FIGHT!").
- **Keywords:** cabinet, phosphor, hype, nostalgic, combative
- **Variant note:** Inherits `theme-style-guide` structure unchanged. Deltas: warm-black CRT
  palette, condensed marquee display type, chunky beveled surfaces, and embraced scanline/bloom
  texture. No structural overrides.

## 2. References & Anchors

- **Anchor — Street Fighter II / Neo-Geo cabinet UI:** borrow the health-bar drama, the round
  timer, the "VS" title slam, and warm red/amber marquee lettering.
- **Anchor — cool-retro-term & CRT-shader aesthetics:** borrow exactly what `neural-neon` refuses
  — the scanline, the phosphor bloom, the slight vignette. Here the nostalgia is the *point*.
- **Anchor — pinball/arcade cabinet industrial design:** borrow beveled plastic bezels, inset
  screens, and chunky physical buttons as surface metaphors.
- **Anti-reference — clean flat Material / iOS default:** no flat matte cards, no hairline
  minimalism; surfaces have chunky depth and heat.
- **Anti-reference — cool cyber neon (`neural-neon`):** never let the palette drift cool. If a
  screen reads blue-dominant it has left Arcade; the field is warm-black and the accents are
  red/amber first, cyan only as an "insert coin" spark.
- **Anti-reference — photoreal grime/rust "retro":** the CRT is clean glass and bright phosphor,
  not a dirty distressed texture. Nostalgia, not decay.

## 3. Color Story

- **Temperature & register:** Warm and saturated on a warm CRT black. Neutrals carry a red-brown
  undertone (~12° hue). Punchy, high-energy — the warm counterpart to neon's cool.
- **Hue relationships:** Warm-dominant pair — arcade red `#FF2E4C` (~350°) and cabinet amber/gold
  `#FFC021` (~44°) lead every screen; electric cyan `#22D3EE` (~188°) is the single cool "insert
  coin / select" spark; CRT phosphor green `#39FF14` is reserved for "WIN / GO" only. Red and
  amber own ~80% of the color area.
- **Neutral strategy:** Warm-black and warm charcoal. Re-seed "black" `#120A0A`, "white"
  `#F5EDE0` (warm bone). Surfaces `#1E1414`; bezels a warm `#2C1D1D`. Pure black/white never
  appear.
- **Semantic mapping:** Win = phosphor green `#39FF14`, loss = arcade red `#FF2E4C`, warning =
  amber `#FFC021`, info = cyan `#22D3EE`. Collision rule: loss-red and brand-red share the hue —
  losses lean darker/desaturated (`#C4243C`) so "damage" reads distinct from "brand heat."
- **Contrast stance:** High and punchy; bloom is allowed to *add* glow but never to reduce a
  text pair below its floor. Bone text on warm-black ≈ 15:1.
- **Mode strategy:** **Dark-warm is primary** and effectively the only designed mode — arcades
  live in dark rooms. No v1 light mode. High-contrast mode disables scanline + bloom and lifts
  text/accents to AAA (a "Tournament Clarity" toggle), so the CRT costume never blocks a11y.

## 4. Typographic Voice

- **Families:** Display is a **condensed heavy** marquee face — think Anton / a heavy condensed
  grotesque (fallback "Oswald" heavy, `sans-serif`) — uppercase, tight, for VS titles, fighter
  names, ROUND banners. Its tall condensed weight signals "marquee," distinct from neon's *wide*
  extended face. UI/body is a sturdy sans (Inter / Barlow). Mono (JetBrains Mono) for scores,
  timers, combo counts.
- **Scale character:** Big dramatic display (up to ~3.2× body) for fight moments; compact 1.2
  ratio for menus. The marquee/menu size gap carries the arcade drama.
- **Weight usage:** 400 body, 600 UI emphasis, 700 for score numerics, 900 condensed for the
  marquee display only. Never body-set the display face.
- **Rhythm:** Body line-height 1.5; score/timer mono 1.4 tabular. Measure ≤ 60ch mobile. Mono
  appears for numeric hype (scores, timers, W/L, combo) — not prose.

## 5. Space & Density

- **Spacing philosophy:** 8px base. Chunkier than average — 16–24px padding inside beveled
  panels so buttons feel physical and tappable, 12px gutters between cabinet sections.
- **Density target:** Reference screen is the Ranked Arena / Post-Battle — two fighter cards, a
  VS block, health bars, and a result banner filling a 390×844 phone with theatrical spacing (it
  should feel like a fight card, not a spreadsheet).
- **Responsive stance:** Under width pressure, secondary stats collapse under a "MORE" reveal
  first; the VS block, health bars, and primary CTA are protected — the fight staging never
  compresses below legibility or 48px targets.

## 6. Shape & Surface

- **Radius language:** Chunky but not round — 4px base, 6px on large panels, 2px on inset score
  readouts; no pills (a cabinet button is a chunky rectangle, not a lozenge). Max 8px.
- **Borders:** Thick — 2–3px bezel borders in a darker warm tone, often doubled (outer dark +
  inner light highlight) to read as beveled cabinet plastic.
- **Elevation:** Physical bevel — surfaces use a 2-tone inset/outset border + a warm inner
  shadow to look pressed or raised, not floated. One drop-shadow step under modals only.
- **Texture & gradient policy:** Embraced, but disciplined: (1) horizontal scanline overlay at
  8–12% alpha on screen-panels; (2) a soft phosphor **bloom** glow on lit text/accents; (3) a
  subtle CRT vignette on full-screen states. All three are gated off by reduced-motion /
  high-contrast. No dirt, no rust, no film grain beyond the scanline.

## 7. Motion & Feedback

- **Animation character:** Punchy arcade "juice" — motion exaggerates impact and hype. This is
  the one theme allowed a little overshoot.
- **Duration & easing:** Micro 100ms; "VS" slam-in 250ms ease-out with a 1.05 overshoot; KO
  flash 100ms; score tick 200–300ms; menu slide 250ms. Nothing past 350ms except a one-shot win
  celebration (600ms). Easing is snappy with a touch of back-ease on entrances only.
- **Interaction states:** Hover brightens the bezel highlight + adds bloom; active depresses the
  button (translateY 2px + darker inset) like a real cabinet button; focus is a 3px amber outline;
  disabled goes 45% + flat (no bevel, no bloom). State pairs bevel/label change with color, never
  color alone (P-008, US-071).

## 8. Component Inflections

- **Buttons:** Chunky cabinet buttons — primary is a red-to-amber warm fill with a beveled edge
  and bone text; pressing depresses it. Secondary is a bezel-outlined ghost. The primary CTA is
  the only bloom-lit fill on a screen.
- **Inputs:** Inset "coin slot" fields — recessed with an inner shadow, 2px radius, amber focus
  glow. Numeric fields use mono tabular figures.
- **Cards:** Beveled cabinet panels — 4–6px radius, 2–3px double bezel, 16–24px padding, warm
  inner shadow. Fighter cards get a marquee nameplate strip across the top.
- **Navigation:** Bottom tab bar styled as a cabinet control deck; active tab = amber glyph +
  bloom + 700 label + inset press state (icon, weight, and depth all change — not just color).
- **At base defaults (deliberately untouched):** tables, tooltips, and breadcrumbs inherit
  `theme-style-guide`, recolored warm.

## 9. Accessibility Commitments

- **WCAG target:** 2.2 AA; the "Tournament Clarity" high-contrast mode reaches AAA body text and
  is the sanctioned path for P-008 — the CRT effects are cosmetic and fully removable.
- **Contrast minimums:** 4.5:1 body, 3:1 large/UI. Near-the-line pairs to recheck: **arcade red
  `#FF2E4C` on warm-black `#120A0A` ≈ 5.2:1** (large safe, verify body); amber `#FFC021` ≈ 11:1
  and phosphor green ≈ 14:1 sit comfortably; cyan `#22D3EE` ≈ 8:1. Critically: **bloom must not
  be counted toward contrast** — measure the base color, not the glow, since bloom is disabled in
  high-contrast/reduced-motion.
- **Focus visibility:** 3px amber outline, 2px offset, ≥ 3:1 on every warm surface; survives with
  bloom off. Touch targets ≥ 48px (cabinet buttons are naturally large).
- **Reduced motion:** `prefers-reduced-motion` disables scanline shimmer, bloom pulse, VS
  overshoot, and KO flash; outcomes resolve as instant static states with labels. Scanline may
  remain as a *static* texture but stops animating.

## 10. Facet Mapping Appendix

| Treatise section | Engine facet | Seed hints |
|---|---|---|
| §1 | `branding.yaml` | name "Arcade"; intent/perception/audience/tone verbatim; keywords: cabinet, phosphor, hype, nostalgic, combative; font-url: Anton + Barlow + JetBrains Mono |
| §3 neutrals | `style-guide.vars.yaml` Surfaces | black `#120A0A`, white `#F5EDE0`, surface `#1E1414`, bezel `#2C1D1D` |
| §3 accents | `style-guide.vars.yaml` Brand | brand-1 red `#FF2E4C`, brand-2 amber `#FFC021`, brand-3 cyan `#22D3EE`; phosphor green `#39FF14` reserved for WIN |
| §3 semantics | `style-guide.vars.yaml` Semantic | success `#39FF14`, error/loss `#C4243C`, warning `#FFC021`, info `#22D3EE` |
| §3 modes | `style-guide.color-modes.yaml` | dark-warm primary only; high-contrast "Tournament Clarity" (no scanline/bloom, AAA); no v1 light |
| §3 narrative | `style-guide.color-palette.yaml` | groups: Warm CRT Neutrals, Red/Amber Heat, Insert-Coin Cyan |
| §4 | `style-guide.vars.yaml` Typography + `style-guide.typography.yaml` | font-display `'Anton','Oswald',sans-serif` condensed; font-sans Barlow/Inter; font-mono JetBrains Mono; big display jump |
| §5 | `style-guide.vars.yaml` Layout + `style-guide.spacing.yaml` | unit 8px; chunky 16–24px panel padding; protect VS staging + 48px targets |
| §6 | `style-guide.vars.yaml` radius + `style-guide.css-snippets.yaml` | radius 4–6px, no pill; double-bevel border + inner-shadow snippets; scanline 8–12% + bloom + vignette snippets (a11y-gated) |
| §7 | `style-guide.css-snippets.yaml` / `style-guide.scoped-vars.yaml` | `--motion-micro:100ms`, `--motion-vs:250ms back-ease`; reduced-motion kills scanline/bloom/overshoot |
| §8 | `style-guide.css-snippets.yaml` + `style-guide.semantic-classes.yaml` | button/input/card/nav per §8; leave tables/tooltips/breadcrumbs at base |
| §9 | verification pass, all facets | recheck red-on-warm-black (5.2:1) at body size; verify all pairs with bloom OFF |
