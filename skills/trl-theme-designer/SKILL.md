---
name: trl-theme-designer
description: >-
  Tunes styleguide-engine theme YAML from a treatise: extracts vars, writes inheritance/delta
  facets and dark modes, and fixes WCAG contrast or drift. Use for theme YAML, design-token
  seeds, theme-{slug}, vars.yaml, color-modes, or treatise conformance.
extended_description: >
  Fine-tune styleguide-engine themes: turn a theme treatise into tuned theme YAML — seed
  extraction into vars.yaml, delta-only facet overrides, base-theme inheritance, dark mode
  variants, WCAG contrast tuning. Use this skill (/trl-theme-designer) to realize a treatise
  as a theme, fine-tune theme YAML or design-token seeds, add a dark mode variant, fix
  contrast, or audit theme drift. Also trigger on: theme-{slug}, base-theme, vars.yaml,
  css-snippets, color-modes, npx @noizu/styleguide serve, treatise conformance. NOT for
  authoring treatises/brand identity/style guides from scratch (trl-user-experience-engineer),
  app frontend implementation (trl-react-engineer), or engine internals development.
ch-description: >-
  依據論述微調 styleguide-engine 主題 YAML：擷取 vars、建立繼承／差異 facet 與深色模式，並修正
  WCAG 對比或漂移。適用於主題 YAML、設計權杖種子、theme-{slug}、vars.yaml、color-modes 或論述符合性。
---

# Theme Designer

Realize and refine styleguide-engine themes from a design treatise — seeds first, deltas only, verified in every mode.

## Overview

The styleguide-engine renders interactive design systems from YAML theme directories. A
**theme treatise** (authored by trl-user-experience-engineer) captures the design theory;
this skill translates it into engine YAML and keeps the two in agreement. It provides:

- **Treatise intake** — parse the canonical 10 sections into actionable YAML deltas
- **Seed extraction** — map the treatise to the ~12 seeds in `style-guide.vars.yaml` that the 4-pass cascade expands into 300+ CSS custom properties
- **Facet tuning** — override only the facet files (of ~20) that deviate from the base theme, respecting accumulation rules
- **Variant families** — child themes (dark/light/high-density) chaining `base-theme`
- **Multi-mode verification** — light/dark/high-contrast passes via `npx @noizu/styleguide serve`, WCAG contrast checks against Section 9 commitments
- **Drift audit** — treatise-vs-YAML conformance reports

## Core Philosophy

**Four principles:**

1. **The treatise is the contract.** Every YAML value traces back to a treatise section; every treatise commitment is either satisfied in YAML, explicitly waived, or escalated back to the treatise author. No freelancing new design theory in YAML.
2. **Override only deltas.** Every theme inherits `base-theme: "theme-style-guide"`. A facet file exists only because the treatise demands a deviation. Never hand-author a base theme — the npx launcher provides the canonical one.
3. **Tune seeds before facets.** The cascade turns 12 seeds into 300+ tokens. A one-line seed change in `vars.yaml` outperforms fifty component overrides. Reach for facet overrides only when the cascade's derivation is wrong for this design, not merely incomplete.
4. **A theme isn't done until every mode passes.** Light, dark, and high-contrast renders are verified against the treatise's accessibility commitments, and the serve output shows no `✗` errors and no unexplained `⚠` warnings.

## When to Use This Skill

- **Realize a new theme** — a treatise exists; build `theme-{slug}/` from it
- **Tune an existing theme** — "the accent is too loud", "cards feel flat in dark mode"
- **Add a mode/density variant** — child theme for dark-first, light, or compact use
- **Contrast tuning** — WCAG failures or "muted text is unreadable" reports
- **Drift audit** — the treatise changed, or the YAML grew ad-hoc edits; reconcile them

> For authoring the treatise, brand identity, style systems, personas, or markdown style guides, see **trl-user-experience-engineer** (`references/outputs/engine-styleguide.md`, `references/outputs/styleguide-setup-guide.md`).

> For consuming the tuned theme in a product frontend (Next.js integration, `npm run regen`, `/styleguide` route), see **trl-react-engineer** — this skill stops at the theme directory and conformance notes.

## The Pipeline

```
treatise-{slug}.md ──▶ INTAKE ──▶ SEED EXTRACTION ──▶ FACET OVERRIDES ──▶ SERVE + ITERATE ──▶ MODE VERIFICATION ──▶ CONFORMANCE NOTE
  (10 sections)        deltas      vars.yaml            delta facets       npx launcher        light/dark/HC          conformance-{slug}.md
```

