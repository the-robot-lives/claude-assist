# Theme Treatise Output

> The design-theory treatment of a theme — a narrative document written before (or alongside) the engine YAML that captures *why* the theme looks the way it does, precisely enough that a fine-tuner can execute against it without re-deriving intent.

---

## 1. Overview

The styleguide-engine renders a theme from ~20 YAML facets in a `theme-{slug}/` directory (see [engine-styleguide.md](engine-styleguide.md)). Those facets encode *values* — hex codes, font stacks, radii — but not *reasoning*. When a theme is fine-tuned, extended, or handed to another agent, the values alone are ambiguous: is `#e85d2f` sacred brand orange or a placeholder? Is the 2px radius a deliberate sharpness statement or an inherited default nobody questioned?

The **theme treatise** closes that gap. It is the authoritative design-theory document for one theme: the palette narrative, the typographic voice, the motion character, the accessibility commitments — every consequential decision stated with its rationale and its boundaries.

**Division of labor:**

| Role | Owns | Skill |
|------|------|-------|
| UX Engineer | Design theory, treatise authoring | this skill |
| Theme Designer | Fine-tuning treatises into engine YAML facets | trl-theme-designer |

> For fine-tuning a treatise into engine YAML, see **trl-theme-designer** — it consumes this document format.

**Rules:**

- **One treatise per theme.** A variant theme that inherits a base (`base-theme: "theme-style-guide"` or a project base) still gets its own treatise — scoped to its deltas, with an explicit statement of what it inherits unchanged.
- **The treatise precedes YAML.** Write (or update) the treatise first; extract YAML second. When theme YAML and treatise disagree, the treatise is the intent of record and one of them is a bug.
- **The section contract is canonical.** The 10 numbered sections below are shared verbatim with trl-theme-designer. Do not rename, renumber, merge, or omit sections — a fine-tuner navigates by number.

---

## 2. File Convention

```
projects/{domain}/design/theme/
  treatise-{slug}.md        ← the treatise (this document)
  theme-{slug}/             ← the engine YAML it governs
    style-guide.meta.yaml
    style-guide.vars.yaml
    branding.yaml
    ...
```

The treatise lives as a **sibling of the theme directory**, named `treatise-{slug}.md` with the same slug as the `theme-{slug}/` it describes. A theme directory without a sibling treatise is an orphan; a treatise without a theme directory is a theme awaiting extraction — both are legitimate intermediate states, but a finished theme has both.

---

## 3. Required Sections (the contract)

Every treatise contains exactly these 10 numbered sections, in this order. Fillable skeleton: [assets/theme-treatise-template.md](../../assets/theme-treatise-template.md).

### §1 Identity

Mirrors the `branding.yaml` fields so extraction is mechanical:

- **Intent** — what the design does; the philosophy in one or two sentences
- **Perception** — what the user should feel within the first five seconds
- **Audience** — who this is for, and the context they arrive in
- **Tone** — voice and communication style
- **Keywords** — 4-6 words the theme must evoke (these seed `branding.yaml` `keywords:`)

For variant themes, also state: the base theme, what the variant is *for* (which product, mode, or audience splits it off), and the one-sentence delta from the base.

### §2 References & Anchors

Aesthetic reference points that triangulate the theme:

- **Anchors** — 2-4 existing products, sites, or style specs (e.g., a `references/styles/*.md` system) the theme should sit near, each with *what specifically* to borrow
- **Anti-references** — 1-3 explicit "not this" examples, each with the specific quality being rejected

Anti-references are not optional. "Warm dark theme" permits a thousand interpretations; "warm dark, but not the amber-on-black terminal nostalgia of cool-retro-term" permits far fewer.

### §3 Color Story

The palette as narrative, not a swatch list:

