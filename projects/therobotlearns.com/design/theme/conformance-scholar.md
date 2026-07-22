# Theme Conformance — scholar (2026-07-17)

Treatise-vs-YAML audit record. Lives at
`projects/therobotlearns.com/design/theme/conformance-scholar.md`.

- **Treatise**: treatise-scholar.md @ revision 2 (status: full)
- **Theme**: theme-scholar/ (7 files) · base chain: theme-scholar → theme-style-guide
- **Audited by / workflow**: Loom (uplift Stage C) / tune-facets + audit-theme-vs-treatise
- **Serve state**: legacy `generate-css` path (styleguide_serve=off); exit 0, no error/exception.
  Only pre-existing **base** ⚠ warnings emitted (empty HUI vars groups; base `card-glow`/`demo`
  snippets targeting undefined page-sections) — none from theme-scholar files.

## Verdict

**DRIFTED → remediated**

The shipped Stage-A theme carried three real drifts, all fixed this pass: (1) the **seed trap** —
`style-guide.vars.yaml` set the accent on bare `red`/`blue`/`yellow`, which the base does not wire
as accent keys, so the indigo accent was a **silent no-op** and all chrome rendered the base
Bauhaus red; (2) **`branding.yaml` was missing `font-url`**, so Inter/JetBrains Mono never loaded;
(3) interactive controls (focus ring, switches, field-focus, radios) inherited the base
`var(--brand-blue)`, rendering blue rather than the treatise's indigo. Post-fix, the compiled CSS
resolves `html[data-design-theme="scholar"] { --brand-red:#6366F1; --info:#3b82f6; --radius:4px;
--hui-control-color:var(--brand-red) }` and a scholar-scoped dark re-point of brand-red to indigo.
Light mode is fully verified from the compiled CSS; the authored dark `color-modes` map is
unverifiable on the legacy path (documented gap below), so dark-mode conformance is asserted only
for the seed-cascade fallback, not the literal dark map.

## 1. Value Trace (YAML → treatise)