The theme lives at `projects/{domain}/design/theme/theme-{slug}/`, beside its treatise
`projects/{domain}/design/theme/treatise-{slug}.md`.

## Seed Selection Guide

The 12 canonical seeds in `style-guide.vars.yaml`, and which treatise signal drives each:

| Seed | Treatise signal (section) | Cascade effect | Touch when… |
|------|---------------------------|----------------|-------------|
| `white` | §3 Color Story — lightest surface | Top of gray ramp (gray-50…), light-mode surfaces | Canvas isn't pure white (warm/cool paper) |
| `black` | §3 Color Story — darkest value | Bottom of gray ramp (…gray-900), dark surfaces, text | Dark canvas is tinted (never default `#000` for dark-native themes) |
| `brand-red` | §3 primary accent | `-light`/`-mid` tints, CTA/action colors | Always — this is the theme's voice |
| `brand-blue` | §3 secondary accent | Secondary tints, links/info accents | Treatise names a second accent |
| `brand-yellow` | §3 tertiary accent | Tertiary tints, highlights | Treatise names a third accent |
| `success` | §9 Accessibility + §3 | `success-tint` backgrounds | Default green clashes with palette temperature or fails contrast |
| `warning` | §9 + §3 | `warning-tint` | Same |
| `error` | §9 + §3 | `error-tint` | Same — and error must stay distinguishable from `brand-red` |
| `info` | §9 + §3 | `info-tint` | Same |
| `font-sans` | §4 Typographic Voice | Full type system, headings + body | Always — must match `branding.yaml` `font-url` |
| `font-mono` | §4 | Code, tokens, technical text | Treatise names a mono voice |
| `radius` | §6 Shape & Surface | Entire border-radius scale | Always — sharpness is the cheapest strong signal (0–2px stern, 6–8px friendly, 12px+ soft) |

Layout seeds (`unit`, spacing overrides) come from §5 Space & Density — override only when the treatise demands non-default rhythm. Full mechanics: `references/seed-extraction.md`.

## Facet Override Decision Table

Treatise section → facet file → when to override vs inherit. Accumulating facets (`css-snippets`, `jsx-snippets`, `scoped-vars`, `css-load`, `jsx-load`) merge with the base; all others replace it wholesale when present.

| Treatise section | YAML facet | Override when… | Inherit when… |
|---|---|---|---|
| §1 Identity | `style-guide.meta.yaml`, `branding.yaml` | Always (name, slug, identity, font-url) | Never |
| §3 Color Story | `style-guide.vars.yaml` (seeds) | Always | Never |
| §3 (mode behavior) | `style-guide.color-modes.yaml` | Always — real light AND dark maps | Never (production themes define both) |
| §3 (documentation) | `style-guide.color-palette.yaml` | Palette has named groups worth documenting | Small palettes; base doc suffices |
| §4 Typographic Voice | `style-guide.typography.yaml` | Custom type scale, weights, letter-spacing | Default scale with new fonts (seeds carry fonts) |
| §5 Space & Density | `style-guide.spacing.yaml`, `style-guide.page-layouts.yaml` | Non-default rhythm, widths, density | 8px scale + 1200px container fit |
| §6 Shape & Surface | seeds (`radius`) + `style-guide.scoped-vars.yaml` | Per-surface treatments beyond radius seed | Radius seed says it all |
| §7 Motion & Feedback | `style-guide.css-snippets.yaml` (accumulates) | Custom transitions, hover/glow feedback | Default motion is acceptable |
| §8 Component Inflections | `style-guide.css-snippets.yaml`, component vars in `vars.yaml`, `style-guide.semantic-classes.yaml` | Named component deviations (btn-*, card-*) | Components follow the cascade |
| §7/§8 (shells) | `style-guide.shell-layouts.yaml` | Treatise specifies app shells / nav chrome | Standard landing/dashboard shells |
| §9 Accessibility | feeds contrast checks on seeds + `color-modes` | (verification input, not a facet) | — |
| §10 Facet Mapping Appendix | (cross-check) | Appendix disagrees with your plan → reconcile first | — |

Full accumulation rules and per-facet schemas: `references/facet-tuning-guide.md`.

## Mode-Verification Matrix

Run after every tuning round (`npx @noizu/styleguide serve <theme-parent-dir>`):