- **Temperature and register** — warm/cool/neutral; muted/saturated; where on that field the palette lives and why
- **Hue relationships** — how the brand hues relate (analogous, complementary, monochrome + accent) and which hue dominates
- **Neutral strategy** — pure gray vs tinted gray; if tinted, toward which hue and roughly how much
- **Semantic mapping philosophy** — how success/warning/error/info are chosen (harmonize with brand vs deliberately break from it), and any collision rules (e.g., "error red must be distinguishable from brand orange at a glance")
- **Contrast stance** — soft and low-contrast, crisp and high-contrast, or somewhere stated in between; where the theme is allowed to be subtle and where it must not be
- **Mode strategy** — which of light / dark / high-contrast modes exist, which is primary, and whether non-primary modes are faithful translations or distinct designs

### §4 Typographic Voice

- **Families** — sans/serif/mono choices with *why each* (what the letterforms signal), plus fallback stacks
- **Scale character** — tight editorial scale vs dramatic display jumps; approximate ratio
- **Weight usage** — which weights exist and what each is reserved for
- **Rhythm** — line-height philosophy, measure targets, where mono appears (code only? data? labels?)

### §5 Space & Density

- **Spacing philosophy** — base unit and how generosity scales (airy marketing vs compact tooling)
- **Density target** — the reference screen (dashboard, article, form) and how much content it should hold per viewport
- **Responsive stance** — what compresses first under width pressure, and what is protected

### §6 Shape & Surface

- **Radius language** — sharp, soft, or pill; the base radius and where exceptions live
- **Borders** — visible structural borders vs borderless surfaces separated by tone
- **Elevation** — shadows vs flat tonal layering; how many elevation steps exist
- **Texture & gradient policy** — allowed at all? If yes, where and how restrained; if no, say so explicitly

### §7 Motion & Feedback

- **Animation character** — snappy/instrumental vs smooth/expressive; what motion is *for* in this theme
- **Duration & easing philosophy** — the timing bands (micro/hover/transition) and easing family
- **Interaction states** — how hover, active, focus, and disabled read; whether state changes use color, elevation, motion, or several

### §8 Component Inflections

How the theme bends the key components away from neutral defaults — minimum coverage: **buttons, inputs, cards, navigation**. For each, one to three sentences on what makes this theme's version *this theme's* (e.g., "primary buttons are the only saturated-fill element on any screen"). Skip components the theme leaves at base defaults, and say that you're skipping them.

### §9 Accessibility Commitments

Non-negotiables the fine-tuner must verify, not aspire to:

- **WCAG target** — 2.2 AA minimum (per skill quality baselines); state anything stricter
- **Contrast minimums** — 4.5:1 body text, 3:1 large text and UI components; call out any palette pairs known to be near the line
- **Focus visibility** — what the focus indicator looks like and its contrast guarantee
- **Reduced motion** — what `prefers-reduced-motion` disables and what survives

### §10 Facet Mapping Appendix

An **advisory** table mapping §1-§9 decisions to engine YAML facets with seed-value hints. Advisory means: the fine-tuner may deviate where the engine's cascade produces a better result, but must preserve the stated intent. Format:

| Treatise section | Engine facet | Seed hints |
|------------------|-------------|------------|
| §1 Identity | `branding.yaml` | intent/perception/audience/tone/keywords verbatim |
| §3 Color Story | `style-guide.vars.yaml` (Surfaces, Brand, Semantic groups) | hex seeds or tight ranges |
| §3 Mode strategy | `style-guide.color-modes.yaml` | per-mode surface/text/border tokens |
| §3 Palette narrative | `style-guide.color-palette.yaml` | swatch groups + usage rules |
| §4 Typographic Voice | `style-guide.vars.yaml` (Typography group), `style-guide.typography.yaml`, `branding.yaml` `font-url` | font stacks, scale notes |
| §5 Space & Density | `style-guide.vars.yaml` (Layout group), `style-guide.spacing.yaml` | unit, density notes |
| §6 Shape & Surface | `style-guide.vars.yaml` (radius), `style-guide.css-snippets.yaml` | radius, shadow/border snippets |
| §7 Motion & Feedback | `style-guide.css-snippets.yaml`, `style-guide.scoped-vars.yaml` | duration/easing custom props |
| §8 Component Inflections | `style-guide.css-snippets.yaml`, `style-guide.semantic-classes.yaml` | per-component overrides |
| §9 Accessibility | verification constraints across all facets | contrast pairs to check |

---

## 4. What Makes a Treatise Executable

