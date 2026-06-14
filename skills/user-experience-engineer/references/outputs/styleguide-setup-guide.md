# Style Guide Setup Guide

> End-to-end instructions for previewing and hosting an interactive style guide with `@noizu/styleguide`.
>
> **Default to the npx launcher (§2).** It needs no cloned engine and no scaffolded app — point it at a theme directory and it spins up the viewer. Reach for the heavier workflows (§3 engine viewer, §4 project-local hosting) only when the style guide must live inside a project's own Next.js app, or you are integrating `/styleguide` into a shipping frontend.

---

## 1. Overview

`@noizu/styleguide` generates interactive HTML style guides from YAML configuration files. It provides:

- **4-pass defaults cascade:** ~12 seed values expand to ~300 CSS custom properties
- **Theme auto-discovery:** any `theme-*` directory with a `style-guide.meta.yaml` is registered
- **Theme inheritance:** a theme sets `base-theme: "theme-style-guide"` and inherits every facet it does not override
- **Per-theme CSS scoping:** `html[data-design-theme="{slug}"]` isolates themes
- **Live previews:** color modes, component showcases, typography specimens, theme switching
- **Config validation:** missing required fields and broken cross-references are reported as console warnings **and** a static alert card in the viewer (see §2.4)

### Three ways to use it

| Approach | When | Section |
|---|---|---|
| **npx launcher** (`@noizu/styleguide serve`) | **Default.** Design exploration, iteration, review, direction comparison. No project frontend required. | **§2 — start here** |
| **Engine viewer** (`serve-project.sh`) | The styleguide-engine repo is cloned and you want repo-integrated symlink previews | §3 |
| **Project-local hosting** | The project ships its own Next.js app and `/styleguide` lives alongside product pages (e.g. codefre.sh) | §4 |

### When to Read This vs. Other Docs

| You want to... | Read this |
|---|---|
| Preview a theme right now with zero setup | **§2 of this document** |
| Set up a new project's style guide from scratch | **This document** (§2, then §3 or §4 if hosting in-app) |
| Convert a completed markdown style guide to YAML | [engine-styleguide.md](engine-styleguide.md) §5-6 |
| Understand the YAML schema in depth | [engine-styleguide.md](engine-styleguide.md) §6 + engine `docs/arch/yaml-configuration.md` |
| Build the markdown style guide itself | [style-guide-construction.md](../process/style-guide-construction.md) |
| Compare design directions (A/B/C/D) | §5 of this document |
| Understand the CSS cascade | Engine `docs/reference/cascade.md` |
| Use components in your app | [engine-styleguide.md](engine-styleguide.md) §10 |

---

## 2. Workflow A: npx Launcher (Recommended)

The fastest, most reliable way to render a style guide. No cloned engine, no scaffolded app — the launcher caches a viewer app under `~/.cache/styleguide-viewer/`, symlinks your themes into it, generates CSS, and starts the dev server.

### 2.1 One command

```bash
# Via npx (no install required — pulls the latest published package)
npx @noizu/styleguide serve ./design/theme/

# Or, if installed globally / as a dependency
styleguide-serve ./design/theme/ --port 3001
```

The argument is a directory containing one or more `theme-*` subdirectories. On run, the launcher:

1. **Ensures the base theme is present** — copies the canonical `theme-style-guide` from the package if your directory doesn't already contain it (see §2.2)
2. Symlinks every `theme-*` directory into the cached viewer
3. Generates per-theme CSS (and prints validation warnings — see §2.4)
4. Starts Next.js on `http://localhost:3000` (override with `--port`)

Useful flags: `--port <n>`, `--clean` (wipe and rebuild the viewer cache — use after upgrades or if the cache is stale), `--help`, `--version`.

> First run installs the viewer's dependencies (~20s). Subsequent runs start in ~3s. The launcher declares its full dependency closure, so you do **not** need to install React, heroicons, monaco, etc. yourself.

### 2.2 The base theme is provided for you — do not hand-author it

