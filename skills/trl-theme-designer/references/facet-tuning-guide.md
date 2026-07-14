# Facet Tuning Guide

> The ~20 YAML facets of a styleguide-engine theme: what each controls, its schema shape, when to override vs inherit from `theme-style-guide`, and the accumulation rules that make some facets merge instead of replace.

---

## 1. Inheritance Model

Every custom theme declares:

```yaml
# style-guide.meta.yaml
name: "Ember"
slug: "ember"                      # MUST match directory suffix: theme-ember/
title: "Ember — Style Guide"
description: "Warm dark developer-tool theme."
base-theme: "theme-style-guide"    # directory name, with the theme- prefix
```

- **The base is provided, never authored.** `npx @noizu/styleguide serve` auto-copies the canonical `theme-style-guide/` into your config dir. Hand-rolling a partial base is the #1 cause of broken renders. Leave it alone.
- **Replace semantics (default):** if your theme ships a facet file, it replaces the base's version of that facet **wholesale**. Omitting the file inherits the base's entirely. There is no per-key merge — so don't ship a `typography.yaml` with only one class and lose the rest.
- **Accumulate semantics (five keys):** `css-snippets`, `jsx-snippets`, `scoped-vars`, `css-load`, `jsx-load` **merge** with the base — your entries are added to the base's, not substituted.
- **Chaining:** a variant may set `base-theme: "theme-ember"` to inherit a custom parent; the parent still inherits `theme-style-guide`.
- **Hosting:** themes are never copied or symlinked into `styleguide-engine/app/src/config/` — the npx launcher / `serve-project.sh` / project-local `npm run regen` manage hosting.

## 2. Facet Catalog

All files live in `theme-{slug}/`. "Treatise §" is the section that typically drives an override.

| File | Top-level key(s) | Merge | Required | Treatise § | Override when… |
|---|---|---|---|---|---|
| `style-guide.meta.yaml` | `name`, `slug`, `title`, `description`, `base-theme` | replace | **Yes** | §1 | Always (identity + inheritance) |
| `style-guide.vars.yaml` | `vars.groups[]` | replace | **Yes** (non-empty) | §3-§6 | Always (seeds) — see `seed-extraction.md` |
| `branding.yaml` | flat fields + `intro` | replace | Recommended | §1 | Always (identity, `font-url`, logo-text) |
| `style-guide.color-modes.yaml` | `color-modes.light`, `.dark` | replace | Recommended | §3 mode strategy | Always for production — both maps, genuinely distinct |
| `style-guide.color-palette.yaml` | `color-palette[]` | replace | No | §3 narrative | Palette has named groups + usage rules worth documenting |
| `style-guide.typography.yaml` | `typography[]`, `typography-classes[]` | replace | No | §4 | Scale ratio, weights, or letter-spacing deviate from base |
| `style-guide.spacing.yaml` | `spacing-contexts` | replace | No | §5 | Non-default grid/container/rhythm |
| `style-guide.page-layouts.yaml` | `page-layouts[]` | replace | No | §5 | Content width presets differ (e.g. 70ch doc pane) |
| `style-guide.shell-layouts.yaml` | `shell-layouts[]` | replace | No | §7/§8 | Treatise specifies app shells / nav chrome |
| `style-guide.css-snippets.yaml` | `css-snippets[]` | **accumulate** | No | §6-§8 | Motion, elevation, component CSS the facets don't model |
| `style-guide.jsx-snippets.yaml` | `jsx-snippets[]` | **accumulate** | No | §8 | Custom demo components in the viewer |
| `style-guide.scoped-vars.yaml` | `scoped-vars` | **accumulate** | No | §6/§7 | Selector-scoped custom props (per-mode, per-section) |
| `style-guide.semantic-classes.yaml` | `semantic-classes[]` | replace | No | §8 | State classes deviate (accent-style, tint usage) |
| `style-guide.semantic-groups.yaml` | `semantic-groups[]` | replace | No | §8 | Regrouping semantic classes |
| `style-guide.globals.yaml` | `globals` | replace | No | §6 | Raw CSS injected last (resets, base elements) — last resort |
| `style-guide.glyphs.yaml` | `glyph-language` | replace | No | — | Theme ships its own glyph set |
| `style-guide.design-sections.yaml` | `design-sections` | replace | No | §2 | Documenting design principles in the viewer |
| `style-guide.page-sections.yaml` | `page-sections[]` | replace | No | — | Controlling which viewer sections appear; must contain every snippet `target-section` |

**Rule of thumb:** a chromatic/typographic theme ships 4-6 files. Ten or more files on a
theme whose treatise says "structural overrides: none" is a red flag — audit each file
against the treatise before adding the next.

## 3. Accumulation Rules in Practice

