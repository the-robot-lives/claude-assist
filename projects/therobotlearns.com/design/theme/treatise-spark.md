---
slug: spark
base_theme: theme-style-guide
status: sketch
revision: 1
---

# Theme Treatise — Spark

Theme: `theme-spark/` · Base: `theme-style-guide` · Status: sketch

> **Reverse-engineered** from the shipped `theme-spark/` YAML (Stage A). **Render-deferral
> note:** Spark is a rounded, animation-forward consumer web aesthetic — among the least
> terminal-natural directions. In a terminal-first product it is treatise-only for this render
> pass (`status: deferred` in `stage_c.themes`); the intent below is captured in full.

## 1. Identity

- **Intent:** Make learning feel like play — joyful, rewarding, and never intimidating.
- **Perception:** "Warm, encouraging, delightful — a friendly tutor who celebrates your
  progress."
- **Audience:** Curious beginners, students, and hobbyists — anyone who finds traditional
  learning tools sterile.
- **Tone:** Upbeat, supportive, playful — enthusiastic without being patronizing.
- **Keywords:** playful, approachable, joyful, encouraging, vibrant
- **Relationship to base:** inherits `theme-style-guide` (light tier: 4 files). The delta is a
  soft rounded consumer system — the **largest radius in the project (12px)**, a violet accent,
  a warm-soft palette, and an animation-forward, celebratory feedback budget. Distinct from
  `comic` (soft-playful vs loud-playful) and from the developer themes (delight vs efficiency).

## 2. References & Anchors

- **Anchor — Duolingo:** borrow the celebration-of-progress feedback, the friendly rounded
  cards, and the "encouraging tutor" voice.
- **Anchor — a warm consumer wellness app (Headspace-adjacent):** borrow the soft violet
  palette, gentle shadows, and generous rounding.
- **Anchor — modern rounded card UI (soft SaaS onboarding):** borrow pill buttons, 12px cards,
  and micro-animations that reward interaction.
- **Anti-reference — a sterile developer tool (`scholar`):** Spark is warm and rounded where
  scholar is crisp and neutral; the whole point is to *not* feel like a technical instrument.
- **Anti-reference — the loud ink-outline comic (`comic`):** Spark is *soft* playful — no black
  outlines, no shouting; delight is gentle, not aggressive.
- **Anti-reference — flat corporate minimalism:** rounding, soft shadow, and celebratory motion
  are the personality; stripping them yields a generic tool.

## 3. Color Story

- **Temperature & register:** Warm-soft and light-primary — a clean white canvas with a
  lavender-tinted alt surface and a friendly violet accent.
- **Hue relationships:** Violet accent `#8b5cf6` (≈258°) leads (the brand color per the README
  table), with rose `#f43f5e` and amber `#fbbf24` as warm secondaries — an analogous-warm set
  around violet. Violet dominates; rose/amber are supporting delights.
- **Neutral strategy:** Cool-lavender-tinted neutrals — pure white `#ffffff` canvas, `#faf5ff`
  alt surface (violet-tinted), deep indigo-black ink `#1a1a2e`, borders `#e9e5f5`. Never pure
  gray.
- **Semantic mapping:** Friendly set — success `#10b981` (emerald), warning `#f59e0b`, error
  `#ef4444`, info `#6366f1`. *Deliberate distinction (flag):* the `red` seed `#f43f5e` (rose,
  used decoratively) is **intentionally different** from the `error #ef4444` semantic — rose is
  a warm brand delight, red is reserved for genuine errors, so a rose accent never reads as a
  failure. Collision rule respected by keeping them separate hues.
- **Contrast stance:** Softer than the tool themes but AA-compliant — gentle borders and tints,
  yet body text stays crisp. Where softness and legibility conflict, legibility wins.
- **Mode strategy:** **Light is primary and the design target.** A dark mode exists as a
  faithful translation (canvas `#1a1a2e`, text `#ede9fe`, violet lightens to `#a78bfa`) but
  gets no independent design. No high-contrast mode in v1.

## 4. Typographic Voice

- **Families:** Nunito for body and headings (`'Nunito', 'Quicksand', sans-serif`) — its
  rounded terminals reinforce the friendly softness; code is Fira Code. No serif, no separate
  display face — the warmth comes from Nunito's roundness plus weight, not a second family.
- **Scale character:** Moderate, friendly — no dramatic jumps; headings step up gently and
  lean on weight (Nunito 700–800) for presence.
- **Weight usage:** 400 body, 600 labels, 700–800 headings and celebratory numbers. Rounded
  heavy weights read as encouraging, not aggressive.
- **Rhythm:** Comfortable, roomy line-height for body; generous spacing. Mono for code/values
  only — rare in this consumer theme.

## 5. Space & Density

- **Spacing philosophy:** Generous and airy — breathing room signals "no pressure." Cards and
  controls sit with comfortable padding and clear separation.
- **Density target:** Reference screen is a friendly progress/onboarding view: a few large
  rounded cards, a celebratory stat, one clear primary action per screen — low density, high
  encouragement.
- **Responsive stance:** Under width pressure, cards stack to a single comfortable column;
  padding and tap-target size are protected — never cram to fit more.

## 6. Shape & Surface