Every theme inherits from a complete **base theme** (`theme-style-guide`, ~20 facet files) that supplies the cascade defaults, the full section list, semantic classes, shell/page layouts, glyphs, and more. **The launcher copies the correct, complete base into your theme directory automatically** if it isn't already there — you do not write it from scratch.

Hand-rolling a partial base is the **#1 cause of broken renders** (no centered content, missing sections, generic styling). Instead:

- Let the launcher provide `theme-style-guide`, **or** copy the canonical base out of the package: `node_modules/@noizu/styleguide/dist/engine-src/config/theme-style-guide/`.
- In each **custom** theme's `style-guide.meta.yaml`, set `base-theme: "theme-style-guide"` (this is the directory name, with the `theme-` prefix; it is also the default if omitted).
- Override **only the facets that differ** from the base. Everything else inherits. Five keys *accumulate* with the base instead of replacing it: `css-snippets`, `jsx-snippets`, `scoped-vars`, `css-load`, `jsx-load`.

```
./design/theme/
  theme-style-guide/        ← canonical base (auto-copied by the launcher; leave it)
  theme-my-brand/           ← your theme; inherits via base-theme
    style-guide.meta.yaml   #   base-theme: "theme-style-guide"
    style-guide.vars.yaml   #   override seeds
    branding.yaml           #   your identity
    style-guide.color-modes.yaml
```

### 2.3 Required fields — or the theme will not render

The validator emits **errors** (`✗`, red) for fields whose absence breaks rendering. Fix every error before anything else:

| Field (file) | If missing | Minimum |
|---|---|---|
| `name` (`style-guide.meta.yaml`) | Theme renders without a display name | `name: "My Brand"` |
| `slug` (`style-guide.meta.yaml`) | **Theme selector and URL routing break** (`html[data-design-theme]` has no target) | `slug: "my-brand"` — must match the directory suffix (`theme-my-brand/` → `my-brand`) |
| `vars.groups` (`style-guide.vars.yaml`) | **No design tokens are generated — nothing cascades, the page is unstyled** | at least one group with real `vars:` (white, black, one accent, `font-sans`, `radius`) |

Strongly recommended (warned if absent — see §2.4): `branding.yaml` identity, `style-guide.color-modes.yaml` (light + dark), `semantic-classes`, `page-layouts`. For a custom theme these are inherited from the base if you omit them, but a production theme should define its own.

### 2.4 Read the launcher's warning output

Both CSS generation (console) and the running viewer (a static alert card at the top of the page) report config problems. **Treat them as a punch list.**

**Console format** — every line names the theme slug, the section, and the consequence:

```
✗ [my-brand] meta:  Missing 'slug' — theme selector and URL routing will break        (red = error, breaks rendering)
⚠ [my-brand] vars:  vars.groups[3] (Cards) has no variables                            (amber = warning, degrades rendering)
⚠ [my-brand] css-snippets: css-snippets 'card-glow' targets section 'cards' which is not defined in page-sections
```

**In the browser:** a non-dismissable **ConfigWarnings alert card** renders above the hero, grouped by section, color-coded (errors red, warnings amber), collapsible. Same information as the console, visible to anyone reviewing the rendered guide.

Common warnings and their fixes:

| Warning | Meaning | Fix |
|---|---|---|
| `vars.groups[N] (X) has no variables` | A declared token group is empty | Add `vars:` to the group, or delete the empty group |
| `No semantic classes defined — cards, buttons, and form variants won't render` | `semantic-classes` is empty/absent and not inherited | Define `semantic-classes` (or inherit from base) |
| `... targets section 'X' which is not defined in page-sections` | A css/jsx snippet's `target-section` doesn't exist | Add the section id to `style-guide.page-sections.yaml`, or fix the snippet's `target-section` |
| `color-modes missing 'light'/'dark' map` | Only one mode defined | Populate both `color-modes.light` and `color-modes.dark` |
| `page-sections[i].sections[j] missing 'id'` | A nav entry has no id | Add an `id` so the section links/renders |
| `semantic-classes[i] (...) missing 'class'/'accent-style'/vars.accent` | Incomplete semantic class | Fill `class`, `accent-style`, and `vars.accent` |