The single quality bar: **every claim must be decidable by the fine-tuner.** Given a candidate YAML value, the fine-tuner should be able to read the treatise and answer "does this honor the intent — yes or no?" without asking the author.

| Vague (reject) | Executable (accept) |
|----------------|---------------------|
| "Warm, inviting colors" | "Palette centers on 20-35° hues (ember orange); neutrals are warm grays tinted ~4% toward orange; no hue cooler than 220° appears outside semantic info-blue" |
| "Clean, modern typography" | "Single geometric sans (Inter) for all UI text; mono (JetBrains Mono) reserved for code and data values; no serif anywhere" |
| "Subtle animations" | "Micro-interactions 80-120ms ease-out; nothing exceeds 250ms; no motion on scroll" |
| "Accessible" | "AA at minimum; ember-500 on canvas-900 measures ~4.7:1 — do not lighten the canvas without rechecking" |
| "Buttons should feel solid" | "Primary buttons are the only saturated-fill elements on a screen; secondary buttons are 1px-border ghosts on the surface tone" |

Techniques that produce executable claims:

1. **Give ranges, not adjectives.** "Radius 2-4px" is decidable; "slightly rounded" is not.
2. **State exclusions.** What the theme *never* does constrains more than what it prefers.
3. **Name the tradeoff winner.** "When density and whitespace conflict, density wins" resolves a whole class of future questions.
4. **Anchor to measurables.** Contrast ratios, hue-degree bands, ms durations, px units.
5. **Mark degrees of freedom.** Where the fine-tuner genuinely may choose, say so: "exact gray ramp is the engine's to derive from the white/black seeds."

Precision has a purpose, not a fetish: a treatise that pins every hex code is just YAML with prose overhead. Pin what carries the identity; delegate what the engine's cascade derives well.

---

## 5. Worked Example: `treatise-ember.md`

A complete treatise for a fictional theme — **ember**, a warm dark developer-tool theme inheriting `theme-style-guide`. This is the shape and depth to aim for.

```markdown
# Theme Treatise — Ember

Theme: `theme-ember/` · Base: `theme-style-guide` · Status: ready for fine-tuning

## 1. Identity

- **Intent:** A dark-native workspace for developers that trades the usual
  blue-cold terminal palette for controlled warmth — the focus of a dark room
  lit by a single warm source. Restraint everywhere except the one accent.
- **Perception:** "This tool is calm, serious, and slightly alive." Warmth
  without playfulness; darkness without gloom.
- **Audience:** Professional developers in long sessions (2+ hours), often in
  low ambient light, monitoring builds and editing configuration. They value
  legibility and low visual fatigue over branding flourish.
- **Tone:** Quiet, precise, technical. Copy is terse; the UI never exclaims.
- **Keywords:** warm, focused, nocturnal, precise, unhurried
- **Variant note:** Inherits `theme-style-guide` structure (layouts, shells,
  section set) unchanged. The delta is entirely chromatic, typographic weight,
  and motion timing — no structural overrides.

## 2. References & Anchors

- **Anchor — Nocturne style spec** (`references/styles/nocturne.md`): the
  dark-native philosophy — dark as canvas, not inverted light mode. Borrow the
  layered-surface elevation model wholesale.
- **Anchor — Zed editor's "Ayu Mirage" family:** the demonstration that warm
  darks can stay professional. Borrow the desaturated warm-gray text hierarchy.
- **Anchor — analog VU meters / studio hardware:** amber-on-charcoal as the
  signal color of instruments. Borrow the single-glow-source discipline.
- **Anti-reference — cool-retro-term / CRT nostalgia:** no scanlines, no glow
  blur, no phosphor kitsch. Warmth here is material, not nostalgic.
- **Anti-reference — "gamer RGB" dark themes:** never more than one saturated
  hue on screen. If two elements compete in saturation, one is wrong.
- **Anti-reference — pitch-black OLED themes (#000 canvas):** pure black makes
  the warm tint unreadable as intent; the canvas must visibly carry warmth.

## 3. Color Story

- **Temperature & register:** Warm and muted. Every neutral is tinted toward
  orange; every saturated color except semantic info stays in the 15-45° hue
  band. Saturation is spent like money: the accent is the only rich element.
- **Hue relationships:** Monochrome-warm + single accent. Accent is ember
  orange `#e8763a` (±5° hue, ±8% saturation acceptable). No secondary brand
  hue — where a second distinguishing color is needed, use a lighter/darker
  ember step, not a new hue.
