# Theme Treatise — {Theme Name}

<!-- Save as: projects/{domain}/design/theme/treatise-{slug}.md (sibling of theme-{slug}/) -->
<!-- Spec + worked example: references/outputs/theme-treatise.md -->
<!-- Rule of thumb: every claim must be decidable by the fine-tuner — attach a range, a measurable, an exclusion, or a named tradeoff winner. No bare adjectives. -->

Theme: `theme-{slug}/` · Base: {base theme, e.g. theme-style-guide, or "none"} · Status: {draft | ready for fine-tuning}

## 1. Identity

<!-- Mirrors branding.yaml — write these so extraction is copy-paste. -->

- **Intent:** {What the design does — the philosophy, 1-2 sentences}
- **Perception:** {What the user should feel in the first five seconds}
- **Audience:** {Who this is for and the context they arrive in}
- **Tone:** {Voice and communication style}
- **Keywords:** {4-6 words the theme must evoke — these seed branding.yaml keywords}
- **Variant note:** {Variants only: name the base, what splits this variant off, what it inherits unchanged, and the one-sentence delta. Delete for standalone themes.}

## 2. References & Anchors

<!-- 2-4 anchors, 1-3 anti-references. Each anchor names WHAT to borrow; each anti-reference names the specific quality being rejected. Anti-references are required. -->

- **Anchor — {product/site/style spec}:** {what specifically to borrow}
- **Anchor — {…}:** {…}
- **Anti-reference — {…}:** {the specific quality being rejected, not just the name}

## 3. Color Story

- **Temperature & register:** {warm/cool/neutral; muted/saturated; hue-degree bands if pinnable}
- **Hue relationships:** {monochrome + accent / analogous / complementary; which hue dominates; accent value or tight range}
- **Neutral strategy:** {pure gray vs tinted; if tinted, toward which hue and how much; white/black seed values if pinned}
- **Semantic mapping:** {how success/warning/error/info are chosen — harmonize vs break from brand; collision rules, e.g. "warning must be distinguishable from the accent"}
- **Contrast stance:** {soft vs crisp; target ratios for body/secondary/chrome; where subtlety is allowed and where it is forbidden}
- **Mode strategy:** {which of light/dark/high-contrast exist; which is primary; are non-primary modes faithful translations or distinct designs? Cover all three even if the answer is "does not exist in v1"}

## 4. Typographic Voice

- **Families:** {sans/serif/mono choices + why each — what the letterforms signal; fallback stacks}
- **Scale character:** {tight vs dramatic; approximate ratio; max heading-to-body size on a working screen}
- **Weight usage:** {which weights exist and what each is reserved for}
- **Rhythm:** {line-heights, measure cap, where mono appears — and where it never does}

## 5. Space & Density

- **Spacing philosophy:** {base unit; where padding is spent — inside surfaces vs between them}
- **Density target:** {the reference screen and how much it holds per viewport, e.g. "6-8 status cards + log pane at 1440×900 without scrolling"}
- **Responsive stance:** {what compresses first under width pressure; what is protected}

## 6. Shape & Surface

- **Radius language:** {base radius, exceptions, maximum; sharp/soft/pill}
- **Borders:** {visible structural borders vs tonal separation; where borders are permitted}
- **Elevation:** {shadow vs tonal layering; number of elevation steps; overlay shadow character}
- **Texture & gradient policy:** {allowed at all? If yes, exactly where and how restrained; if no, say so explicitly}

## 7. Motion & Feedback

- **Animation character:** {instrumental vs expressive; what motion is FOR in this theme; any sanctioned exceptions}
- **Duration & easing:** {timing bands in ms for micro/hover/panel; easing family; hard ceiling}
- **Interaction states:** {how hover/active/focus/disabled read; which channels carry state — color, elevation, motion, outline; never rely on hue alone}

## 8. Component Inflections

<!-- Minimum coverage: buttons, inputs, cards, navigation. 1-3 sentences each on what makes this theme's version distinct. -->

- **Buttons:** {…}
- **Inputs:** {…}
- **Cards:** {…}
- **Navigation:** {…}
- **At base defaults (deliberately untouched):** {list the components inherited unchanged — say you're skipping them}

## 9. Accessibility Commitments

<!-- Non-negotiables the fine-tuner must verify, not aspire to. -->

- **WCAG target:** {2.2 AA minimum; state anything stricter and for what}
- **Contrast minimums:** {4.5:1 body, 3:1 large/UI; list known near-the-line pairs with approximate ratios to recheck after seed changes}
- **Focus visibility:** {what the focus indicator is; its contrast guarantee against every surface step}
- **Reduced motion:** {what prefers-reduced-motion disables; what survives and in what form}

## 10. Facet Mapping Appendix

<!-- Advisory summary, written LAST. Every row must trace to a decision in §1-§9 — if a row surfaces a new decision, move it into the body first. Cover every facet the theme overrides. -->

| Treatise section | Engine facet | Seed hints |
|---|---|---|
| §1 | `branding.yaml` | {name, intent/perception/audience/tone/keywords verbatim; font-url} |
| §3 neutrals | `style-guide.vars.yaml` Surfaces | {white/black seeds} |
| §3 accent | `style-guide.vars.yaml` Brand | {brand hex seed(s)} |
| §3 semantics | `style-guide.vars.yaml` Semantic | {success/warning/error/info seeds or ranges} |
| §3 modes | `style-guide.color-modes.yaml` | {per-mode surface/text/border tokens} |
| §3 narrative | `style-guide.color-palette.yaml` | {swatch groups + usage rules} |
| §4 | `style-guide.vars.yaml` Typography + `style-guide.typography.yaml` | {font stacks, scale notes} |
| §5 | `style-guide.vars.yaml` Layout + `style-guide.spacing.yaml` | {unit, density notes} |
| §6 | `style-guide.vars.yaml` radius + `style-guide.css-snippets.yaml` | {radius; shadow/border/gradient snippets} |
| §7 | `style-guide.css-snippets.yaml` / `style-guide.scoped-vars.yaml` | {duration/easing custom props; reduced-motion guard} |
| §8 | `style-guide.css-snippets.yaml` + `style-guide.semantic-classes.yaml` | {per-component overrides} |
| §9 | verification pass, all facets | {contrast pairs to recheck} |

> For fine-tuning a treatise into engine YAML, see **trl-theme-designer** — it consumes this document format.