| File : key | Value | Treatise § | Disposition | Action taken |
|------------|-------|-----------|-------------|--------------|
| vars : white | `#fafafa` | §3 near-white canvas | conformant | kept |
| vars : black | `#111118` | §3 near-black ink | conformant | kept |
| vars : brand-red | `#6366F1` | §3 single indigo accent | conformant | **moved from bare `red` (no-op) → `brand-red`** |
| vars : brand-red-light/-mid | `color-mix(var(--brand-red) 12/20%, surface)` | §3/§6 tints | conformant | re-pointed off base's baked-hex color-mix |
| vars : success/warning/error/info | `#22c55e`/`#eab308`/`#ef4444`/`#3b82f6` | §3 semantic set | conformant | set directly (independent of off-chrome brand-blue/yellow) |
| vars : font-sans / font-mono | Inter / JetBrains Mono | §4 | conformant | kept; now matched by branding `font-url` |
| vars : radius | `4px` | §6 crisp-soft | conformant | kept |
| vars : hui-focus-ring-color | `color-mix(var(--brand-red) 35%, transparent)` | §7/§9 2px indigo ring @~0.35α | conformant | re-pointed off base `brand-blue` |
| vars : hui-control-color / -field-focus-border / -switch-track-on-bg / -radio-option-* | `var(--brand-red)` | §8 indigo controls | conformant | re-pointed off base `brand-blue` |
| scoped-vars : brand-red (dark) | `color-mix(#6366F1 75/18/30%, white/surface)` | §3 dark indigo (#818CF8) | conformant | re-point vs base literal `#e20613` dark leak |
| branding : font-url | Inter+JetBrains Mono Google Fonts | §1/§4 | conformant | **added (was missing)** |
| color-modes : surface-warning/-danger | `var(--warning-tint)`/`var(--error-tint)` | §3 semantic tints | conformant | re-pointed off now-removed `--yellow-light`/`--red-light` |
| css-snippets : tl-quiz-option/-rubric-row/-stat-tile/-nav-active | self-scoped `html[data-design-theme="scholar"] …` | §8 component inflections | conformant | new; verified self-scoped in compiled CSS |

## 2. Claim Coverage (treatise → YAML)

| § | Claim (condensed) | Status | Where encoded / rationale |
|---|-------------------|--------|---------------------------|
| §1 | Identity, Inter voice, keywords | realized | branding.yaml (+font-url), meta.yaml |
| §3 | Near-white #fafafa / near-black #111118 monochrome | realized | vars white/black |
| §3 | Single indigo accent #6366F1; accent count = 1 | realized | vars brand-red; brand-blue/yellow left off-chrome |
| §3 | Neutral near-gray with faint **cool** cast, ramp inherited | realized (intentional inheritance) | base slate surfaces + gray text supply the cool cast; see §5 |
| §3 | Semantic set success/warning/error/info | realized | vars Semantic group (set directly) |
| §3 | Light primary; dark = faithful translation, indigo→#818CF8 | realized light / **partially verified dark** | color-modes dark map + scoped-vars dark re-point; map unverifiable on legacy path |
| §4 | Inter + JetBrains Mono, ~1.2–1.25 scale | realized (fonts) / inherited (scale) | vars fonts + branding font-url; default scale kept |
| §6 | 4px radius; thin structural borders; flat, single soft overlay shadow | realized | vars radius; borders/elevation via base cascade + snippets |
| §7 | 2px indigo focus ring ~0.35α; ≤200ms motion | realized (ring) / inherited (motion) | hui-focus-ring-color; base transitions |
| §8 | Indigo primary fill, bordered ghost secondary, bordered inputs/cards, indigo-underline active nav | realized | hui-* re-points + css-snippets (quiz option, rubric row, stat tile, nav-active) |
| §9 | WCAG 2.2 AA both modes; indigo-on-white ~4.6:1 near line | realized light / caution | see §4 Contrast; standing caution on indigo body text |

## 3. Mode-Verification Matrix Results

| # | Check | Light | Dark | HC / reduced-motion | Notes |
|---|-------|-------|------|---------------------|-------|
| 1 | Body text vs surface (AAA) | PASS (~17:1) | not verifiable | n/a v1 | ink #111118 on #fafafa |
| 2 | Secondary/muted text | PASS | not verifiable | — | gray ramp inherited |
| 3 | Accent as UI (≥3:1) / body (≥4.5:1) | PASS UI / caution body | not verifiable | — | indigo body text must use #4f46e5 |
| 4 | Semantic classes not hue-alone | PASS | not verifiable | — | renders show green/amber as markers beside labels |
| 5 | Meaningful borders (≥3:1) | PASS | not verifiable | — | thin gray borders (theme uses lines) |
| 6 | Focus indicator (2px indigo ring) | PASS | not verifiable | — | hui-focus-ring-color re-pointed to indigo |
| 7 | Mode distinctness | — | not verifiable | — | color-modes dark map not emitted on legacy path |
| 8 | Reduced-motion per §9 | — | — | inherited | base guard |
| 9 | Treatise exclusions (no serif/gradient/glow/2nd accent) | PASS | — | — | no hex in prompts; single indigo confirmed in CSS |
| 10 | Validator (no ✗; ⚠ explained) | PASS | — | — | legacy path: no error/exception; base-only ⚠ |

## 4. Contrast Measurements (near-the-line pairs)

| Pair | Mode | Required | Measured | Result |
|------|------|----------|----------|--------|
| ink #111118 on #fafafa | light | 4.5:1 (AAA 7:1) | ~17:1 | PASS |
| indigo #6366F1 as text on #fafafa | light | 4.5:1 body | ~4.6:1 | PASS (near line — prefer #4f46e5 for body) |
| text-link #4f46e5 on #fafafa | light | 4.5:1 | ~5.9:1 | PASS |
| indigo dark #818CF8 on #111118 | dark | 4.5:1 | ~6:1 (treatise) | UNVERIFIED on legacy path |

## 5. Deviations & Waivers

| Item | Treatise clause | Deviation | Rationale | Approved by |
|------|-----------------|-----------|-----------|-------------|
| Neutral gray ramp | §3 "ramp inherited, not redefined" | No local neutral ramp | **Intentional** — base slate surfaces + gray text already deliver §3's "faint cool cast"; a local ramp would duplicate the base. Stage-B flag resolved as documented-inheritance. | Loom (Stage C) |
| Dark color-modes map | §3 dark translation | Not emitted / unverifiable on legacy path | Legacy `generate-css` does not emit `color-modes` literal maps; full verification needs `npx @noizu/styleguide serve` (unavailable). Seed-cascade dark fallback looks reasonable. | Loom (Stage C) |

## 6. Standing Cautions

| Caution | Trigger to recheck |
|---------|--------------------|
| brand-blue / brand-yellow retain the base literal-hex dark leak (revert to navy/gold in dark) | If either is ever put on working chrome. Currently OFF-CHROME (info/warning set directly; controls on indigo) so the leak is inert. |
| Indigo #6366F1 as body text is only ~4.6:1 (just over AA) | Any lightening of the accent or the #fafafa canvas. Use text-link #4f46e5 (~5.9:1) for indigo body copy. |
| Dark indigo pairing (#818CF8 on #111118 ~6:1) unverified | When the serve path returns — verify the literal dark map. |

## 7. Escalations to trl-user-experience-engineer

| # | Issue | § | Status |
|---|-------|---|--------|
| 1 | Base `theme-style-guide/style-guide.scoped-vars.yaml` brightens brand-red/-blue/-yellow for dark from literal Bauhaus hex (`#e20613`/`#0047ab`/`#f5c518`), not `var(--brand-*)` — every non-red theme silently reverts in dark | §3 | Known base-cascade defect; per-theme scoped-vars re-point applied as interim (this theme re-points brand-red). Base fix out of Stage C scope. |
| 2 | Base wires accents on `brand-red`/`brand-blue`/`brand-yellow`, not bare `red`/`blue`/`yellow`; shipped Stage-A themes used bare keys (silent no-op) | §3 | Pattern-level; scholar fixed here. Flagged for other pre-v3 themes. |

## 8. Session History

| Date | Workflow | Summary | Verdict after |
|------|----------|---------|---------------|
| 2026-07-17 | uplift Stage C (tune-facets) | Fixed seed trap (accent→brand-red +light/-mid re-point), added missing font-url, re-pointed hui controls + dark brand-red to indigo, added §8 css-snippets, fixed color-modes semantic tint refs. Rendered 5 screens (7+1 API calls), verified tokens from compiled CSS. | DRIFTED → remediated |