- **Neutral strategy:** Warm charcoals, not grays. Canvas ~`#1a1512` (a brown-
  black, roughly 25° hue at 15-20% saturation, 8-10% lightness). The gray ramp
  the engine derives from white/black seeds must be re-seeded: "black" seed is
  `#141110`, "white" seed is `#f5efe8` (warm off-white) so every derived step
  inherits the tint. Pure `#000`/`#fff` never appear.
- **Semantic mapping:** Harmonize, don't match. Success is an olive-warm green
  `#8aa84f`-region (a cold mint would shatter the temperature); warning is
  amber but must be visually distinct from the ember accent — push it yellower
  (~48°) and lighter; error is a red clearly redder than ember (~5°, higher
  saturation); info is the one permitted cool — a muted slate blue `#6a8caf`-
  region, desaturated so it reads as annotation, not alarm.
- **Contrast stance:** Medium-soft for chrome, crisp for content. Body text on
  canvas targets 10:1+ (warm off-white on charcoal); secondary text may drop
  to ~5:1 but never below 4.5:1. Borders and dividers may sit near 1.5:1 —
  structure comes from surface layering, not lines.
- **Mode strategy:** Dark is the primary and the design target. Light mode
  exists as a faithful translation (warm paper `#f5efe8` canvas, same ember
  accent darkened to `#c85a20` for contrast) but receives no independent
  design decisions. No high-contrast mode in v1; the dark palette already
  passes AA with margin, and forced-colors users get system colors untouched.

## 4. Typographic Voice

- **Families:** UI sans is Inter (neutral, high x-height, disappears into the
  work); code/data mono is JetBrains Mono (its 400 weight holds up at 13px on
  dark). Rationale: the theme's personality lives in color and light, so type
  stays instrumental. No serif anywhere. Fallbacks: `-apple-system, sans-serif`
  and `'Menlo', monospace`.
- **Scale character:** Tight tooling scale, ~1.2 ratio. Headings distinguish
  by weight and spacing more than size — the largest heading on a working
  screen is at most 2× body.
- **Weight usage:** 400 body, 500 emphasized UI labels, 600 headings and the
  active nav item. 700 exists only in the brand wordmark. Never bold whole
  paragraphs.
- **Rhythm:** Body line-height 1.6; mono blocks 1.5. Measure capped ~70ch in
  docs panes. Mono appears for code, literal values, IDs, and timestamps —
  never for headings or prose.

## 5. Space & Density

- **Spacing philosophy:** 8px base unit, inherited from base theme. Padding is
  spent inside cards, not between them — surfaces sit close (8-12px gutters)
  with generous internal padding (16-24px), reinforcing the layered-material
  feel.
- **Density target:** Reference screen is a build-monitor dashboard: 6-8 status
  cards plus a log pane visible on a 1440×900 viewport without scrolling.
  Denser than marketing, looser than a trading terminal.
- **Responsive stance:** Under width pressure, the sidebar collapses to icons
  first, then card grids drop columns; internal card padding and body font
  size are protected — never compress legibility to fit more cards.

## 6. Shape & Surface

- **Radius language:** Soft-technical: 4px base radius on cards and inputs,
  2px on small chips/badges, 6px maximum anywhere. No pills.
- **Borders:** Structural borders are rare. Surfaces separate by tone: each
  elevation step is a warmer, slightly lighter charcoal. A 1px border in
  `rgba(232,118,58,0.12)` (ember at 12%) marks only *interactive* surface
  edges (inputs, focused cards).
- **Elevation:** Three steps — canvas, surface, raised — expressed by
  lightness, not shadow. Shadows exist only under overlays (modals, menus):
  soft, large-radius, warm-black (`rgba(20,17,16,0.6)`), never crisp.