**Goal: a clean run shows no `✗` and ideally no `⚠`.** Resolve errors first (they break rendering), then warnings (they degrade it).

### 2.5 Directory structure the launcher expects

```
<theme-directory>/                  ← the path you pass to `serve`
  theme-style-guide/                ← base (auto-added if missing)
    style-guide.meta.yaml
  theme-my-brand/
    style-guide.meta.yaml           (required — registers the theme)
    style-guide.vars.yaml
    branding.yaml
    style-guide.color-modes.yaml
    ...                             (optional facets — override only what differs)
```

A `theme-*` directory missing `style-guide.meta.yaml` is skipped (with a warning). If no valid themes are found, the launcher exits with an explanation.

### 2.6 Requirements

- Node 18+ (22+ recommended) and npm on `PATH`
- For `npx @noizu/styleguide`, `.npmrc` must resolve the `@noizu` scope to Verdaccio (`npm.noizu.com`); set `NPM_TOKEN` if the registry requires auth
- No other manual dependency setup — the launcher's cached app installs everything it needs

---

## 3. Workflow B: Engine Viewer (`serve-project.sh`)

Use this when the styleguide-engine repo is cloned locally and you want repo-integrated previews driven by symlinks. The npx launcher (§2) is simpler and preferred for most work; reach for this when you specifically need the engine checkout (e.g. editing engine internals).

### 3.1 Directory Structure

```
projects/{domain}/
  design/
    README.md                          # Design overview, direction comparison
    direction-a-{name}.md             # Design direction A (markdown style guide)
    direction-b-{name}.md             # Design direction B
    logo.svg                           # Logo asset
    theme/                             # ← Engine-compatible theme configs
      theme-{slug-a}/
        style-guide.meta.yaml         # Required
        style-guide.vars.yaml         # Required
        branding.yaml                  # Required
        style-guide.color-modes.yaml  # Required
        ...                            # Optional facets
      theme-{slug-b}/
        style-guide.meta.yaml
        ...
```

### 3.2 Setup Steps

**Step 1: Create the design directory**

```bash
mkdir -p projects/{domain}/design/theme/theme-{slug}
```

**Step 2: Copy the theme template**

```bash
cp skills/user-experience-engineer/assets/theme-template/* \
   projects/{domain}/design/theme/theme-{slug}/
```

This copies skeleton YAML files with documented placeholders. At minimum, populate `style-guide.meta.yaml` (`name`, `slug`, `title`, `description`, `base-theme`), `style-guide.vars.yaml` (seed colors, fonts, radius), and `branding.yaml` (`name`, `logo-text`, `font-url`). See §2.3 for the hard requirements.

**Step 3: Verify slug consistency** — the `slug` in `style-guide.meta.yaml` must match the directory suffix (`theme-codefresh-forge/` → `slug: codefresh-forge`).

**Step 4: Preview in the engine**

```bash
./serve-project.sh {domain}
```

This removes stale theme symlinks from the engine's `src/config/`, symlinks your `design/theme/theme-*` directories in, runs CSS generation, and starts the dev server. Open `http://localhost:3000`.

### 3.3 Requirements

- The engine is cloned (`styleguide-engine/` submodule initialized)
- Node 22+, npm installed; `.npmrc` configured for Verdaccio (`npm.noizu.com`)
- Engine dependencies installed: `cd styleguide-engine/app && npm install`

> Even with the engine cloned, you can still preview any theme directory directly with `npx @noizu/styleguide serve ./design/theme/` — no symlinking required.

---

## 4. Workflow C: Project-Local Hosting (Starter)

Use this when the project has its own frontend and you want the style guide as part of the project's web app — the `/styleguide` route lives alongside your product pages.

### 4.1 Directory Structure

This is the codefre.sh pattern:

```
projects/{domain}/
  app/
    frontend/
      src/
        config/
          theme-style-guide/             # Base theme (canonical — keep complete)
            style-guide.meta.yaml
            style-guide.vars.yaml
            branding.yaml
            style-guide.color-modes.yaml
            ...                           # full facet set
        app/
          styleguide/
            page.tsx                      # Full interactive viewer
          design-system.generated.css     # Generated (gitignored)
```

### 4.2 Setup Steps

**Option A: From starter tarball**

```bash
tar xzf skills/user-experience-engineer/assets/styleguide-starter.tar.gz \
  -C projects/{domain}/web
cd projects/{domain}/web
npm install
npm run regen
npm run dev
```

**Option B: From init-proj-scaffold (full-stack)**

```bash
init-proj-scaffold {domain} {slug} {ElixirModule}
cd projects/{domain}/app
make init && make build && make run
```

The scaffold includes `frontend/src/config/theme-style-guide/` with all YAML facets pre-populated with documented placeholders. Edit them in place.

**Option C: Manual setup** (integrating into an existing Next.js project)

1. Add `@noizu/styleguide` to `package.json`
2. Add the webpack alias + tsconfig paths for `@styleguide-engine/`
3. Create `src/config/theme-{slug}/` with the required files (§2.3) and `base-theme: "theme-style-guide"`
4. Add `src/scripts/generate-css.ts` (calls `generateCSS()` from the package)
5. Add `src/app/styleguide/page.tsx` (renders the viewer)
6. Import the generated CSS in `globals.css`

> Whatever the hosting option, you can sanity-check the YAML at any time without the full app by running `npx @noizu/styleguide serve <config-dir>` against the directory holding your `theme-*` folders.

### 4.3 Customizing the Theme

**Minimum viable custom theme** — inherit the base, override seeds + color modes:

```yaml
# style-guide.meta.yaml
name: "CodeFresh"
slug: "codefresh"
title: "CodeFresh — Style Guide"
description: "Eval-driven AI development platform."
base-theme: "theme-style-guide"   # inherit everything not overridden
```

```yaml
# style-guide.vars.yaml
vars:
  groups:
    - name: Theme Seeds
      vars:
        white: "#ffffff"
        black: "#000000"
        red: "#7C3AED"          # your primary accent
        blue: "#0047ab"
        yellow: "#f5c518"
        success: "#22c55e"
        warning: "#eab308"
        error: "#ef4444"
        info: "#3b82f6"
        font-sans: "'Geist', -apple-system, sans-serif"
        font-mono: "'Geist Mono', 'Menlo', monospace"
        radius: "6px"
```

```yaml
# branding.yaml
name: "CodeFresh"
logo-text: "CODEFRESH"
font-url: "https://fonts.googleapis.com/css2?family=..."
intent: "Eval-driven development platform for AI builders."
perception: "Competent, fast, trustworthy."
audience: "AI engineers who ship production models."
tone: "Direct, technical, never condescending."
keywords: [eval, ship, iterate, precise, fast]
```

```yaml
# style-guide.color-modes.yaml
color-modes:
  light:
    surface: "var(--white)"
    surface-alt: "var(--gray-50)"
    text: "var(--black)"
    text-secondary: "var(--gray-700)"
    text-muted: "var(--gray-500)"
    border: "var(--gray-200)"
    border-strong: "var(--gray-300)"
  dark:
    surface: "#1a1a1a"
    surface-alt: "#252525"
    text: "#e8e8e8"
    text-secondary: "var(--gray-400)"
    text-muted: "var(--gray-500)"
    border: "#333333"
    border-strong: "var(--gray-600)"
```

Everything else inherits from the base theme. Add facet files only to override.

### 4.4 Regenerate and Preview

```bash
npm run regen    # or: ./regen.sh
npm run dev      # → http://localhost:3000/styleguide
```

**Never run `npx next build` in a running dev environment** — use `tsc --noEmit` for type checking.

---

## 5. Multiple Design Directions