| Check | Light | Dark | High-contrast / forced-colors |
|---|---|---|---|
| Body text vs surface ≥ 4.5:1 | required | required | ≥ 7:1 if treatise §9 commits to AAA |
| Muted/secondary text ≥ 4.5:1 | required | required (gray-500 on dark canvas is the usual failure) | required |
| Accent-on-surface (buttons, links) ≥ 4.5:1 | required | required — accents often need brightening in dark | required |
| Semantic states distinguishable + ≥ 3:1 vs surface | required | required | not color-alone (icon/label present) |
| Borders/dividers visible (≥ 3:1 for meaningful boundaries) | required | required | required |
| Focus ring visible on every interactive element | required | required | required |
| Mode toggle produces genuinely distinct render | — | required | — |
| Serve output: no `✗`, no unexplained `⚠` | required | required | — |

Procedure, contrast math, and the drift audit: `references/verification-and-drift.md`.

## Quick Start Guides

### Path 1: New theme from a treatise
1. Read `treatise-{slug}.md`; fill `assets/seed-extraction-worksheet.md` (section → delta)
2. Create `theme-{slug}/` with `style-guide.meta.yaml` (name, slug = dir suffix, `base-theme: "theme-style-guide"`), `style-guide.vars.yaml` seeds, `branding.yaml`, `style-guide.color-modes.yaml`
3. `npx @noizu/styleguide serve projects/{domain}/design/theme/` — clear every `✗`, then every `⚠`
4. Add delta facets per the decision table; re-serve after each
5. Run the mode-verification matrix; fix contrast against §9
6. Write `conformance-{slug}.md` from `assets/theme-conformance-report.md`

### Path 2: Tune an existing theme
1. Read the treatise AND the current YAML; locate which section governs the complaint
2. Prefer a seed change; escalate to facet override only if the cascade derivation is wrong
3. Serve, compare before/after in both modes, re-check affected contrast rows
4. Update the conformance note (or flag treatise drift if the change contradicts it)

### Path 3: Add a dark (or light) variant
1. Create `theme-{slug}-{variant}/` with `base-theme: "theme-{slug}"` (chained inheritance)
2. Override only `style-guide.color-modes.yaml`, mode-relevant seeds, and `scoped-vars`
3. Verify both themes in the picker side-by-side; run the full mode matrix on the variant

## Reference Guide

### When to Read Each Reference

| Task | Read These |
|------|-----------|
| **Parse a treatise into deltas** | `treatise-intake.md` |
| **Extract/adjust seeds, understand the cascade** | `seed-extraction.md` |
| **Decide override vs inherit for any facet** | `facet-tuning-guide.md` |
| **Pick/adjust hues, temperature, contrast ratios** | `color-theory-for-tuning.md` |
| **Type scale, weights, line rhythm as vars** | `typography-and-rhythm-for-tuning.md` |
| **Serve loop, mode matrix, drift audit** | `verification-and-drift.md` |
| **See the whole pipeline end-to-end** | `worked-example-ember-theme.md` |
| **Run a workflow as an agent** | `agent-playbook.claude-code.md` |

All reference paths are relative to `references/`.

## Related Skills

- **trl-user-experience-engineer** — upstream: authors treatises, style guides, brand identity, and owns the engine output docs; hand back when drift needs a treatise change
- **trl-react-engineer** — downstream: integrates the tuned theme into project frontends (Workflow C hosting, `npm run regen`)
- **trl-story-to-release** — audits shipped features for style-guide conformance; consumes the same theme this skill tunes

## Bundled Resources

### References
- [agent-playbook.claude-code.md](references/agent-playbook.claude-code.md) — Agent role + 4 executable workflows
- [treatise-intake.md](references/treatise-intake.md) — Parsing the 10 treatise sections into actionable deltas
- [seed-extraction.md](references/seed-extraction.md) — The 12 seeds, cascade passes, override levels
- [facet-tuning-guide.md](references/facet-tuning-guide.md) — All ~20 facets: schemas, override vs inherit, accumulation
- [color-theory-for-tuning.md](references/color-theory-for-tuning.md) — Hue/temperature/contrast mechanics mapped to seed and palette values, WCAG ratios
- [typography-and-rhythm-for-tuning.md](references/typography-and-rhythm-for-tuning.md) — Scale ratios, weight axes, line rhythm as engine vars
- [verification-and-drift.md](references/verification-and-drift.md) — Serve loop, mode matrix, treatise-drift audit
- [worked-example-ember-theme.md](references/worked-example-ember-theme.md) — End-to-end: treatise → seeds → facets → contrast fixes → conformance

### Assets
- [project-tracker.md](assets/project-tracker.md) — Per-theme progress tracker
- [seed-extraction-worksheet.md](assets/seed-extraction-worksheet.md) — Treatise section → seed value capture sheet
- [theme-conformance-report.md](assets/theme-conformance-report.md) — Treatise-vs-YAML audit template