- **Texture & gradient policy:** One sanctioned gradient: a barely-visible
  radial warmth (ember at 3-5% alpha) allowed on the app shell header and
  empty states — the "light source." Nowhere else. No noise, no patterns.

## 7. Motion & Feedback

- **Animation character:** Instrumental with one expressive exception. UI
  motion confirms causality (this opened because you clicked); the exception
  is a slow ember pulse (2s ease-in-out loop, opacity 0.7→1.0) permitted only
  on "in-progress" status indicators — the coal breathing.
- **Duration & easing:** Micro-feedback 80-120ms ease-out; panel/overlay
  transitions 180-220ms ease-in-out; nothing exceeds 250ms except the status
  pulse. No spring/bounce easing anywhere.
- **Interaction states:** Hover lightens surface one elevation step (no color
  shift); active compresses padding by 1px equivalent (translate, not resize);
  focus is a 2px ember outline offset 2px (see §9); disabled drops to 45%
  opacity and removes the interactive border. State changes never rely on the
  ember hue alone — pair with elevation or outline.

## 8. Component Inflections

- **Buttons:** Primary is the only saturated-fill element on any screen —
  ember fill, near-black warm text (`#1a1512`), 4px radius. Secondary is a
  ghost: 1px ember-12% border, off-white text, transparent fill. Destructive
  uses the semantic error red as border+text ghost, filling only on hover.
- **Inputs:** Recessed one elevation step *below* their surface (darker, not
  lighter) — fields read as cut into the material. Focus swaps the recessed
  border for the ember focus ring. Placeholder at the 4.5:1 floor, no lower.
- **Cards:** The workhorse surface — one elevation step up, 4px radius,
  16-24px padding, no border unless interactive. Status cards carry a 3px
  left-edge semantic stripe instead of tinted backgrounds.
- **Navigation:** Sidebar sits on canvas (step 0), content on surface (step 1)
  — nav reads as the room, content as the desk. Active item: 600 weight +
  2px ember left rail. No filled active backgrounds.
- **At base defaults (deliberately untouched):** tables, toasts, modals'
  structure, breadcrumbs — inherit `theme-style-guide` behavior with the ember
  palette applied through tokens only.

## 9. Accessibility Commitments

- **WCAG target:** 2.2 AA across both modes; AAA (7:1) for body text in dark
  mode specifically, since long-session legibility is the product promise.
- **Contrast minimums:** Body `#f5efe8` on canvas `#1a1512` ≈ 14:1 (pass with
  margin). Known near-the-line pairs the fine-tuner must verify after any
  seed adjustment: ember `#e8763a` as *text* on canvas ≈ 5.4:1 (safe for
  large/UI, verify if used for body-size text); secondary text step must stay
  ≥ 4.5:1 — the warm tint tempts it darker.
- **Focus visibility:** 2px solid ember outline, 2px offset, on every
  focusable element; against all three surface steps the outline exceeds 3:1.
  Focus is never removed, only restyled.
- **Reduced motion:** `prefers-reduced-motion` disables the status pulse
  (replaced by a static ember dot + label) and all transitions over 100ms;
  hover elevation changes survive as instant state swaps.

## 10. Facet Mapping Appendix