For projects exploring multiple visual directions (like codefre.sh with 4 directions), create a separate theme per direction, all inheriting the same base. Preview them together with `npx @noizu/styleguide serve ./design/theme/` (or `./serve-project.sh {domain}`) — the theme picker shows every `theme-*` for side-by-side comparison.

### 5.1 Design Directory Layout

```
projects/{domain}/design/
  README.md                            # Comparison table + decision framework
  direction-a-{name}.md              # Full markdown style guide for direction A
  direction-b-{name}.md
  logo.svg
  theme/
    theme-style-guide/                 # shared base
    theme-{domain}-{direction-a}/
    theme-{domain}-{direction-b}/
    theme-{domain}-{direction-c}/
```

### 5.2 Naming Convention

Theme directories follow `theme-{project}-{direction-name}`. Examples from codefre.sh:
- `theme-codefresh-minimal` (Direction A: Minimal Tech 100%)
- `theme-codefresh-editorial` (Direction B: MT 80% + Editorial 20%)
- `theme-codefresh-brutalist` (Direction C: Neo-Brutalist)
- `theme-codefresh-forge` (Direction D: Forge)

### 5.3 Design README Template

The design README should include (see `projects/codefre.sh/design/README.md`):

1. **At-a-glance comparison table** — columns per direction; rows for name, style system, primary font, accent color, border radius, motion, risk level
2. **Decision framework** — flowchart/decision tree for choosing between directions
3. **Mixing guidance** — which directions combine, and how
4. **What's not covered** — explicit scope boundaries
5. **Next steps** — what to do after selection

---

## 6. Reference Implementation: codefre.sh

codefre.sh demonstrates the recommended setup pattern.

### What codefre.sh Does Well

| Aspect | Implementation |
|---|---|
| **Design exploration** | 4 design directions as separate markdown files with comparison table |
| **Decision framework** | Flowchart in README for choosing between directions |
| **Complete vars.yaml** | All component-level overrides (cards, buttons, HUI controls, toggles) |
| **Color modes** | Distinct light and dark modes with semantic token mapping |
| **Full facet coverage** | All facet files populated (not just the required ones) |
| **Font loading** | Google Fonts URL in branding.yaml, matching font-sans/font-mono in vars |
| **Project-local hosting** | Themes in `app/frontend/src/config/` for integrated dev experience |

### Lessons from codefre.sh

1. **Start with vars.yaml** — the cascade derives everything from seeds, so this is the highest-leverage file (and `vars.groups` is a hard requirement, §2.3)
2. **Inherit, then override** — set `base-theme` and populate only the facets that differ; the base fills the rest
3. **Color modes are not optional** — every production theme needs real light and dark modes
4. **Design directions as markdown first** — write full style guides as markdown, then extract to YAML (see [engine-styleguide.md](engine-styleguide.md) §5)
5. **Component overrides matter** — codefre.sh defines many var groups including HUI controls, toggles, and cards. Without these, components use generic base styling
6. **Watch the validation output** — a clean `serve`/`regen` run with no `✗`/`⚠` is part of "done" (§2.4)

---

## 7. Complete Setup Checklist

### Prerequisites

- [ ] Node 18+ (22+ recommended) and npm installed
- [ ] `.npmrc` configured for Verdaccio (`npm.noizu.com`) for the `@noizu` scope
- [ ] For §3/§4 only: engine submodule initialized or starter extracted, and dependencies installed

### Required Fields (theme will not render without these — §2.3)

- [ ] `style-guide.meta.yaml` — `name` **and** `slug` (slug matches directory suffix)
- [ ] `style-guide.vars.yaml` — non-empty `vars.groups` with at least one real group (white, black, one accent, `font-sans`, `radius`)
- [ ] `base-theme: "theme-style-guide"` set (or omitted to use the default base) so inheritance fills the rest
- [ ] The base theme (`theme-style-guide`) is present in the config directory — let the launcher copy it; do not hand-author one (§2.2)

### Strongly Recommended (warned if absent)

