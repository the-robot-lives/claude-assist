# Theme Conformance — cockpit (2026-07-17)

Treatise-vs-YAML audit record. Lives at
`projects/therobotlearns.com/design/theme/conformance-cockpit.md`.

- **Treatise**: treatise-cockpit.md @ rev 2 (status: full)
- **Theme**: theme-cockpit/ (6 files) · base chain: theme-cockpit → theme-style-guide
- **Audited by / workflow**: uplift Stage C (theme-designer) / extract-seeds + tune-facets
- **Serve state**: legacy `generate-css` path (styleguide_serve off — public npm 404s on
  `@noizu/styleguide`). No `✗` (no error/exception). Remaining `⚠` are benign and listed in §3 row 10.

## Verdict

**CONFORMANT** (dark-mode literal color-modes maps serve-unverified; documented waivers below)

Every treatise §1-§9 commitment is realized in the seed cascade + delta facets, or explicitly
waived with rationale. The compiled CSS carries the pinned tokens (`--radius: 1px`; light
`--brand-red: #c81e6e`; dark leak-fixed `--theme-brand-red: #ff2e88`) and every `css-snippets`
selector is self-scoped under `html[data-design-theme="cockpit"]` (bleed check: 0 unscoped across
`.meter-fill`/`.keybind-footer`/`.kb-table`/`.status-chip`/`.meter-track`). The one true limitation
is structural, not a defect: the legacy path does not emit `color-modes.yaml`'s literal light/dark
maps, so those are reasoned, not serve-verified (Standing Caution §6).

## 1. Value Trace (YAML → treatise)

| File : key | Value | Treatise § | Disposition | Action taken |
|------------|-------|-----------|-------------|--------------|
| vars: white | `#c9d1d9` | §3 cool off-white ink | conformant | seed (dark-mode data ink ≈12:1) |
| vars: black | `#0e1116` | §3 cool graphite canvas | conformant | seed |
| vars: brand-red | `#c81e6e` | §3 primary accent (light magenta) | conformant | seed carries LIGHT value (dark-primary pattern) |
| vars: brand-red-light | `color-mix(var(--brand-red) 70%, surface)` | §3 / seed-trap | conformant | re-pointed off base's hard-coded Bauhaus color-mix |
| vars: success/warning/error/info | `#3fb950`/`#d29922`/`#f85149`/`#58a6ff` | §3/§9 GitHub-dark set | conformant | seeds |
| vars: font-sans / font-mono | Inter / JetBrains Mono | §4 dual system | conformant | seeds; match branding `font-url` |
| vars: radius | `1px` | §6 (0-1px) | conformant | seed → compiled `--radius: 1px` |
| scoped-vars: brand-red(dark) + -light/-mid | `#ff2e88` + color-mix | §3/§6 signature magenta + dark leak fix | conformant | dark override (compiled `--theme-brand-red: #ff2e88`) |
| color-modes: light/dark maps | pale `#eef1f4` / graphite `#0e1116` | §3 mode strategy | conformant (serve-unverified) | authored both maps |
| css-snippets ×6 | focus/motion, pane, action-key, data-table, meter, footer/status | §6/§7/§8/§9 | conformant | self-scoped, accumulate on base |
| branding: name…keywords | verbatim | §1 | conformant | mirrors §1/§10 |

## 2. Claim Coverage (treatise → YAML)

| § | Claim (condensed) | Status | Where encoded / rationale |
|---|-------------------|--------|---------------------------|
| §1 | Instrument/dense/signal identity | realized | branding.yaml (intent/perception/tone/keywords verbatim) |
| §2 | Anti-ref: NOT retro amber CRT; NOT rounded consumer cards | realized | modern cool seeds + flat pane (no shadow, radius 1px); confirmed in renders 03/14/17 |
| §3 | Cool graphite + ONE magenta signal + four status hues | realized | seeds + scoped-vars |
| §3 | "Fifth decorative color is a bug" (magenta off semantic axis) | realized (exclusion) | brand-blue/brand-yellow deliberately NOT used on chrome (Standing Caution) |
| §4 | Dual mono(data)+grotesk(labels); no serif | realized | font seeds + `.data-table`/`.meter` mono, grotesk `thead th` labels |
| §5 | Tight density (4px unit, 1.35 lh) | realized (component-level) | tight padding in table/footer/meter snippets; global `unit` left to base (waiver §5) |
| §6 | Radius 0-1px; flat/box-drawn; active-pane magenta border; overlay shadow only | realized | radius seed + `.pane`/`.pane.active` + color-modes `shadow-color` reserved for modal |
| §7 | Motion 140/200ms + reduced-motion | realized | `--motion-micro`/`--motion-meter` + `prefers-reduced-motion` guards |
| §8 | Action key, panes, keybind footer, selected-row bar, status chip | realized | 6 css-snippets |
| §8 | k9s `:`-prompt filter input | unrealized (render-only) | deferred — add `.cmd-prompt` snippet in a future pass (low priority; Deviations §5) |
| §9 | AAA data in dark; glyph+color status; magenta focus; reduced-motion | realized | contrast §3/§4; `.status-chip` (color+glyph); focus snippet; motion guards |

## 3. Mode-Verification Matrix Results