| Treatise section | Engine facet | Seed hints |
|---|---|---|
| §1 | `branding.yaml` | name "Ember"; intent/perception/audience/tone above, verbatim; keywords: warm, focused, nocturnal, precise, unhurried; font-url: Inter + JetBrains Mono |
| §3 neutrals | `style-guide.vars.yaml` Surfaces | white: `#f5efe8`, black: `#141110` (warm seeds — the derived ramp carries the tint) |
| §3 accent | `style-guide.vars.yaml` Brand | single brand color `#e8763a`; do not populate a second/third brand hue |
| §3 semantics | `style-guide.vars.yaml` Semantic | success ~`#8aa84f`, warning ~`#d9a83c`, error ~`#cc4433`, info ~`#6a8caf` — tune within the hue constraints of §3 |
| §3 modes | `style-guide.color-modes.yaml` | dark primary (canvas `#1a1512`); light: canvas `#f5efe8`, accent darkened to ~`#c85a20` |
| §3 narrative | `style-guide.color-palette.yaml` | three groups: Warm Neutrals, Ember, Semantics; usage rules from §3/§8 |
| §4 | `style-guide.vars.yaml` Typography + `style-guide.typography.yaml` | font-sans: `'Inter', -apple-system, sans-serif`; font-mono: `'JetBrains Mono', 'Menlo', monospace`; 1.2 scale note |
| §5 | `style-guide.vars.yaml` Layout + `style-guide.spacing.yaml` | unit 8px (inherit); document the tight-gutter/generous-padding rule |
| §6 | `style-guide.vars.yaml` radius + `style-guide.css-snippets.yaml` | radius: `4px`; elevation steps + overlay shadow + the one sanctioned gradient as snippets |
| §7 | `style-guide.css-snippets.yaml` / `style-guide.scoped-vars.yaml` | `--motion-micro: 100ms`, `--motion-panel: 200ms`; status-pulse keyframes + reduced-motion guard |
| §8 | `style-guide.css-snippets.yaml` + `style-guide.semantic-classes.yaml` | button/input/card/nav overrides per §8; leave listed components at base |
| §9 | verification pass, all facets | recheck ember-on-canvas and secondary-text ratios after any seed change |
```

---

## 6. Authoring Guidance

1. **Write §1 and §2 first, then §3.** Identity and anchors constrain the color story; a palette chosen before the anti-references are named tends to drift back toward genre defaults.
2. **Read the base theme before writing a variant treatise.** A variant treatise that restates the base wholesale is noise; one that only lists deltas without naming the base's relevant behavior is unexecutable. State the inheritance, then the deltas.
3. **Steal structure from the style specs.** The `references/styles/*.md` systems (positioning → color → typography → spacing → components → interaction) are proven treatise raw material — a treatise for a Minimal Tech-derived theme should cite the spec as an anchor and document only where it departs.
4. **Every adjective earns a number or an exclusion.** Sweep the draft for bare adjectives ("clean," "bold," "subtle") and attach a measurable or a "never" to each — see §4 above.
5. **The Facet Mapping Appendix is written last** and is a *summary*, not new content. If writing the appendix surfaces a decision not present in §1-§9, the decision belongs in the body first.
6. **Keep it to one document.** If the treatise wants to sprawl past ~400 lines, the theme is probably two themes.

---

## 7. Quality Checklist

Before handing a treatise to trl-theme-designer:

- [ ] File is at `projects/{domain}/design/theme/treatise-{slug}.md`, slug matches the (existing or planned) `theme-{slug}/` directory
- [ ] All 10 sections present, numbered, in canonical order
- [ ] §1 fields map one-to-one onto `branding.yaml` (intent, perception, audience, tone, keywords)
- [ ] §2 contains at least one explicit anti-reference with the rejected quality named
- [ ] §3 states a mode strategy covering light, dark, and high-contrast (even if the answer is "does not exist in v1")
- [ ] No bare adjectives — every claim is decidable (has a range, a measurable, an exclusion, or a named tradeoff winner)
- [ ] Degrees of freedom are marked — the fine-tuner knows what is pinned vs delegated to the engine cascade
- [ ] §9 states WCAG 2.2 AA or stricter, with known near-the-line contrast pairs called out
- [ ] §10 appendix rows cover every facet the theme overrides; no appendix row introduces a decision absent from §1-§9
- [ ] Variant themes: base named, inherited-unchanged scope stated, deltas enumerated
- [ ] Length is roughly 150-400 lines — long enough to decide with, short enough to hold in context

---

## 8. Related Documents

- [engine-styleguide.md](engine-styleguide.md) — the YAML facets a treatise is fine-tuned into
- [styleguide-setup-guide.md](styleguide-setup-guide.md) — end-to-end engine setup and theme hosting
- [../process/style-guide-construction.md](../process/style-guide-construction.md) — the construction process a treatise documents the results of
- [../../assets/theme-treatise-template.md](../../assets/theme-treatise-template.md) — fillable skeleton

> For fine-tuning a treatise into engine YAML, see **trl-theme-designer** — it consumes this document format.
