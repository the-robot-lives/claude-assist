# Worked Example: The Ember Theme

> End-to-end fine-tuning pass: from the `treatise-ember.md` contract (a warm dark developer-tool theme) to a verified `theme-ember/` directory and its conformance note. Every step shows the actual artifact produced.

---

## 0. Starting Point

```
projects/forge.dev/design/theme/
  treatise-ember.md          ← authored by trl-user-experience-engineer (10 sections)
  (theme-ember/ does not exist yet)
```

Treatise headline (§1): dark-native developer workspace; "controlled warmth — the focus
of a dark room lit by a single warm source. Restraint everywhere except the one accent."
Variant note: inherits `theme-style-guide` structure unchanged; delta is chromatic,
typographic weight, and motion timing only.

## 1. Intake

Walking §1-§9 with the worksheet (`assets/seed-extraction-worksheet.md`) produced 23
claim rows. The decisive extracts:

| § | Claim (quoted/condensed) | Type | Encoding |
|---|---|---|---|
| 1 | intent/perception/audience/tone/keywords | pinned | `branding.yaml` verbatim |
| 3 | white seed `#f5efe8`, black seed `#141110`; ramp delegated; `#000`/`#fff` banned | pinned + delegated + exclusion | seeds + standing grep check |
| 3 | accent `#e8763a` ±5° hue ±8% sat; no secondary brand hue | pinned range + exclusion | `brand-red` seed; `brand-blue`/`brand-yellow` left unset |
| 3 | semantics: olive success, yellower-lighter warning, redder error, muted slate info | pinned regions | semantic seeds |
| 3 | dark primary; light = faithful translation, accent darkened ~`#c85a20` | pinned | `color-modes.yaml` + scoped-var for light accent |
| 4 | Inter / JetBrains Mono; ~1.2 scale; 400/500/600 reservations, 700 wordmark-only | pinned | font seeds + `typography.yaml` + `font-url` |
| 5 | 8px unit inherited; tight gutters, generous card padding | pinned + delegated | inherit `spacing.yaml`; padding rule via component snippet |
| 6 | radius 4px (2px chips, 6px max); elevation by tone; one sanctioned header gradient | pinned | `radius` seed + css-snippets |
| 7 | micro 80-120ms ease-out; ≤250ms; status pulse 2s; reduced-motion guard | pinned | scoped-vars + css-snippets |
| 8 | button/input/card/nav inflections; tables/toasts/modals/breadcrumbs at base | pinned + do-not-touch | css-snippets; explicit non-files |
| 9 | AA both modes, AAA dark body; ember-as-text ≈5.4:1 caution; secondary ≥4.5:1 | verification | conformance check rows |

§10 reconciliation: appendix matched the plan; no missed rows. File plan: 8 files (see
`facet-tuning-guide.md` §6 for the ship/skip table).

## 2. Seed Extraction

`theme-ember/style-guide.vars.yaml` — full listing with reasoning in
`seed-extraction.md` §6. Plus the two identity files:

```yaml
# theme-ember/style-guide.meta.yaml
name: "Ember"
slug: "ember"                       # matches theme-ember/
title: "Ember — Style Guide"
description: "Warm dark developer-tool theme: one accent, layered charcoal, unhurried motion."
base-theme: "theme-style-guide"
```

```yaml
# theme-ember/branding.yaml
name: "Ember"
logo-text: "EMBER"
font-url: "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap"
intent: "A dark-native workspace for developers that trades the usual blue-cold terminal palette for controlled warmth — the focus of a dark room lit by a single warm source. Restraint everywhere except the one accent."
perception: "This tool is calm, serious, and slightly alive. Warmth without playfulness; darkness without gloom."
audience: "Professional developers in long sessions (2+ hours), often in low ambient light, monitoring builds and editing configuration."
tone: "Quiet, precise, technical. Copy is terse; the UI never exclaims."
keywords:
  - warm
  - focused
  - nocturnal
  - precise
  - unhurried
```

## 3. Three Facet Overrides (the interesting ones)

### 3a. `style-guide.color-modes.yaml` — §3 mode strategy

