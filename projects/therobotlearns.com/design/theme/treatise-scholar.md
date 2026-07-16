---
slug: scholar
base_theme: theme-style-guide
status: sketch
revision: 1
---

# Theme Treatise — Scholar

Theme: `theme-scholar/` · Base: `theme-style-guide` · Status: sketch

> **Reverse-engineered** from the shipped `theme-scholar/` YAML (Stage A) — the treatise
> justifies the on-disk values and flags anything arbitrary. **Surface note:** the product is
> a terminal agent; Stage C renders Scholar onto a mocked terminal, and it is also the theme
> assigned to the one true browser page (`07-quiz-spa`) — the cleanest, most web-legible of
> the rendered set.

## 1. Identity

- **Intent:** Equip curious minds with a structured, AI-powered knowledge system that grows
  with them — a competent, precise default that respects the user's time and attention.
- **Perception:** "Precise, intelligent, trustworthy — a well-organized personal wiki." No
  flourish, no friction; the tool recedes and the knowledge is foreground.
- **Audience:** Developers, engineers, and technical professionals who learn continuously and
  expect a clean, keyboard-fast tool.
- **Tone:** Direct, knowledgeable, quietly confident (from `branding.yaml` verbatim).
- **Keywords:** knowledge, precision, mastery, structured, intelligent
- **Relationship to base:** inherits `theme-style-guide` structure and its neutral gray ramp.
  The delta is a near-white monochrome foundation with a single indigo accent and a crisp 4px
  radius. Sibling to `deep-focus` (both neutral, sans-only, developer-facing); Scholar splits
  off by being **light-native and indigo**, where deep-focus is dark-native and teal. It is
  the project's "competent workhorse" direction — the safe default for dense admin surfaces.

## 2. References & Anchors

- **Anchor — Linear / Vercel dashboard minimal:** borrow the near-white canvas + single-accent
  discipline and the thin-bordered, keyboard-fast surface density.
- **Anchor — Tailwind UI defaults:** the semantic palette (`#22c55e`/`#eab308`/`#ef4444`/
  `#3b82f6`) is drawn straight from that lineage — proven, legible, unsurprising.
- **Anchor — Stripe / technical documentation sites:** borrow the "precision as aesthetic"
  register — restrained type, generous but not lavish spacing, one confident accent.
