---
slug: atlas
base_theme: theme-style-guide
status: sketch
revision: 1
---

# Theme Treatise — Atlas

Theme: `theme-atlas/` · Base: `theme-style-guide` · Status: sketch

> **Reverse-engineered** from the shipped `theme-atlas/` YAML (Stage A). **Render-deferral
> note:** Atlas is a typography-first, long-form *reading page* — the least terminal-natural
> of this project's directions. In a terminal-first product (19/20 screens are TUI surfaces),
> it is treatise-only for this render pass (`status: deferred` in `stage_c.themes`) and can
> render later if a browser-page surface or added screens justify it. The design intent below
> is captured in full regardless.

## 1. Identity

- **Intent:** Create a contemplative reading environment where knowledge feels weighty and
  worthwhile — content as the hero, set like a beautifully typeset journal.
- **Perception:** "Authoritative, thoughtful, crafted — a beautifully typeset textbook or
  journal." Depth over speed.
- **Audience:** Lifelong learners, researchers, and professionals who value depth over speed.
- **Tone:** Measured, articulate, unhurried — the voice of a well-curated library.
- **Keywords:** editorial, depth, authority, craftsmanship, contemplative
- **Relationship to base:** inherits `theme-style-guide` (light-tier: 4 files, no
  css-snippets/typography.yaml). The delta is a serif-first editorial voice, a warm paper
  palette, a burnt-amber accent, and a near-sharp 2px radius. Distinct from the sans developer
  themes (`scholar`, `deep-focus`) by leading with *serif reading*, not UI efficiency.

## 2. References & Anchors

- **Anchor — a university-press book / literary journal:** borrow the generous margins, the
  serif body, and the discipline of one measured column of text.
- **Anchor — editorial reading apps in serif mode (Readwise Reader, iA):** borrow the "text is
  the interface" restraint — chrome recedes almost entirely.
- **Anchor — classic newspaper editorial typography:** borrow the high-contrast display serif
  (Fraunces) over a readable body serif (Source Serif 4).