```yaml
color-modes:
  dark:                             # primary; the design target
    surface: "#1a1512"              # canvas — brown-black per §3 neutral strategy
    surface-alt: "#241d18"          # elevation step 1 (tone, not shadow — §6)
    text: "var(--white)"            # #f5efe8 ≈ 14:1 on canvas (AAA, §9)
    text-secondary: "#b8ab9d"       # 5.4:1 — see contrast fix in §5 below
    text-muted: "#96897c"           # 4.6:1 — floor-adjacent, flagged in conformance
    border: "#3a2f27"               # near-1.5:1 by design (§3: structure from layering, not lines)
    border-strong: "#54463a"
  light:                            # faithful translation, no independent decisions (§3)
    surface: "var(--white)"         # warm paper
    surface-alt: "#ece4d8"
    text: "var(--black)"
    text-secondary: "#4a4038"
    text-muted: "#6f635a"
    border: "#d8ccbc"
    border-strong: "#b8a894"
```

### 3b. `style-guide.css-snippets.yaml` — §6/§7/§8 (accumulates with base)

```yaml
css-snippets:
  - name: "Ember Elevation & Header Warmth"
    slug: "ember-elevation"
    title: "Tone-based elevation + sanctioned header gradient"
    description: "Three surface steps by lightness; the one permitted radial warmth on the shell header (§6)."
    target-section: ui-elements
    body: |
      html[data-design-theme="ember"] .card {
        background: var(--surface-alt);
        border: none;                                   /* §6: no structural borders */
        border-radius: var(--radius);
        padding: var(--space-5);                        /* §5: generous internal padding */
      }
      html[data-design-theme="ember"] .card:hover {
        background: #2e251e;                            /* hover = one elevation step (§7) */
      }
      html[data-design-theme="ember"] .shell-header {
        background-image: radial-gradient(ellipse at top,
          rgba(232, 118, 58, 0.04), transparent 70%);   /* the light source — nowhere else */
      }

  - name: "Ember Buttons & Inputs"
    slug: "ember-buttons-inputs"
    title: "Primary fill / ghost secondary / recessed inputs"
    description: "§8: primary is the only saturated-fill element; inputs read as cut into the material."
    target-section: buttons
    body: |
      html[data-design-theme="ember"] .btn-primary {
        background: var(--brand-red);                   /* #e8763a */
        color: #1a1512;                                 /* near-black warm text — 5.4:1+ on ember */
        border: none;
        border-radius: var(--radius);
      }
      html[data-design-theme="ember"] .btn-secondary {
        background: transparent;
        color: var(--text);
        border: 1px solid rgba(232, 118, 58, 0.12);     /* ember-12% interactive edge (§6) */
        border-radius: var(--radius);
      }
      html[data-design-theme="ember"] .input {
        background: #14100d;                            /* recessed BELOW surface (§8) */
        border: 1px solid rgba(232, 118, 58, 0.12);
        border-radius: var(--radius);
      }
      html[data-design-theme="ember"] .input:focus-visible,
      html[data-design-theme="ember"] .btn-primary:focus-visible,
      html[data-design-theme="ember"] .btn-secondary:focus-visible {
        outline: 2px solid var(--brand-red);            /* §9 focus spec: 2px, offset 2px */
        outline-offset: 2px;
      }

  - name: "Ember Status Pulse"
    slug: "ember-status-pulse"
    title: "In-progress pulse (the coal breathing)"
    description: "§7's one expressive exception, with the §9 reduced-motion guard."
    target-section: ui-elements
    body: |
      html[data-design-theme="ember"] .status--in-progress .status-dot {
        animation: ember-pulse 2s ease-in-out infinite;
      }
      @keyframes ember-pulse {
        0%, 100% { opacity: 0.7; }
        50%      { opacity: 1.0; }
      }
      @media (prefers-reduced-motion: reduce) {
        html[data-design-theme="ember"] .status--in-progress .status-dot {
          animation: none;
          opacity: 1;                                   /* static ember dot fallback (§9) */
        }
      }
```

### 3c. `style-guide.scoped-vars.yaml` — §7 timing + per-mode accent (accumulates)