- [ ] `branding.yaml` — `name`, `logo-text`, `font-url`, identity fields
- [ ] `style-guide.color-modes.yaml` — distinct `light` and `dark` maps
- [ ] `semantic-classes` defined (danger/success/warning/info) — or inherited from base
- [ ] `page-layouts` defined — or inherited from base

### Validation

- [ ] `npx @noizu/styleguide serve <config-dir>` (or `npm run regen`) completes with **no `✗` errors**
- [ ] **No `⚠` warnings** in the console or the in-viewer alert card — or each remaining one is understood and intentional (§2.4)
- [ ] No snippet `target-section` references a section absent from `page-sections`
- [ ] All hex values are valid (`#` + 6 digits); semantic colors (success/warning/error/info) defined
- [ ] Font families in vars.yaml match those loaded via branding.yaml `font-url`
- [ ] `/styleguide` (or `http://localhost:3000`) renders with correct colors, fonts, centered content, and components
- [ ] Dark mode toggle produces distinct light/dark rendering
- [ ] The theme appears in the theme picker (if multiple themes exist)

### Production Completeness

- [ ] All relevant YAML facet files populated (not just the required ones)
- [ ] Brand identity fields filled in branding.yaml (intent, perception, audience, tone, keywords)
- [ ] Intro hero configured with project-specific title, subtitle, color bar, meta cards
- [ ] Logo renders correctly
- [ ] Custom CSS snippets added for project-specific components (each with a valid `target-section`)
- [ ] Semantic classes configured for project states (danger, success, warning, info)
- [ ] Page + shell layouts defined for project content/navigation patterns

---

## 8. YAML Facet Reference (Quick)

All files live in the theme directory (`theme-{slug}/`). For full schema details, see [engine-styleguide.md](engine-styleguide.md) §6 and engine `docs/arch/yaml-configuration.md`.

| File | Top-Level Key | Purpose | Required? |
|---|---|---|---|
| `style-guide.meta.yaml` | `name`, `slug`, `title`, `description`, `base-theme` | Theme identity + inheritance | **Yes** (`name`, `slug`) |
| `style-guide.vars.yaml` | `vars.groups[]` | CSS custom properties (seed values → cascade) | **Yes** (non-empty) |
| `branding.yaml` | (standalone) | Brand identity, logo, intro hero | Recommended |
| `style-guide.color-modes.yaml` | `color-modes.light`, `color-modes.dark` | Semantic surface/text/border overrides per mode | Recommended |
| `style-guide.color-palette.yaml` | `color-palette[]` | Color groups for the palette viewer | No |
| `style-guide.typography.yaml` | `typography[]`, `typography-classes[]` | Font declarations and type scale | No |
| `style-guide.spacing.yaml` | `spacing-contexts` | Grid, container, rhythm settings | No |
| `style-guide.page-layouts.yaml` | `page-layouts[]` | Content width presets with chrome | No |
| `style-guide.shell-layouts.yaml` | `shell-layouts[]` | Page shell wireframes (navbar/sidebar/footer) | No |
| `style-guide.css-snippets.yaml` | `css-snippets[]` | Custom CSS rules (accumulated with base) | No |
| `style-guide.jsx-snippets.yaml` | `jsx-snippets[]` | Custom JSX demos (accumulated with base) | No |
| `style-guide.scoped-vars.yaml` | `scoped-vars` | Selector-scoped vars (accumulated with base) | No |
| `style-guide.semantic-classes.yaml` | `semantic-classes[]` | Contextual modifier classes (danger, success, etc.) | No |
| `style-guide.semantic-groups.yaml` | `semantic-groups[]` | Groupings for semantic classes | No |
| `style-guide.globals.yaml` | `globals` | Raw CSS injected last (resets, base elements) | No |
| `style-guide.glyphs.yaml` | `glyph-language` | Unicode glyph browser entries | No |
| `style-guide.design-sections.yaml` | `design-sections` | Design principle rows for the viewer | No |
| `style-guide.page-sections.yaml` | `page-sections[]` | Controls which sections appear in the viewer | No |

### Merge Behavior

Most files **replace** the base theme's equivalent when present. These keys **accumulate** (entries from both theme and base are merged):