- **Anti-reference — warm editorial serif reading themes (this project's `atlas`):** Scholar
  is sans-only and neutral; no serif, no contemplative warmth — it is a *tool*, not a journal.
- **Anti-reference — playful rounded consumer UI (this project's `spark`):** the 4px radius is
  crisp, not friendly-round; there is no delight-motion budget and no pastel warmth.
- **Anti-reference — heavy-ornament dashboards:** no gradients, no decorative shadows, no
  texture; every non-content pixel must earn its place.

## 3. Color Story

- **Temperature & register:** Neutral and light-primary. The foundation is a near-true-gray
  monochrome (`#fafafa` canvas, `#111118` ink); the single saturated element is indigo.
- **Hue relationships:** Neutral monochrome + one indigo accent `#6366F1` (≈239°). The `blue`
  seed `#3B82F6` serves semantic info, not a second brand hue — accent count stays at one.
- **Neutral strategy:** Near-pure gray with a faint cool cast. The gray ramp
  (`gray-50…gray-700`) is **inherited from `theme-style-guide`, not redefined here** — Scholar's
  own `vars.yaml` defines only the white/black/accent/semantic seeds. *Honest flag:* the
  color-modes file references `var(--gray-*)`, `var(--yellow-light)`, `var(--red-light)` that
  resolve through the base theme; a fine-tuner changing neutrals must edit the base or add
  local overrides, not expect them in this theme's vars.
- **Semantic mapping:** Standard modern-web set — success `#22c55e`, warning `#eab308`, error
  `#ef4444`, info `#3b82f6`. They harmonize with the indigo accent while staying clearly
  distinct: error red `#ef4444` (≈0°) is far from indigo (≈239°), so "error" never reads as
  "brand." Collision rule: indigo is reserved for interactive/brand emphasis and must not be
  used to signal a semantic state.
- **Contrast stance:** Crisp and high throughout — Scholar has no soft register. Ink `#111118`
  on `#fafafa` ≈ 17:1; borders are thin but visible (`gray-200`), because this theme *does*
  use lines for structure (unlike deep-focus's tonal layering).
- **Mode strategy:** **Light is primary and the design target.** A dark mode exists as a
  faithful translation (canvas `#111118`, text `#e4e4ec`, indigo lightened to `#818CF8` for
  contrast) but gets no independent design. No high-contrast mode in v1 — light-mode contrast
  already clears AA with wide margin.

## 4. Typographic Voice

- **Families:** UI sans is Inter (neutral geometric, high x-height, disappears into the work);
  code/data mono is JetBrains Mono. Rationale: Inter is the genre-default "precise, modern"
  face precisely because it is unopinionated — the theme's confidence comes from restraint,
  not letterform character. No serif, no display face.
- **Scale character:** Tight-to-moderate, ≈1.2–1.25 ratio. Headings step by size and weight;
  the largest working-screen heading stays ≤2× body.
- **Weight usage:** 400 body, 500 UI labels/emphasis, 600 headings and active items. 700 is
  reserved for the wordmark. Never bold paragraphs.
- **Rhythm:** Body line-height ≈1.6; mono ≈1.5. Measure ≈70–75ch in docs panes. Mono appears
  for code, IDs, and literal values only.

## 5. Space & Density

- **Spacing philosophy:** 8px base unit (inherited). Moderate — generous enough to read as
  clean, tight enough for dense admin tables and settings forms. Whitespace is a tool, not a
  luxury.
- **Density target:** Reference screen is the settings/quiz-runner surface: a form or a
  question list with clear grouping, several fields or items per viewport without crowding.
  Denser than deep-focus's reading layout, far looser than cockpit.
- **Responsive stance:** Under width pressure, multi-column forms stack to one column and
  secondary metadata truncates; label legibility and tap-target size are protected.

## 6. Shape & Surface

- **Radius language:** 4px base — crisp-soft, the "competent default." Applies to cards,
  inputs, buttons; no pills, no sharp 0.
- **Borders:** Visible and structural — thin gray borders (`gray-200`/`gray-300`) delineate
  cards, inputs, and table rows. Scholar earns clarity from lines, not shadow.
- **Elevation:** Minimal — a single soft shadow (`rgba(0,0,0,0.06)`) for raised menus/modals;
  most surfaces sit flat, separated by borders and the `gray-50` alt surface.
- **Texture & gradient policy:** None — no gradients, no texture, no glow. Precision reads as
  flatness plus crisp borders.

## 7. Motion & Feedback

- **Animation character:** Subtle and instrumental — motion confirms an action, nothing more.
- **Duration & easing:** Micro-feedback 80–120ms ease-out; transitions ≤200ms; nothing
  exceeds 250ms. No spring/bounce, no scroll-triggered motion.
- **Interaction states:** Hover shifts surface to `gray-50` or lightens the border; active
  presses subtly; focus is a 2px indigo ring (`rgba(99,102,241,0.35)`); disabled drops to
  ~45% and removes hover affordance. State never rests on the indigo hue alone — it pairs with
  border/background change.

## 8. Component Inflections

- **Buttons:** Primary is an indigo fill with white text — the one saturated element on a
  screen; secondary is a bordered ghost on the surface. Destructive uses semantic error red as
  a bordered ghost that fills only on hover.
- **Inputs:** Bordered fields on the surface (not recessed), 4px radius; focus swaps the gray
  border for the indigo ring. Placeholder at the 4.5:1 floor.
- **Cards:** Bordered surfaces, 4px radius, `gray-50` header zones where grouping helps; the
  workhorse container for admin and settings content.
- **Navigation:** A left rail or top bar with the active item marked by indigo text/underline +
  600 weight; no filled active backgrounds beyond a subtle `surface-accent` tint.
- **At base defaults (deliberately untouched):** toasts, breadcrumbs, tables' base structure,
  and modal shells inherit `theme-style-guide` with the indigo tokens applied.

## 9. Accessibility Commitments

- **WCAG target:** 2.2 AA across both modes; body text clears AAA in light mode by a wide
  margin.
- **Contrast minimums:** Ink `#111118` on `#fafafa` ≈ 17:1. **Near-the-line pair the fine-
  tuner must verify: indigo accent `#6366F1` as text/icon on white ≈ 4.6:1 — just over the
  AA body floor; do not lighten the accent or the canvas without rechecking, and prefer the
  `text-link #4f46e5` (≈5.9:1) for indigo body text.** In dark mode, indigo lightens to
  `#818CF8` — verify ≈ 6:1 on `#111118`.
- **Focus visibility:** 2px indigo ring on every focusable element; against white it exceeds
  3:1. Never removed, only restyled.
- **Reduced motion:** `prefers-reduced-motion` drops transitions over 100ms to instant; hover
  border/background changes survive as immediate swaps.

## 10. Facet Mapping Appendix

| Treatise section | Engine facet | Seed hints |
|---|---|---|
| §1 | `branding.yaml` | name "The Robot Learns" (Scholar); intent/perception/audience/tone verbatim; keywords: knowledge, precision, mastery, structured, intelligent |
| §3 neutrals | `style-guide.vars.yaml` Surfaces + base gray ramp | white `#fafafa`, black `#111118`; gray ramp inherited from `theme-style-guide` (not local) |
| §3 accent | `style-guide.vars.yaml` Brand | single indigo `#6366F1`; `blue #3B82F6` serves info |
| §3 semantics | `style-guide.vars.yaml` Semantic | success `#22c55e`, warning `#eab308`, error `#ef4444`, info `#3b82f6` |
| §3 modes | `style-guide.color-modes.yaml` | light primary (canvas `#fafafa`); dark: canvas `#111118`, text `#e4e4ec`, indigo `#818CF8`, link `#4f46e5`/`#818CF8` |
| §4 | `style-guide.vars.yaml` Typography | font-sans `'Inter', -apple-system, sans-serif`; font-mono `'JetBrains Mono', 'Fira Code', monospace`; ~1.2–1.25 scale |
| §5 | `style-guide.vars.yaml` Layout | 8px unit; moderate density; ~70–75ch measure |
| §6 | `style-guide.vars.yaml` radius + `style-guide.css-snippets.yaml` | radius `4px`; thin structural borders; single soft shadow for overlays |
| §7 | `style-guide.scoped-vars.yaml` | `--motion-micro: 100ms` ease-out; reduced-motion guard |
| §8 | `style-guide.semantic-classes.yaml` | indigo primary fill, bordered inputs/cards, indigo-underline active nav |
| §9 | verification across facets | recheck indigo `#6366F1` as body text (~4.6:1) and `#818CF8` dark-mode pairing |