```yaml
scoped-vars:
  'html[data-design-theme="ember"]':
    motion-micro: "100ms"           # §7 band: 80-120ms
    motion-panel: "200ms"           # §7 band: 180-220ms
  'html[data-design-theme="ember"][data-color-mode="light"]':
    brand-red: "#c85a20"            # §3: accent darkened for light-mode contrast (4.6:1 on #f5efe8)
```

(`typography.yaml` and `color-palette.yaml` were also shipped — see
`typography-and-rhythm-for-tuning.md` §3 for the type classes.)

## 4. Serve Iteration

```bash
npx @noizu/styleguide serve projects/forge.dev/design/theme/
```

Round 1 punch list (console + ConfigWarnings card):

| Output | Fix |
|---|---|
| `⚠ [ember] css-snippets: 'ember-status-pulse' targets section 'status' which is not defined in page-sections` | changed `target-section: status` → `ui-elements` (base section set; we ship no `page-sections.yaml`) |
| `⚠ [ember] color-modes missing 'light' map` | light map had been left as TODO; populated per §3 (listing above) |
| Visual: derived gray ramp in token browser carries warm tint | confirms seed strategy — no action |
| Visual: H2s weak in dark mode | `font-url` was missing weight 600 — fixed (see `typography-and-rhythm-for-tuning.md` §6) |

Round 2: clean — no `✗`, no `⚠`.

## 5. Contrast Fixes (mode matrix, §9)

Measured with the WCAG one-liner (`color-theory-for-tuning.md` §5):

| Pair | Measured | §9 requirement | Action |
|---|---|---|---|
| `#f5efe8` text on `#1a1512` | 13.9:1 | AAA 7:1 dark body | pass |
| draft `text-secondary #a89684` on `#1a1512` | 4.1:1 | ≥ 4.5:1 | **fail → retuned to `#b8ab9d` = 5.4:1** (full reasoning in `color-theory-for-tuning.md` §6) |
| ember `#e8763a` as text on `#1a1512` | 5.4:1 | 4.5:1 body / 3:1 large-UI | pass, standing caution: verify any future body-size use |
| ember `#c85a20` on light `#f5efe8` | 4.6:1 | ≥ 4.5:1 | pass (barely — recorded near-the-line) |
| `#1a1512` btn text on ember fill | 5.4:1 | ≥ 4.5:1 | pass |
| focus outline vs all three dark surfaces | ≥ 4.9:1 | ≥ 3:1 | pass |
| reduced-motion emulation | pulse off, static dot shown | §9 | pass |
| forced-colors emulation | system colors untouched (no overrides fight it) | §3 mode strategy | pass |

## 6. Conformance Note (final artifact)

`projects/forge.dev/design/theme/conformance-ember.md` (from
`assets/theme-conformance-report.md`), abridged:

```markdown
# Theme Conformance — ember (2026-07-15)

Treatise: treatise-ember.md @ current · Theme: theme-ember/ (8 files) · Verdict: CONFORMANT

## Realized claims
§1 branding verbatim · §3 seeds (#f5efe8/#141110/#e8763a + 4 semantics), no secondary
hue populated · §3 modes (dark primary, light translation, light accent #c85a20 via
scoped-vars) · §4 Inter/JJB Mono, 1.2-scale classes, weight reservations · §6 radius 4px,
tone elevation, one header gradient · §7 timing vars + pulse + reduced-motion guard ·
§8 button/input/card/nav snippets; tables/toasts/modals/breadcrumbs untouched at base.

## Deviations & waivers
- text-secondary retuned #a89684 → #b8ab9d (4.1 → 5.4:1) to honor §9; stays in §3 warm band.
- Chip radius 2px NOT yet encoded (no chip component in current viewer set) — waived until a chip ships.

## Standing cautions (recheck after any seed change)
- ember as body-size text: 5.4:1 dark / large-UI only
- ember-light accent #c85a20 on paper: 4.6:1 (near the line)
- text-muted dark #96897c: 4.6:1 (near the line)

## Escalations to trl-user-experience-engineer
- none this round
```

Handoff: theme directory + conformance note to trl-react-engineer for project-local
hosting (`src/config/theme-ember/`, `npm run regen`).