- `css-snippets`
- `jsx-snippets`
- `scoped-vars`
- `css-load`
- `jsx-load`

---

## 9. Common Pitfalls

| Problem | Cause | Fix |
|---|---|---|
| **No centered content / generic styling / missing sections** | Hand-authored or incomplete base theme; base theme absent | Let the launcher copy the canonical `theme-style-guide` (§2.2); set `base-theme: "theme-style-guide"` and override only deltas |
| **Page renders unstyled** | `vars.groups` missing or empty (a hard error) | Add at least one var group with real seed tokens (§2.3); check console for `✗ vars:` |
| Theme not appearing in picker | Directory doesn't start with `theme-` or missing `style-guide.meta.yaml` | Rename directory, add meta.yaml |
| CSS not scoped correctly | Slug mismatch between meta.yaml and directory name | Ensure `theme-foo/` has `slug: foo` |
| `... targets section 'X' which is not defined in page-sections` | Snippet `target-section` doesn't exist | Add the section id to `page-sections`, or fix the snippet (§2.4) |
| Warnings ignored | Not reading console / the in-viewer alert card | Treat every `✗`/`⚠` as a punch-list item (§2.4) |
| Fonts not loading | `font-url` in branding.yaml doesn't match font families in vars.yaml | Verify the Google Fonts URL includes all declared weights |
| Dark mode looks identical to light | Color modes not defined or both set to same values | Populate `color-modes` with distinct light/dark values |
| Components look generic | Only seed vars defined, no component overrides | Add component-level vars (card-\*, btn-\*, etc.) to vars.yaml |
| Stale viewer after upgrading the package | Cached viewer app out of date | Re-run with `npx @noizu/styleguide serve <dir> --clean` |
| `serve-project.sh` fails | No `design/theme/` directory or no `theme-*` subdirs | Create the expected structure (or just use the npx launcher) |
| `npm run regen` fails | npm not configured for Verdaccio registry | Ensure `.npmrc` points to `npm.noizu.com` for the `@noizu` scope |

---

## 10. Recommended Order of Operations

For a new project in the incubator:

```
1. Select style system
   └── SKILL.md Style Selector table → choose pure or mixed (80/20)

2. Write design direction(s) as markdown
   └── process/style-guide-construction.md → full markdown style guide(s)
   └── Save to projects/{domain}/design/direction-{x}-{name}.md

3. Write design README
   └── Comparison table + decision framework (see codefre.sh/design/README.md)

4. Extract YAML from selected direction
   └── engine-styleguide.md §5-6 → section-to-YAML mapping

5. Create the theme directory + custom theme
   └── projects/{domain}/design/theme/theme-{slug}/
   └── Set base-theme: "theme-style-guide"; do NOT hand-author the base (§2.2)

6. Populate required fields first
   └── meta (name, slug) → vars.groups → branding → color-modes (§2.3)

7. Preview with the npx launcher (default)
   └── npx @noizu/styleguide serve ./design/theme/
   └── (Workflow B/C: ./serve-project.sh {domain}  or  npm run regen && npm run dev)

8. Clear the validation punch list
   └── Resolve every ✗, then every ⚠, in the console + in-viewer alert card (§2.4)

9. Iterate on optional facets
   └── typography, spacing, snippets, semantic classes, layouts, etc.

10. Validate against the §7 checklist
```

---

## Related Documents

- [engine-styleguide.md](engine-styleguide.md) — YAML extraction from markdown, full schema templates, component reference
- [style-guide-construction.md](../process/style-guide-construction.md) — Building the markdown style guide
- [project-scaffold.md](project-scaffold.md) — Full-stack project scaffolding (includes theme setup)
- Engine docs: `styleguide-engine/app/docs/guides/creating-themes.md` — Theme creation walkthrough
- Engine docs: `styleguide-engine/app/docs/arch/yaml-configuration.md` — Full YAML schema reference
- Engine docs: `styleguide-engine/app/docs/reference/cascade.md` — Seed-to-token cascade
