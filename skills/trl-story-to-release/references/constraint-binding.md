# Constraint Binding

Phase 2: turn the project's style guide, design tokens, and the story's linked personas into an explicit, frozen constraint checklist. Implementation (phase 4) ticks it; verification (phase 5) audits it. Deviations are logged, never silently absorbed.

> This skill never *authors* style guides. For creating or evolving one, see **trl-user-experience-engineer** (`process/style-guide-construction.md`, `outputs/engine-styleguide.md` there).

## Step 1 — Locate the Style Sources

Search in priority order; record exactly what was found in the checklist header:

| Priority | Location pattern | Format | Notes |
|----------|------------------|--------|-------|
| 1 | `design/theme/theme-*/style-guide.{meta,vars,color-modes}.yaml`, `branding.yaml` | Engine YAML | styleguide-engine seed tokens — the most authoritative token source |
| 2 | `frontend/src/config/` theme YAML / token files | YAML/TS | Project-local engine config |
| 3 | `docs/style-guide*.md`, `design/**/style-guide*.md` | Markdown | Prose style guide; extract tables and token lists |
| 4 | CSS custom properties / Tailwind config / design-token JSON | Code | Fallback token source |
| — | Nothing found | — | Binding is **DEGRADED**: only accessibility floor + persona constraints apply; state this in the header and recommend trl-user-experience-engineer |

## Step 2 — Scope to the Story's Surface

Do not transcribe the whole style guide. From `grooming.md` and the screen inventory, list the surface (screens, component types, copy, motion), then extract only constraints that touch it. A dashboard story pulls card, chart, empty-state, and page-shell rules — not the marketing-hero rules.

## Step 3 — Extract Style-Guide Constraints (SG-*)

Each constraint must be *checkable*: a pass condition an auditor can evaluate against the built UI. Extraction patterns:

| Style-guide material | Becomes constraint | Pass condition shape |
|----------------------|--------------------|----------------------|
| Color tokens | "Surface X uses token Y, no ad-hoc hex" | grep built CSS/JSX for non-token colors on the surface |
| Type scale | "Headings/body use scale steps N" | computed sizes match scale |
| Spacing system | "Gaps/padding from the spacing scale (e.g. 8px grid)" | no off-scale magic numbers |
| Component variants | "Use sanctioned `<Card>`/`<Btn>` variants; no new variants" | components imported from the design system, variant props sanctioned |
| States | "Interactive elements implement hover/focus/active/disabled per guide" | each state visually present |
| Motion | "Transitions within guide durations; respect reduced-motion" | durations in range; `prefers-reduced-motion` honored |
| Voice & tone | "Copy follows tone (e.g. plain, no jargon)" | copy review against tone rules |

Every SG row cites file + key/section (e.g. `style-guide.vars.yaml: vars.groups.colors.accent`).

## Step 4 — Derive Persona Constraints (PC-*)

Read each linked persona file and translate its fields into implementation constraints:

| Persona field | Signal | Derived constraint pattern |
|---------------|--------|----------------------------|
| Technical Level: Novice | No tool-specific vocabulary can be assumed | Labels self-explanatory; empty states teach; no unexplained jargon or bare acronyms |
| Technical Level: Expert | Efficiency dominates | Keyboard access, dense-info tolerance, no forced wizards |
| Demographics: role/device context | Where/how they work | Minimum viewport, touch targets ≥44px, offline/latency tolerance |
| Frustrations | Pains the product must not reproduce | Each frustration → a "must not" constraint on this surface |
| Goals / Job to Be Done | The outcome the surface must serve | Primary action prominent within N interactions |
| Accessibility notes (if any) | Hard requirements | Elevate to the AF floor |

## Step 5 — Accessibility Floor (AF-*)

Always included, regardless of style guide or personas — and it *beats* the style guide on conflict:

| ID | Constraint | Pass condition |
|----|-----------|----------------|
| AF-1 | WCAG 2.2 AA on the touched surface | 0 critical/serious axe violations |
| AF-2 | Contrast ≥4.5:1 body, ≥3:1 large text/UI | measured on final palette |
| AF-3 | Full keyboard operability + visible focus | keyboard-only walkthrough completes |
| AF-4 | Meaningful accessible names/labels | screen-reader pass over interactive elements |
| AF-5 | `prefers-reduced-motion` respected | animations disabled/reduced under the media query |

## Step 6 — Merge, Resolve, Freeze

Merge all rows under the precedence table (SKILL.md → Constraint-Source Precedence). Log every conflict and its winner. Then **freeze**: during phases 4–5 the checklist is append-only via the deviation log — constraints are never edited to match what got built.

| Freeze rule | Rationale |
|-------------|-----------|
| Constraints immutable after phase 2 | Prevents "grade your own homework" drift |
| Deviations logged with justification | Some deviations are right (guide gap, criterion conflict) — but they must be visible |
| Unjustifiable deviation → fix-required | Caught in phase 5 audit |
| Guide itself is wrong → upstream note | File against the style guide owner; do not fork locally |

## Worked Example

Story US-042 (metrics dashboard, persona P-003 novice first-time admin). Style sources found: `design/theme/theme-admin/style-guide.vars.yaml`, `style-guide.color-modes.yaml`, `branding.yaml` (binding: FULL).

Style-guide excerpt (as found):

```yaml
# design/theme/theme-admin/style-guide.vars.yaml (excerpt)
vars:
  groups:
    colors: { primary: "#1a56db", accent: "#0e9f6e", danger: "#e02424" }
    semantics: { radius: "6px", font-family: "Inter, sans-serif" }
# branding.yaml (excerpt)
tone: "plain-spoken, confidence-building; avoid ops jargon on admin surfaces"
```

Resulting checklist (abridged):

| ID | Constraint | Source (rank) | Pass condition |
|----|-----------|---------------|----------------|
| AF-2 | Metric text contrast ≥4.5:1 in both color modes | Floor (2) | measured light + dark |
| PC-1 | Metric names self-explanatory to a novice — no bare "p95", "QPS" | P-003 §Technical Level (3) | copy review: each metric label plain-English with unit |
| PC-2 | Empty/unavailable state explains *what to do next*, not just "no data" | P-003 §Frustrations ("dashboards that assume context") (3) | empty state includes one action/link |
| PC-3 | Health verdict visible without scrolling at 1366×768 | P-003 §Job to Be Done (3) | above-the-fold check at persona viewport |
| SG-1 | Cards use `StyleGuideCard` sanctioned variants; no bespoke card CSS | vars.yaml + component inventory (4/5) | imports audited |
| SG-2 | Status colors from tokens: accent=healthy, danger=failing; no ad-hoc hex | vars.groups.colors (4) | grep for hex literals on surface |
| SG-3 | Copy tone plain-spoken per branding.yaml | branding.yaml:tone (4) | tone review |

Conflict log: PC-1 (plain labels) vs the ops convention of "p95 latency" → persona rank beats convention; label rendered "Slowest responses (p95)" — term kept but explained. **Checklist FROZEN.**
