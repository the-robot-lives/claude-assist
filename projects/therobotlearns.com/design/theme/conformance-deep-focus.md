# Theme Conformance — deep-focus (2026-07-17)

Treatise-vs-YAML audit record. Lives at
`projects/therobotlearns.com/design/theme/conformance-deep-focus.md`.

- **Treatise**: treatise-deep-focus.md @ rev 2 (status: full)
- **Theme**: theme-deep-focus/ (6 files) · base chain: theme-style-guide
- **Audited by / workflow**: Loom (Stage C, uplift pipeline) / tune-facets + render-reflect
- **Serve state**: legacy `generate-css` path (styleguide_serve off) — exit 0, no error/exception;
  only benign ⚠ (`target-section 'cards'/'buttons'/'navigation' not in page-sections`, same
  class the base's own `card-glow` emits; `font-size-base` fallback, inherited). No ✗/⚠ severity
  split on this path.

## Verdict

**CONFORMANT** (dark literal-map verification deferred)

The shipped theme carried a silent **seed trap**: accents were set on bare `red`/`blue`/`yellow`
keys, which the base does not wire as accent-driving, so the treatise's teal §3 accent never
actually applied. Stage C moved them to `brand-red`/`brand-blue`/`brand-yellow`, re-pointed each
`-light`/`-mid` sibling to `var(--brand-*)`, added the dark brand-tint re-point, pointed HUI
focus/controls at the teal accent (§8/§9), and added the missing `font-url`. Compiled CSS now
shows `html[data-design-theme="deep-focus"]` owning `--brand-red: #14b8a6` (light) plus three
dark teal re-points, with zero unscoped bleed. All treatise §1/§3/§4/§6/§8/§9 pins are realized
or explicitly waived. The one open item is verification-tooling, not design: the legacy path does
not emit `color-modes.yaml`'s literal light/dark maps, so dark-mode literal conformance is
asserted by design + seed cascade, not measured (see §6 Standing Cautions).

## 1. Value Trace (YAML → treatise)

| File : key | Value | Treatise § | Disposition | Action taken |
|------------|-------|-----------|-------------|--------------|
| vars : white | `#e2e8f0` | §3 lightest | conformant | kept |
| vars : black | `#0a0e1a` | §3 darkest (navy, not #000) | conformant | kept |
| vars : brand-red | `#14b8a6` | §3 single teal accent | conformant | **seed-trap fix** (was bare `red`) |
| vars : brand-red-light/-mid | `color-mix(var(--brand-red) 12/20%)` | §3 | conformant | re-pointed off old hex |
| vars : brand-blue (+light/mid) | `#38bdf8` | §3 sky / info-aligned | conformant (reserved) | moved off bare `blue`; off-chrome |
| vars : brand-yellow (+light/mid) | `#fbbf24` | §3 amber / warning-aligned | conformant (reserved) | moved off bare `yellow`; off-chrome |
| vars : success/warning/error/info | mint/amber/rose/sky | §3 semantics | conformant | kept (set directly) |
| vars : font-sans/-mono | IBM Plex Sans/Mono | §4 | conformant | kept; now matched by `font-url` |
| vars : radius | `6px` | §6 soft-technical | conformant | kept |
| vars : hui-focus-ring/control/field/switch/radio | `var(--brand-red)` | §8/§9 teal focus | conformant | **delta** (base defaulted brand-blue) |
| scoped-vars : brand-red dark (+light/mid) | teal `color-mix` 75/18/30% | §3 mode + §6 | conformant | **new** dark re-point (base-defect workaround) |
| css-snippets : tl-answer/chip/flashcard/nav-active | self-scoped | §8 sample elements | conformant | **new**, all under `html[data-design-theme="deep-focus"]` |
| branding : font-url | IBM Plex CSS2 URL | §1/§4 | conformant | **new** (was missing) |
| color-modes : light/dark maps | full maps | §3 modes | conformant (dark unverified on legacy path) | kept |

## 2. Claim Coverage (treatise → YAML)

| § | Claim (condensed) | Status | Where encoded / rationale |
|---|-------------------|--------|---------------------------|
| §1 | identity/intent/perception/tone/keywords | realized | branding.yaml + meta.yaml |
| §3 | navy canvas + single teal accent | realized | black seed + brand-red teal (verified in CSS) |
| §3 | cool-leaning semantics (mint/amber/rose/sky) | realized | vars Semantic group |
| §3 | dark primary; light = faithful translation | realized | color-modes maps (dark literal map unverified — caution) |
| §3 | blue serves info, not a 2nd brand hue | realized | info set directly; brand-blue off-chrome |
| §4 | IBM Plex Sans + Mono, ~1.2 scale | realized (fonts) / waived (scale) | seeds + font-url; type scale left at base (acceptable) |
| §5 | 8px unit, airy reading padding | realized | inherited from base |
| §6 | 6px radius; tonal 3-step elevation; overlay shadow only | realized | radius seed + color-modes surface steps + flashcard snippet shadow |
| §7 | 150–220ms ease; reduced-motion guard | waived | base motion acceptable; not custom-encoded |
| §8 | teal primary fill, recessed inputs, borderless cards, teal-rail nav | realized | brand-red cascade + css-snippets samples |
| §9 | 2px teal focus ring on every focusable | realized | hui-focus-ring-color re-pointed to teal |
| §9 | contrast floors (body AAA in dark) | realized (by design) | see §3/§4 below; literal dark map unverified |

## 3. Mode-Verification Matrix Results

| # | Check | Light | Dark | HC / reduced-motion | Notes |
|---|-------|-------|------|---------------------|-------|
| 1 | Body vs surface (AAA if committed) | PASS | PASS (design) | — | dark #cbd5e1/#0a0e1a ≈13:1; literal dark map unverified on legacy path |
| 2 | Secondary/muted text | PASS | EDGE | — | text-secondary ≈4.3:1 (large/secondary only); text-muted ≈3:1 decorative/disabled only |
| 3 | Accent as text/UI | PASS | PASS | — | teal on navy ≈5:1 (large/UI) |
| 4 | Semantic not hue-alone | PASS | PASS | — | labels/icons accompany semantic color |
| 5 | Meaningful borders ≥3:1 | WAIVED | WAIVED | — | §6: structure via tonal navy layering, not lines (intentional ~1.5:1) |
| 6 | Focus indicator per §9 | PASS | PASS | — | 2px teal ring; hui-focus-ring-color = teal |
| 7 | Mode distinctness | — | DEFER | — | maps present; genuine distinctness not measurable on legacy path |
| 8 | Reduced-motion per §9 | — | — | INHERIT | base handles; not custom-encoded |
| 9 | Exclusions sweep (no #000, no gradient/glow, single accent) | PASS | PASS | — | canvas #0a0e1a not #000; no dc2626 bleed; snippets flat |
| 10 | Validator (no error/exception) | PASS | PASS | — | legacy generate-css exit 0; ⚠ explained above |

## 4. Contrast Measurements (near-the-line pairs)

| Pair | Mode | Required | Measured | Result |
|------|------|----------|----------|--------|
| body #cbd5e1 on canvas #0a0e1a | dark | 4.5:1 (AAA 7:1 committed) | ≈13:1 | PASS (AAA) |
| text-secondary #64748b on #0a0e1a | dark | 4.5:1 (large 3:1) | ≈4.3:1 | EDGE — large/secondary only (per §9) |
| text-muted #475569 on #0a0e1a | dark | — | ≈3:1 | decorative/disabled only (per §9) |
| teal #14b8a6 on #0a0e1a | dark | 3:1 (large/UI) | ≈5:1 | PASS — verify if used body-size |

## 5. Deviations & Waivers

| Item | Treatise clause | Deviation | Rationale | Approved by |
|------|-----------------|-----------|-----------|-------------|
| HUI focus/controls | §8/§9 | re-pointed base `brand-blue` → teal | treatise commits teal focus/active-controls; base default clashed | treatise §9 |
| Type scale | §4 (~1.2 tight) | left at base scale | fonts carry the voice; base scale acceptable, no drift observed | Stage C |
| Motion | §7 (150–220ms) | inherit base | base motion within acceptable band | Stage C |
| Low-contrast borders | §6 | ~1.5:1 borders | intentional — separation by tone-layering, not lines | treatise §6 |

## 6. Standing Cautions

| Caution | Trigger to recheck |
|---------|--------------------|
| brand-blue / brand-yellow dark leak — base scoped-vars brightens them from literal Bauhaus hex (#0047ab/#f5c518) in dark, not `var(--brand-*)`. Inert today (both off-chrome: info/warning set directly, focus/controls teal). | If any chrome ever consumes `brand-blue`/`brand-yellow` tints in this theme, add their dark re-point to `style-guide.scoped-vars.yaml` (mirror the brand-red block). |
| Dark `color-modes` literal maps UNVERIFIED — legacy `generate-css` does not emit them; only the black/white seed cascade resolves modes on this path. | Re-run `npx @noizu/styleguide serve` when the private registry is available; confirm dark literal map + mode distinctness (matrix rows 1/7). |
| text-secondary #64748b ≈4.3:1 (AA edge). | Any canvas darkening or use of text-secondary at body size. |

## 7. Escalations to trl-user-experience-engineer

| # | Issue | § | Status |
|---|-------|---|--------|
| 1 | Base-cascade dark brand-tint defect: `theme-style-guide/style-guide.scoped-vars.yaml` brightens `brand-*` in dark from literal hex, not `var(--brand-*)`, so every non-red theme leaks Bauhaus red/navy/gold in dark until each adds a per-theme scoped-vars delta. | §3 mode | Pipeline-wide escalation pending against the base file; worked around per-theme (do not fix base from Stage C). |

## 8. Session History

| Date | Workflow | Summary | Verdict after |
|------|----------|---------|---------------|
| 2026-07-17 | Stage C tune (render/reflect + implement) | seed-trap fix (bare→brand-*), teal HUI focus/controls, dark scoped-vars re-point, `font-url`, 4 self-scoped sample snippets; 5 terminal-surface renders @ quality medium (high tier 429-stormed) | CONFORMANT (dark literal-map verification deferred) |
