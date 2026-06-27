# TRFI Candidate UI Themes

Three candidate visual directions for **The Robot Fakes It**'s own application
interface (Editor, Theme Studio, Prototype Player). Each is rendered as a
self-contained HTML mockup in this directory:

- [`blueprint.html`](./blueprint.html) — Theme A, Blueprint
- [`nocturne.html`](./nocturne.html) — Theme B, Nocturne
- [`paper.html`](./paper.html) — Theme C, Paper

Every file stacks all three key pages vertically as labeled screen frames, so
you can scroll one theme top-to-bottom to see the whole product in that skin.

---

## Theme A — Blueprint

> Minimal-tech, drafting-table light. Monochrome on a measured grid with one
> blueprint-ink accent.

| Role | Hex |
|------|-----|
| bg | `#F4F6F8` |
| surface | `#FFFFFF` |
| text | `#16202B` |
| muted | `#5D6B78` |
| border | `#C7D2DC` |
| accent | `#0B6FB8` (blueprint cyan/ink) |

- **Font stack:** `"Inter", "Helvetica Neue", Arial, system-ui, sans-serif`;
  monospace `"SF Mono", ui-monospace, "Cascadia Mono", Menlo, Consolas, monospace`
  for DSL source, tokens, and logs.
- **Radius:** `4px` (tight, technical).
- **Motif:** faint engineering grid in the page background and canvas; square
  "measurement" accents; uppercase mono micro-labels.
- **Signal / personality:** precision, calm, engineering trust. Reads like a CAD
  / drafting tool — nothing decorative, everything aligned.
- **Best-suited user:** the **engineer / design-systems author** who wants the
  tool to disappear and the structure to dominate; teams who pair TRFI with a
  formal component library and value legibility over mood.
- **Contrast notes:** body text `#16202B` on `#FFFFFF` ≈ 15:1; muted `#5D6B78`
  on `#FFFFFF` ≈ 5:1; accent `#0B6FB8` on white ≈ 4.7:1 — all pass WCAG AA for
  body text.

---

## Theme B — Nocturne

> Dark-native creative instrument. Deep charcoal canvas, one luminous teal
> accent, data on dark.

| Role | Hex |
|------|-----|
| bg | `#0E1116` |
| surface | `#161B22` |
| text | `#E6EDF3` |
| muted | `#8B97A6` |
| border | `#2A323D` |
| accent | `#4CC6C0` (luminous teal) |
| accent-2 (secondary) | `#A78BFA` (violet — used for LLM calls / upvert) |

- **Font stack:** `"Inter", "Helvetica Neue", Arial, system-ui, sans-serif`;
  monospace `"SF Mono", ui-monospace, "JetBrains Mono", "Roboto Mono", Menlo,
  Consolas, monospace`.
- **Radius:** `8px` (soft, modern instrument panel).
- **Motif:** restrained glow on live/active elements only (running FSM, primary
  CTA, current state node); subtle radial light wash; color-coded call log
  (teal GET, violet LLM, green POST).
- **Signal / personality:** focused, premium, "pro tool at night." Attention is
  pulled to the work; glow marks what is live. This is the recommended idiom for
  creative/developer tooling.
- **Best-suited user:** the **product designer / prototyper in flow** who keeps
  the app open all day, often beside a dark IDE; demo-facing work where the
  rendered prototype should pop against a quiet chrome.
- **Contrast notes:** body text `#E6EDF3` on `#161B22` ≈ 13:1; muted `#8B97A6`
  on `#161B22` ≈ 5.3:1; accent `#4CC6C0` on `#0E1116` ≈ 8.4:1. Primary buttons
  use dark ink `#04201E` on the teal fill (high contrast) rather than white.

---

## Theme C — Paper

> Editorial, warm-sketch. Off-white paper, ink lines, a marker-warm accent that
> echoes the low-fi wireframe origin.

| Role | Hex |
|------|-----|
| bg | `#F3EDE1` |
| surface | `#FBF7EE` |
| text | `#2B2620` |
| muted | `#7A6F5D` |
| border | `#D8CCB4` |
| accent | `#C8553D` (warm marker/terracotta) |
| accent-2 (secondary) | `#3D7D74` (muted teal — DSL types / GET calls) |

- **Font stack:** serif `"Iowan Old Style", "Palatino Linotype", Palatino,
  "Hoefler Text", Georgia, "Times New Roman", serif` for headings/body; a
  casual stack `"Comic Sans MS", "Marker Felt", "Bradley Hand", "Segoe Print",
  cursive` for hand-written annotations (inspector hints, footnotes); monospace
  `"Courier New", ui-monospace, Courier, monospace` for source/tokens.
- **Radius:** `6px`, with offset hard shadows and a slight canvas tilt to keep
  the sketch spirit.
- **Motif:** ink borders, paper grain (dotted background), offset drop shadows
  like stacked paper, marker-colored handwritten callouts — a direct nod to the
  Balsamiq wireframe lineage the product grew out of.
- **Signal / personality:** approachable, human, low-pressure. Says "this is a
  sketch you can play with," which lowers the stakes of early ideation.
- **Best-suited user:** **founders, PMs, and non-designers** sketching ideas to
  validate; workshop / classroom settings; anyone who finds dense dev tooling
  intimidating and responds to a warmer, editorial surface.
- **Contrast notes:** body text `#2B2620` on `#FBF7EE` ≈ 13:1; muted `#7A6F5D`
  on `#FBF7EE` ≈ 4.6:1; accent `#C8553D` on `#FBF7EE` ≈ 4.6:1 — meets AA for
  body text. (The cursive annotation stack is decorative; keep critical text in
  serif/sans.)

---

## Recommendation — lead with Theme B, Nocturne

**Lead with Nocturne, and ship Blueprint and Paper as switchable alternate
skins.**

Rationale:

1. **Audience fit.** TRFI's core daily user is a designer/developer prototyping
   for hours at a time, frequently alongside a code editor. The dark-native
   instrument is the genre-correct default for creative dev tooling and the most
   comfortable for long sessions.
2. **The product's own pitch.** TRFI is about a low-fi → hi-fi reveal and a
   "fake it convincingly" live demo. A quiet charcoal chrome makes the rendered
   *prototype* the brightest thing on screen, and the restrained glow gives a
   natural, honest signal for what's **live** (running FSM, active state, real
   API/LLM calls) — directly serving the Prototype Player's job.
3. **Brand resonance.** "The Robot Fakes It" carries a slightly nocturnal,
   uncanny tone; the luminous-on-dark instrument reinforces it without gimmicks.
4. **It's also the most defensible default** because TRFI is itself a theming
   engine: the three themes double as a built-in demonstration that the same
   screens re-skin from `theme.yaml` seeds. Nocturne as the shell, with
   one-click Blueprint (precision/enterprise) and Paper (approachable/ideation)
   as proof, turns the chrome into a live advertisement for the feature.

Sequencing: build the token set so all three are the *same* generated-CSS
pipeline with different seed values — that keeps the recommendation cheap to
honor and dogfoods the engine.