- **Radius language:** `12px` base — the **roundest theme in the project**; buttons and tags go
  fully pill. Softness is the signature; nothing here is sharp.
- **Borders:** Soft and light (`#e9e5f5`) or borderless — surfaces separate by gentle tint and
  shadow more than by lines.
- **Elevation:** Soft violet-tinted shadows (`rgba(139,92,246,0.08)`) give a gentle lift — cards
  float pleasantly; two soft steps (resting vs raised on hover).
- **Texture & gradient policy:** Restrained soft gradients are permitted (a gentle violet wash
  on hero/celebration surfaces); no harsh gradients, no texture. The alt surface `#faf5ff` does
  much of the warming work without gradients.

## 7. Motion & Feedback

- **Animation character:** The **most expressive in the project** — micro-animations and
  celebratory feedback (a gentle bounce on a completed lesson, a soft pop on a correct answer).
  Motion is a reward system, aligned with the "celebrate progress" intent.
- **Duration & easing:** 150–300ms with gentle spring/ease-out; celebration moments may bounce
  softly but briefly. Nothing harsh or endlessly looping.
- **Interaction states:** Hover lifts the card and may scale ~1.02; active gives a soft press;
  focus is a 2px violet ring (`rgba(139,92,246,0.35)`); disabled fades to ~45%. State pairs
  motion/elevation with the violet ring, never hue alone.

## 8. Component Inflections

- **Buttons:** Pill-shaped, violet fill with white text — the friendly primary; secondary is a
  soft-tinted or bordered pill. Buttons invite tapping, with a gentle press animation.
- **Inputs:** Rounded (12px), soft-bordered or filled `#faf5ff`; focus swaps to the violet ring.
  Friendly, generous tap targets.
- **Cards:** Large rounded (12px) soft-shadow cards — the workhorse; often borderless, floating
  gently on the white canvas.
- **Navigation:** Rounded pill tabs or a soft rail; the active item is a filled violet pill or a
  violet underline + weight, celebratory rather than utilitarian.
- **At base defaults (deliberately untouched):** toasts, breadcrumbs, and modal structure
  inherit `theme-style-guide` with the violet/lavender tokens.

## 9. Accessibility Commitments

- **WCAG target:** 2.2 AA across both modes.
- **Contrast minimums:** Ink `#1a1a2e` on white ≈ 16:1. **Near-the-line pairs to verify: violet
  accent `#8b5cf6` as text/icon on white ≈ 3.9:1 — below the AA body floor; use `text-link
  #7c3aed` (≈5.6:1) for violet text and reserve `#8b5cf6` for fills/large-UI; text-muted
  `#a1a1b5` ≈ 2.6:1 — decorative only.** Verify soft semantic tints hold 4.5:1 for any text on
  them. In dark mode verify violet `#a78bfa` and link `#c4b5fd` on `#1a1a2e`.
- **Focus visibility:** 2px violet ring on every focusable element; verify it clears 3:1 on
  white (use the darker `#7c3aed` if the soft violet falls short). Never removed.
- **Reduced motion:** `prefers-reduced-motion` disables celebration bounce/pop and hover scale;
  rewards fall back to a static state change (a checkmark, a color) so progress still reads.

## 10. Facet Mapping Appendix

| Treatise section | Engine facet | Seed hints |
|---|---|---|
| §1 | `branding.yaml` | name "The Robot Learns" (Spark); intent/perception/audience/tone verbatim; keywords: playful, approachable, joyful, encouraging, vibrant |
| §3 neutrals | `style-guide.vars.yaml` Surfaces | white `#ffffff`, black `#1a1a2e`; alt `#faf5ff` (lavender-tinted), border `#e9e5f5` |
| §3 accent | `style-guide.vars.yaml` Brand | violet `#8b5cf6` leads; rose `#f43f5e` + amber `#fbbf24` secondary (rose ≠ error, deliberate) |
| §3 semantics | `style-guide.vars.yaml` Semantic | success `#10b981`, warning `#f59e0b`, error `#ef4444`, info `#6366f1` |
| §3 modes | `style-guide.color-modes.yaml` | light primary (white); dark: canvas `#1a1a2e`, text `#ede9fe`, violet `#a78bfa`, link `#c4b5fd` |
| §4 | `style-guide.vars.yaml` Typography | font-sans `'Nunito', 'Quicksand', sans-serif`; font-mono `'Fira Code', monospace`; friendly weights 700–800 |
| §5 | `style-guide.vars.yaml` Layout | airy/generous; low density; one primary action per screen |
| §6 | `style-guide.vars.yaml` radius + `style-guide.css-snippets.yaml` | radius `12px` (pills); soft violet-tinted shadows; restrained soft gradient allowed |
| §7 | `style-guide.scoped-vars.yaml` / `css-snippets.yaml` | `--motion: 200–300ms` spring; celebration keyframes + reduced-motion guard |
| §8 | `style-guide.semantic-classes.yaml` | pill violet buttons, rounded soft inputs, large rounded soft-shadow cards, violet-pill active nav |
| §9 | verification across facets | use `#7c3aed` (not `#8b5cf6`) for violet text/focus; muted `#a1a1b5` decorative-only |
