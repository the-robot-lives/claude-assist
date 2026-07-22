# Typography & Rhythm for Tuning

> Scale ratios, weight axes, line rhythm, and spacing cadence as they map onto engine vars — `font-sans`/`font-mono` seeds, `typography-classes`, and the spacing facets. Deliberately duplicated theory (adapted from the UX Engineer's references) so this skill stands alone; framed entirely as "which YAML value do I move, and how far."

---

## 1. What the Seeds Do vs What the Facet Does

- **Seeds** (`vars.yaml` Typography group): `font-sans`, `font-mono` — the families. The cascade derives the full size scale (`--font-size-xs` … `--font-size-display`) and base line-heights from defaults.
- **Facet** (`style-guide.typography.yaml`): documents families (`typography[]`) and defines the rendered type classes (`typography-classes[]`) — size, weight, line-height, letter-spacing, transform per class. Ship it only when the treatise's scale character deviates from the base (replace semantics: ship the FULL class list).
- **Loading** (`branding.yaml` `font-url`): families and weights must match the seeds or you silently render fallbacks. Every weight referenced by a `typography-class` must appear in the `font-url`.

```yaml
# branding.yaml (excerpt)
font-url: "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap"
```

## 2. Scale Ratios

A type scale multiplies a base size by a constant ratio per step. The ratio IS the
personality — treatises pin it ("tight tooling scale, ~1.2").

| Ratio | Name | Character | Typical use |
|---|---|---|---|
| 1.125 | major second | very tight, dense | data-heavy tools, terminals |
| 1.2 | minor third | tight, calm | dev tools, dashboards (ember's choice) |
| 1.25 | major third | balanced | product UI default |
| 1.333 | perfect fourth | editorial confidence | content sites, docs |
| 1.5 | perfect fifth | dramatic | marketing, landing |
| 1.618 | golden | display-first | hero-driven brands |

With base 16px and ratio 1.2: 16 → 19.2 → 23 → 27.6 → 33.2 → 39.8. The engine's derived
`--font-size-*` scale approximates a mid-range ratio; encode a deviating ratio by
pointing `typography-classes` at the derived tokens that best match your steps — or, for
strongly non-default scales, overriding size tokens in a vars group.

**Tuning heuristics:**

- "Headings feel shouty" → drop one ratio step (or one token step per class), don't shrink body.
- Body size is load-bearing: 16px minimum for reading UIs, 13-14px acceptable only for dense data with generous line-height.
- A tight ratio (≤1.2) NEEDS weight/spacing/case differentiation (§3 below) because size alone no longer separates levels.

## 3. Weight Axes and Reservation

Weights are a vocabulary; a treatise reserves each ("400 body, 500 emphasized labels,
600 headings, 700 wordmark only"). Encode reservations directly in `typography-classes`
and never exceed them in snippets:

```yaml
# style-guide.typography.yaml (excerpt — ember §4)
typography:
  - var: font-sans
    name: "Inter"
    description: "Neutral, high x-height; the theme's personality lives in color, so type stays instrumental."
    usage: "All UI text: headings, body, labels"
    weights: [400, 500, 600, 700]
  - var: font-mono
    name: "JetBrains Mono"
    description: "Holds up at 13px/400 on dark surfaces."
    usage: "Code, literal values, IDs, timestamps — never headings or prose"
    weights: [400, 500]

typography-classes:
  - name: H1
    class: typography-h1
    font-family: "var(--font-sans)"
    font-size: "var(--font-size-2xl)"     # tight scale: largest working heading ≤ 2× body
    font-weight: "600"                     # §4: 600 = headings; 700 reserved for wordmark
    line-height: "1.2"
    letter-spacing: "-0.01em"
  - name: Body
    class: typography-body
    font-family: "var(--font-sans)"
    font-size: "var(--font-size-md)"
    font-weight: "400"
    line-height: "1.6"                     # §4 rhythm
  - name: Label
    class: typography-label
    font-family: "var(--font-sans)"
    font-size: "var(--font-size-xs)"
    font-weight: "500"                     # §4: 500 = emphasized UI labels
    line-height: "1.4"
    letter-spacing: "0.06em"
    text-transform: "uppercase"
  - name: Code
    class: typography-code
    font-family: "var(--font-mono)"
    font-size: "var(--font-size-sm)"
    font-weight: "400"
    line-height: "1.5"                     # §4: mono blocks 1.5
```

**Dark-mode weight note:** light-on-dark text renders optically bolder (glow spreads
strokes). Dark-first themes often step DOWN a weight vs their light counterparts, or use
`-webkit-font-smoothing: antialiased` in a snippet — check headings in both modes before
concluding a weight is wrong.

## 4. Line Rhythm

Line-height is inversely proportional to line length and size:

| Context | line-height | Notes |
|---|---|---|
| Display/H1 | 1.05-1.2 | large sizes need tighter leading or they float apart |
| Working headings | 1.2-1.35 | |
| UI text, buttons, labels | 1.4-1.5 | |
| Body copy | 1.5-1.65 | pair with measure ≤ 70-75ch |
| Long-form reading | 1.65-1.8 | |
| Code blocks | 1.4-1.6 | mono needs a touch more than UI text |

Letter-spacing pairs with size: negative at display sizes (-0.02em region), zero at
body, positive on small caps/labels (+0.04-0.08em). All of these are per-class fields in
`typography-classes` — no snippet needed.

Measure ("~70ch in docs panes") is a layout concern → `page-layouts.yaml`:

```yaml
page-layouts:
  - name: docs
    title: Docs
    description: "Reading pane — measure-capped column"
    selector: ".content.docs"
    vars:
      max-width: "70ch"
      padding: "var(--space-6)"
      margin: "0 auto"
      body-bg: "var(--surface)"
      content-bg: "var(--surface-alt)"
```

## 5. Spacing Cadence as Vars

The engine derives a 4/8px-based `--space-*` scale; treatises tune its **application**,
not usually the scale itself:

- **Density philosophy** ("padding inside cards, not between them") → component vars/snippets: card padding `var(--space-4)`-`var(--space-6)`, grid gaps `var(--space-2)`-`var(--space-3)`.
- **Grid/container/rhythm** → `spacing.yaml` `spacing-contexts` (grid columns + gutter token, page max-width + padding tokens, section-spacing roles).
- **Vertical rhythm coherence:** section gaps > component gaps > element gaps, each roughly 2× the next (e.g. space-8 / space-4 / space-2). If a served page feels "arrhythmic," check for values that break this geometric ordering before inventing new tokens.

```yaml
# style-guide.spacing.yaml (only when §5 deviates from base)
spacing-contexts:
  grid:
    columns: 12
    gutter-token: space-3        # ember: tight gutters (§5 "surfaces sit close")
    margin-token: space-5
  page-container:
    max-width: "1440px"          # §5 reference screen: 1440×900 dashboard
    padding-x-token: space-5
    padding-y-token: space-4
  section-spacing:
    - role: "Major section gap"
      token: space-8
    - role: "Component gap"
      token: space-3
    - role: "Element gap"
      token: space-2
```

## 6. Worked Example: "Headings Feel Weak in Dark Mode"

Complaint on served ember theme: H2s don't separate from body in dark mode. Treatise
constraints: §4 tight 1.2 scale ("headings distinguish by weight and spacing more than
size"), 600 max working weight, largest heading ≤ 2× body.

Diagnosis order (cheapest first):

1. **Fonts actually loading?** Check the network panel / computed font-family — a missing 600 in `font-url` renders faux-bold or 400. (Common; this was the bug half the time.)
2. **Optical weight in dark mode** — if 600 loads but reads thin, add tracking and spacing rather than size: `letter-spacing: -0.005em → 0`, and increase space-above via the class or section rhythm.
3. **Size step** — only if 1 and 2 fail AND the treatise's "≤ 2× body" ceiling permits, move H2 one token step (`--font-size-xl` → `--font-size-2xl`).

Fix applied (case 1 + a spacing polish):

```yaml
# branding.yaml — 600 was missing from the loaded weights
font-url: "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap"
```

Re-serve, verify both modes, note in conformance: "H2 weakness was unloaded 600 weight;
scale and weights unchanged, §4 intact."