- **Anti-reference — a sans developer tool (this project's `scholar`):** Atlas is serif and
  contemplative; a neutral geometric sans would erase its entire character.
- **Anti-reference — playful rounded consumer UI (`spark`):** the 2px radius is nearly sharp;
  nothing here is bubbly or celebratory.
- **Anti-reference — a dense dashboard:** Atlas protects whitespace and reading measure over
  information density every time they conflict.

## 3. Color Story

- **Temperature & register:** Warm and light-primary, muted. Neutrals are warm stone
  (`#faf8f5` paper, `#1c1917` ink); saturation is low and reserved.
- **Hue relationships:** A warm-paper neutral base + a burnt-amber accent `#b45309` (≈30°) and
  a deep editorial blue `#1e40af` for links/info — a restrained two-accent editorial pairing,
  amber for emphasis, blue for reference.
- **Neutral strategy:** Warm stone, tinted toward the amber/brown family (`#faf8f5`,
  `#f5f0ea`, borders `#e7e5e4`/`#d6d3d1`, ink `#1c1917`). Pure gray never appears.
- **Semantic mapping:** Traditional and muted — success `#15803d`, warning `#a16207`, error
  `#b91c1c`, info `#1d4ed8`. Deep, print-like tones that sit quietly against paper rather than
  alarming. Error `#b91c1c` is a deep true-red, clearly distinct from the burnt-amber accent.
- **Contrast stance:** High for text (ink on paper ≈ 15:1), soft for chrome — borders whisper,
  because a reading page earns structure from typography and space, not lines.
- **Mode strategy:** **Light is primary and the design target** — a bright paper page. A dark
  mode exists as a faithful translation (canvas `#1c1917`, text `#e7e5e4`, accent shifts to
  `#d97706`, links to `#93c5fd`) but gets no independent design. No high-contrast mode in v1.

## 4. Typographic Voice

- **Families — the defining trait:** the body/`font-sans` slot is a **serif stack**
  (`'Source Serif 4', 'Georgia', serif`) — Atlas reads in serif, not sans. Display is Fraunces
  (`'Fraunces', 'Georgia', serif`), a high-contrast display serif for headings; code is IBM
  Plex Mono. There is **no sans-serif anywhere** — a rare, deliberate commitment.
- **Scale character:** Editorial with dramatic display jumps — Fraunces headings are large and
  high-contrast against the calm body; approximate ratio ≈1.3+ at the display end.
- **Weight usage:** Body 400 with 600 for emphasis; Fraunces display carries weight and optical
  size. Restraint: emphasis is italic or small-caps before it is bold.
- **Rhythm:** Generous body line-height (≈1.7) and a protected reading measure (≈65–70ch). Mono
  appears only for code and literal values — never headings or running text.

## 5. Space & Density

- **Spacing philosophy:** Generous and unhurried — wide margins, ample paragraph spacing; the
  page breathes like a printed book.
- **Density target:** Reference screen is the knowledge-article viewer: a single centered column
  of long-form prose with a slim contents rail — low density by design, one idea in view.
- **Responsive stance:** Under width pressure, the contents rail drops and margins narrow; the
  reading measure and body size are protected absolutely — legibility of long text is the whole
  point.

## 6. Shape & Surface

- **Radius language:** `2px` — nearly sharp, an editorial restraint (like a fine printed rule).
  Applies uniformly; no pills, no soft cards.
- **Borders:** Thin warm hairlines (`#e7e5e4`, `border-strong #d6d3d1`) used sparingly; a burnt-
  amber `border-accent #b45309` marks only emphasized dividers/pull-quotes.
- **Elevation:** Minimal — print is flat. A single faint shadow (`rgba(28,25,23,0.06)`) for the
  rare raised element (menus); most surfaces sit flat on paper.
- **Texture & gradient policy:** None — clean paper. No gradients, no texture; craftsmanship
  reads as impeccable type and spacing, not ornament.

## 7. Motion & Feedback

- **Animation character:** Minimal and dignified — motion is nearly absent; a reading page does
  not perform.
- **Duration & easing:** Transitions 150–250ms ease-in-out; no bounce, no scroll-triggered
  motion. Page turns and reveals are quiet.
- **Interaction states:** Hover underlines links (editorial convention) and lightens buttons;
  active presses subtly; focus is a 2px accent-blue ring (`rgba(30,64,175,0.3)`); disabled
  drops to ~45%. Link underlines carry emphasis, never color alone.

## 8. Component Inflections

- **Buttons:** Restrained — a solid burnt-amber primary and a hairline-bordered secondary; text
  is the serif body face, never shouty. Buttons are the quiet servant of the reading.
- **Inputs:** Simple bordered fields on paper, 2px radius; focus swaps to the blue ring. Rare in
  this reading-first theme.
- **Links — the star component:** editorial underlined links in accent blue `#1e40af`; the most
  expressive interactive element, since a reading tool is mostly text-and-links.
- **Cards:** Minimal — a hairline border or a faint alt-surface (`#f5f0ea`) tint; no shadow.
  Used for pull-quotes and contents, not as dominant chrome.
- **Navigation:** A slim contents rail with the active section in 600 weight + amber marker; no
  filled backgrounds.
- **At base defaults (deliberately untouched):** toasts, modals, breadcrumbs inherit
  `theme-style-guide` with warm-paper tokens.

## 9. Accessibility Commitments

- **WCAG target:** 2.2 AA; body reading text clears AAA on paper by a wide margin.
- **Contrast minimums:** Ink `#1c1917` on `#faf8f5` ≈ 15:1. Near-the-line pairs to verify:
  **burnt-amber `#b45309` as text on paper ≈ 4.9:1 (just over AA — do not lighten), warning
  `#a16207` ≈ 4.6:1 (label/large preferred), text-muted `#a8a29e` ≈ 2.6:1 — decorative only.**
  Link blue `#1e40af` ≈ 8:1 (safe). In dark mode verify amber `#d97706` and link `#93c5fd` on
  `#1c1917`.
- **Focus visibility:** 2px accent-blue ring on every focusable element; clears 3:1 on paper.
  Never removed.
- **Reduced motion:** `prefers-reduced-motion` drops the few transitions to instant; nothing
  essential is motion-dependent.

## 10. Facet Mapping Appendix

| Treatise section | Engine facet | Seed hints |
|---|---|---|
| §1 | `branding.yaml` | name "The Robot Learns" (Atlas); intent/perception/audience/tone verbatim; keywords: editorial, depth, authority, craftsmanship, contemplative |
| §3 neutrals | `style-guide.vars.yaml` Surfaces | white `#faf8f5`, black `#1c1917` (warm stone); alt `#f5f0ea` |
| §3 accents | `style-guide.vars.yaml` Brand | burnt-amber `#b45309` (emphasis) + editorial blue `#1e40af` (links/info) |
| §3 semantics | `style-guide.vars.yaml` Semantic | success `#15803d`, warning `#a16207`, error `#b91c1c`, info `#1d4ed8` |
| §3 modes | `style-guide.color-modes.yaml` | light primary (paper `#faf8f5`); dark: canvas `#1c1917`, text `#e7e5e4`, accent `#d97706`, link `#93c5fd` |
| §4 | `style-guide.vars.yaml` Typography | font-sans = SERIF `'Source Serif 4', 'Georgia', serif`; display `'Fraunces', serif`; mono `'IBM Plex Mono', monospace`; ~1.3+ display ratio, ~1.7 body line-height |
| §5 | `style-guide.vars.yaml` Layout | generous margins; ~65–70ch measure; low density |
| §6 | `style-guide.vars.yaml` radius | radius `2px`; hairline borders; single faint shadow |
| §7 | `style-guide.scoped-vars.yaml` | `--motion: 200ms` ease-in-out; reduced-motion guard |
| §8 | `style-guide.semantic-classes.yaml` | amber primary button, underlined editorial links (star), minimal cards, amber-marker active nav |
| §9 | verification across facets | recheck amber `#b45309`/`#a16207` as text; muted `#a8a29e` decorative-only |