| # | Check | Light | Dark | HC / reduced-motion | Notes |
|---|-------|-------|------|---------------------|-------|
| 1 | Body/data text vs surface (AAA committed) | PASS ≈13.8:1 | PASS ≈12:1 | — | data AAA in dark per §9 |
| 2 | Secondary/muted text (≥4.5:1) | PASS 8.3 / 5.3 | PASS 5.9 / 4.8 | — | muted just clears floor in dark |
| 3 | Accent as UI/large (≥3:1; not body) | PASS ≈5:1 | PASS ≈6:1 | — | magenta reserved for UI/large per §9 |
| 4 | Semantic states ≥3:1 + not hue-alone | PASS | PASS | glyph present | `.status-chip` pairs color+glyph |
| 5 | Meaningful borders (≥3:1) | PASS (border-strong ≈4.1) | PASS (border-strong ≈3.9) | — | resting `border` #30363d ≈1.4:1 waived (decorative) |
| 6 | Focus indicator visible (≥3:1, §9) | PASS | PASS | — | 2px magenta outline, never removed |
| 7 | Mode distinctness | — | PASS | — | pale #eef1f4 vs graphite #0e1116 (literal maps serve-unverified) |
| 8 | Reduced-motion per §9 | — | — | PASS | meter/button transitions dropped |
| 9 | Exclusions sweep (no amber CRT / no Bauhaus accent leak) | PASS | PASS | — | dark scoped-vars re-point brand-red → magenta |
| 10 | Validator (no ✗, ⚠ explained) | PASS | PASS | — | ⚠ = `target-section` advisories + `font-size-base` fallback (same as shipped siblings; CSS still emits, verified) |

## 4. Contrast Measurements (near-the-line pairs)

| Pair | Mode | Required | Measured | Result |
|------|------|----------|----------|--------|
| warning `#d29922` on `#0e1116` | dark | ≥4.5 (text) / ≥3 (large) | ≈4.7:1 | PASS — keep at label size+ (Caution) |
| magenta `#ff2e88` on `#0e1116` | dark | ≥3 (UI/large) | ≈6:1 | PASS (not body — treatise-consistent) |
| magenta `#c81e6e` on `#eef1f4` | light | ≥3 (UI/large) | ≈5:1 | PASS |
| text-muted `#7d8590` on `#0e1116` | dark | ≥4.5 | ≈4.8:1 | PASS (narrow) |
| resting border `#30363d` on `#0e1116` | dark | ≥3 (meaningful) | ≈1.4:1 | WAIVED — decorative rule (see §5) |

## 5. Deviations & Waivers

| Item | Treatise clause | Deviation | Rationale | Approved by |
|------|-----------------|-----------|-----------|-------------|
| Global `unit` seed | §5 4px base unit | Left to base default; density via component padding | Overriding the global unit ripples the base spacing scale and can break inherited components; cockpit's density is realized where it matters (tables/footer/meters) | Stage C |
| Resting `border` #30363d | §3 "dividers stay legible" / §6 | Sub-3:1 against canvas | Deliberate GitHub-dark idiom; grouping conveyed by tonal fill + `border-strong` (≥3.9:1) + magenta active-pane border for the meaningful boundary | Stage C |
| k9s `:`-prompt input | §8 inputs | Not encoded as a css-snippet | Render-only element this pass; add `.cmd-prompt` (magenta caret) in a future tuning pass | Stage C (deferred) |
| Light-mode magenta | §3 modes (`#c81e6e`) | Carried by the seed, not a `standard`-section scoped-var | Dark-primary pattern (mirrors theme-npl-minimal): seed = light value, dark scoped-var = signature; avoids relying on a possibly-inert light alias | Stage C |

## 6. Standing Cautions

| Caution | Trigger to recheck |
|---------|--------------------|
| `color-modes.yaml` literal light/dark maps are serve-unverified on the legacy path (only white/black seed cascade resolves modes there) | Next `npx @noizu/styleguide serve` availability |
| brand-blue / brand-yellow left on the base Bauhaus dark cascade (reserved / off-chrome — §3 one-signal discipline) | If any future chrome element starts using brand-blue/-yellow |
| warning `#d29922` ≈4.7:1 (near-the-line) | Any change to the `warning` seed or using it below label size |
| resting `border` #30363d sub-3:1 | If it's ever used as a *sole* meaningful boundary (use `border-strong`/magenta instead) |

## 7. Escalations to trl-user-experience-engineer

| # | Issue | § | Status |
|---|-------|---|--------|
| 1 | Base `theme-style-guide/style-guide.scoped-vars.yaml` brightens dark brand tints from literal Bauhaus hex (`#e20613`/`#0047ab`/`#f5c518`) not `var(--brand-*)` — every non-Bauhaus theme reverts at night | base cascade | Already tracked in conformance-npl-minimal.md §7; cockpit works around it in its own scoped-vars. No new escalation. |

## 8. Session History

| Date | Workflow | Summary | Verdict after |
|------|----------|---------|---------------|
| 2026-07-17 | extract-seeds + tune-facets (Stage C) | New theme from treatise rev 2; 5 terminal-mocked renders at medium quality (429 storm forced high→medium tier drop); seeds + dark leak-fix scoped-vars + both color-modes maps + 6 self-scoped css-snippets; legacy validate clean (0 bleed) | CONFORMANT (color-modes maps serve-unverified) |