Because `css-snippets` merge with the base, you never lose base snippets by adding your
own — but you also **cannot remove or replace a base snippet** from the theme file. If a
base snippet fights your design, override its selectors with a later, more specific
snippet (and note it in conformance).

Snippet schema (real shape — `body` is the CSS payload, `target-section` must exist in
`page-sections`):

```yaml
# style-guide.css-snippets.yaml
css-snippets:
  - name: "Ember Status Pulse"
    slug: "ember-status-pulse"
    title: "In-progress pulse"
    description: "Slow ember breathing on in-progress status dots; disabled under reduced motion."
    target-section: ui-elements
    body: |
      .status--in-progress .status-dot {
        animation: ember-pulse 2s ease-in-out infinite;
      }
      @keyframes ember-pulse {
        0%, 100% { opacity: 0.7; }
        50%      { opacity: 1.0; }
      }
      @media (prefers-reduced-motion: reduce) {
        .status--in-progress .status-dot { animation: none; opacity: 1; }
      }
```

`scoped-vars` accumulate the same way — ideal for per-mode or per-selector custom props:

```yaml
# style-guide.scoped-vars.yaml
scoped-vars:
  'html[data-design-theme="ember"]':
    motion-micro: "100ms"
    motion-panel: "200ms"
  'html[data-design-theme="ember"][data-color-mode="dark"] .shell-header':
    header-glow: "radial-gradient(ellipse at top, rgba(232,118,58,0.04), transparent 70%)"
```

**Slug discipline:** every scoped selector uses YOUR slug (`html[data-design-theme="ember"]`).
When copying from templates whose selectors say `"style-guide"`, rewrite them — a stale
slug is a silent no-op.

## 4. Replace-Facet Gotchas

| Gotcha | Symptom | Fix |
|---|---|---|
| Partial `typography.yaml` | Type-scale section shrinks to your few classes | Ship the FULL class list you want, or omit the file and push font changes through seeds |
| `semantic-classes.yaml` with 2 of 4 states | Warning: cards/buttons/form variants missing states | Define all states you need (danger/warning/info/success) — replace means replace |
| `page-sections.yaml` copied to "just reorder" | Snippet `⚠ target-section not defined` errors, missing sections | Include every section referenced by any snippet (yours AND the base's, since snippets accumulate) |
| Editing the auto-copied `theme-style-guide/` | Works locally, breaks on `--clean` / other machines | Never edit the base; move the change into your theme |
| `slug` ≠ directory suffix | CSS generated but never applied | `theme-ember/` ⇒ `slug: ember` |

## 5. color-modes.yaml — the Facet Most Themes Get Wrong

Both maps are required for production; setting them identical is the rare, justified
exception (treatise must say so). Semantic keys remap the cascade per mode:

```yaml
# style-guide.color-modes.yaml
color-modes:
  dark:                              # ember's PRIMARY mode (§3)
    surface: "#1a1512"
    surface-alt: "#241d18"
    text: "var(--white)"             # #f5efe8 seed
    text-secondary: "#c9beb2"
    text-muted: "#96897c"
    border: "#3a2f27"
    border-strong: "#54463a"
  light:                             # faithful translation, not a new design (§3)
    surface: "var(--white)"
    surface-alt: "#ece4d8"
    text: "var(--black)"
    text-secondary: "#4a4038"
    text-muted: "#6f635a"
    border: "#d8ccbc"
    border-strong: "#b8a894"
```

Accent adjustments per mode (e.g., ember darkened to `#c85a20` on light) go through
`scoped-vars` on the mode selector, since seeds are mode-shared (see `seed-extraction.md` §4).

## 6. Worked Example: Choosing the File Set for Ember

Treatise says: "delta is entirely chromatic, typographic weight, and motion timing — no
structural overrides" (§1 variant note). Resulting plan:

| File | Ship? | Why |
|---|---|---|
| `style-guide.meta.yaml` | yes | identity + `base-theme` |
| `style-guide.vars.yaml` | yes | seeds (see `seed-extraction.md` §6) |
| `branding.yaml` | yes | §1 verbatim + Inter/JetBrains Mono `font-url` |
| `style-guide.color-modes.yaml` | yes | §3 mode strategy (dark primary, light translation) |
| `style-guide.typography.yaml` | yes | §4 pins a 1.2 scale + weight reservations — deviates from base |
| `style-guide.css-snippets.yaml` | yes (3 snippets) | §6 elevation-by-tone + header gradient, §7 pulse + reduced-motion, §8 button/input inflections |
| `style-guide.scoped-vars.yaml` | yes | §7 duration props, per-mode accent |
| `style-guide.color-palette.yaml` | yes | §10 names three doc groups |
| `spacing`, `page-layouts`, `shell-layouts`, `semantic-classes`, `globals`, `glyphs`, `page-sections` | no | §1: no structural overrides; §8 leaves listed components at base |

Eight files, each traceable to a treatise clause. Everything else inherits.
