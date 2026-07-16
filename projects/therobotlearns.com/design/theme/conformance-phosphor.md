# Theme Conformance — phosphor (2026-07-17)

Treatise-vs-YAML audit record. Lives at
`projects/therobotlearns.com/design/theme/conformance-phosphor.md`.

- **Treatise**: treatise-phosphor.md @ rev 2 (status: full)
- **Theme**: theme-phosphor/ (6 files) · base chain: theme-phosphor → theme-style-guide
- **Audited by / workflow**: Stage C agent (trl-theme-designer) / extract-seeds + tune-facets
- **Serve state**: legacy `generate-css` path (styleguide_serve=off) — exit 0, no error/exception.
  Remaining ⚠ are benign base-pattern noise (target-section slots + font-size fallback), listed in §3/§5.

## Verdict

**CONFORMANT** (dark = the one true mode, fully realized and compiled-CSS-verified monochrome amber;
light = faithful secondary fallback, serve-unverified).

Every treatise §3/§4/§6 seed and §7/§8/§9 inflection is encoded and verified in the compiled CSS
(`/tmp/design-system.generated.phosphor.css`): the phosphor `.dark` block resolves surface `#140c00`,
all three brand families to amber `#ffb000`, success `#ffd050`, error `#ff5a3c`, info `#c88a00`, with
**no** Bauhaus/navy/gold/green literal leaking from the base's dark cascade. The image renders confirm
the soft signals (monochrome amber, near-black void, mono face, box-drawing chrome, reverse-video, the
single red break). Two verification gaps remain, neither a treatise violation: (1) the legacy path does
not emit `color-modes.yaml`'s literal light/dark maps, so dark/light *maps* are reasoned, not
serve-verified; (2) light mode is a deliberately-secondary "paper terminal" fallback (§3) with
marginal accent contrast on cream — documented, not remediated.

## 1. Value Trace (YAML → treatise)

| File : key | Value | Treatise § | Disposition | Action taken |
|------------|-------|-----------|-------------|--------------|
| vars : white | `#ffb000` | §3 (amber ramp lightest) | conformant | re-seed so gray-* ramp becomes amber |
| vars : black | `#140c00` | §3 (warm near-black) | conformant | re-seed dark end |
| vars : brand-red | `#ffb000` | §3 (single amber accent) | conformant | primary voice |
| vars : brand-blue / brand-yellow | `#ffb000` | §3 (monochrome — no 2nd hue) | conformant | collapsed to amber so base HUI controls/focus/tabs cannot emit navy/gold |
| vars : brand-*-light | `color-mix(var(--brand-*) 70%, surface)` | §3/§6 | conformant | seed-trap fix (re-point off literal Bauhaus hex) |
| vars : success/warning/error/info | `#ffd050`/`#ffb000`/`#ff5a3c`/`#c88a00` | §3 semantic mapping | conformant | amber intensities + the one red break |
| vars : font-sans / font-mono | `'IBM Plex Mono',…` | §4 (mono-primary) | conformant | font-sans deliberately = mono; no proportional face |
| vars : font-size-base | `var(--size-md)` | §4 | conformant | pin base size (silences font-token ⚠); flat 1.15 scale deferred (see §5) |
| vars : line-height-base | `1.4` | §4 (dense rows) | conformant | terminal density |
| vars : radius | `0px` | §6 (radius 0) | conformant | cheapest strong signal |
| color-modes : dark | surface `#140c00` / text `#ffb000` … | §3 (dark true mode) | conformant | literal map (serve-unverified on legacy path) |
| color-modes : light | surface `#f4ead6` / text `#a85f00` … | §3 (cream fallback) | conformant | faithful secondary fallback |
| scoped-vars : dark surface/text/border | near-black void + amber ladder | §3/§6 | conformant | overrides base slate; drives legacy-path dark mode |
| scoped-vars : dark brand-red/blue/yellow(+light/mid) | amber | §3 (monochrome guarantee) | conformant | kills base's literal-hex Bauhaus/navy/gold dark leak |
| scoped-vars : dark success/warning/error/info(+tint) | amber ladder + `#ff5a3c` | §3/§9 | conformant | kills base's green/gold/rose/navy dark leak; error stays the one break |
| scoped-vars : standard surface/text/brand | cream + `#a85f00` | §3 (light fallback) | conformant | decouples light canvas from the `#ffb000` white seed |
| css-snippets : phosphor-foundation | radius0/shadow:none/focus box/motion 0ms | §6/§7/§9 | conformant | self-scoped |
| css-snippets : phosphor-cursor | 1000ms step blink + reduced-motion freeze | §7/§9 | conformant | the one living element |
| css-snippets : phosphor-prompt-input | `> ` prefix, amber underline, block cursor | §8 inputs | conformant | placeholder at `--text-muted` (6:1 floor) |
| css-snippets : phosphor-button | bracketed `[ ]`, reverse-video primary | §8 buttons | conformant | self-scoped |
| css-snippets : phosphor-card | no fill, 1px rule, active brightens | §6/§8 cards | conformant | the rule IS the border |
| css-snippets : phosphor-statusbar | reverse-video keybind bar | §8 navigation | conformant | product-specific (TUI status rule) |
| css-snippets : phosphor-stat-tile | box-drawn, bright number/dim label | §8 | conformant | product-specific (screen 14) |
| css-snippets : phosphor-row | hover intensify, selected reverse-video | §7/§8 | conformant | product-specific (screen 04) |

## 2. Claim Coverage (treatise → YAML)

| § | Claim (condensed) | Status | Where encoded / rationale |
|---|-------------------|--------|---------------------------|
| §1 | Identity/perception/audience/tone/keywords | realized | branding.yaml verbatim |
| §3 | Warm monochrome amber; lightness carries hierarchy | realized | white/black seeds → amber ramp |
| §3 | One accent hue, no second brand hue | realized | all three brand slots = `#ffb000` (collapse enforces single hue) |
| §3 | Neutrals are an amber ramp; no true gray/`#000`/`#fff` | realized | white/black re-seed; surfaces via scoped-vars |
| §3 | Semantics = amber intensities; error = one red break; warning amber prefixed `!` | realized | vars + scoped-vars; success `#ffd050`, error `#ff5a3c` |
| §3 | No green anywhere except success, pushed amber-ward | realized | success is amber `#ffd050`, not green (verified in dark CSS) |
| §3 | Dark is the only true mode; cream light is a faithful fallback | realized | color-modes + scoped-vars (light serve-unverified) |
| §4 | Single mono family is the primary UI face; no proportional | realized | font-sans = font-mono = IBM Plex Mono |
| §4 | Terminal-flat ≈1.15 scale, heading ≤1.6× body | waived | typography.yaml not authored (wholesale-replace trap); base scale kept, flat scale deferred |
| §4 | 400 body / 700 headings; line-height 1.4 | realized (partial) | line-height-base 1.4; weights ride base |
| §5 | Character-grid (`ch`/row), dense | realized (partial) | `--terminal-measure: 80ch`, `ch` units in snippets; not a hard grid engine |
| §6 | Radius 0 everywhere | realized | radius seed + snippet enforcement |
| §6 | Box-drawing rules as structure; the rule is the border | realized | card/stat-tile/border tokens |
| §6 | Zero elevation, no shadows ever | realized | shadow-color transparent + box-shadow:none |
| §6 | No gradients/noise/scanline/glow filters | realized | none authored; negatives in prompts |
| §7 | Motion near-absent (0ms); cursor 1000ms step blink | realized | motion tokens 0ms; phosphor-cursor keyframe |
| §8 | Bracketed buttons, prompt inputs, box-drawn cards, reverse-video, status rule | realized | css-snippets (self-scoped) |
| §9 | WCAG AA dark, body AAA target | realized | see §3/§4 matrix; body ≈10:1 |
| §9 | Focus = amber block/box, never removed | realized | `:focus-visible` 1px amber box |
| §9 | Monochrome guarantee — meaning never by color alone | realized | semantic glyphs (✓ ! ✗ i); error also brightest-shifted |
| §9 | Reduced-motion freezes cursor | realized | prefers-reduced-motion guard |
| §9 | No high-contrast mode | waived (by treatise) | §3 explicit: dark clears AA with margin; nothing to boost but intensity |

## 3. Mode-Verification Matrix Results

| # | Check | Light | Dark | HC / reduced-motion | Notes |
|---|-------|-------|------|---------------------|-------|
| 1 | Body text vs surface (≥4.5; AAA if committed) | ~4.6:1 (marginal) | ~10:1 (AAA) | — | dark = true mode, AAA met; light serve-unverified |
| 2 | Secondary/muted text (≥4.5) | ~4.6/~4.6 | ~6:1 (`#c88a00`) | — | muted floored at dim step, never `#8a5e00` (3:1) |
| 3 | Accent as text/UI (≥4.5 / ≥3 large) | ~4.6 (`#a85f00`) | ~10:1 | — | light accent darkened for cream legibility |
| 4 | Semantic text-on-tint; not hue-alone | amber+glyph | amber+glyph; error `#ff5a3c` ~5.5:1 | — | glyph-led (✓ ! ✗ i); error also brightest-shifted |
| 5 | Meaningful borders (≥3:1) | color-mix ~35% | color-mix ~32% (~3:1) | — | box-drawing structure is redundant with layout |
| 6 | Focus indicator (visible, per §9) | 1px amber box | 1px amber box (>7:1) | — | never removed |
| 7 | Mode distinctness | — | cream vs near-black — distinct | — | genuinely different render |
| 8 | Reduced-motion per §9 | — | — | cursor freezes to static block | nothing else moves |
| 9 | Exclusions sweep (banned literals/hues) | pass | **pass** — no `#e20613`/`#0047ab`/`#f5c518`/`#1a8a3f` in phosphor dark | — | grep-verified in compiled CSS |
| 10 | Validator (no ✗, ⚠ explained) | pass | pass | — | legacy path: exit 0, no error/exception |

## 4. Contrast Measurements (near-the-line pairs)

| Pair | Mode | Required | Measured | Result |
|------|------|----------|----------|--------|
| amber `#ffb000` on `#140c00` | dark | 4.5 (AAA 7) | ~10:1 | PASS (AAA) |
| dim `#c88a00` on `#140c00` | dark | 4.5 | ~6:1 | PASS |
| error `#ff5a3c` on `#140c00` | dark | 4.5 | ~5.5:1 | PASS |
| muted `#8a5e00` on `#140c00` (borders only) | dark | 3.0 (non-text) | ~2.9:1 | PASS as decorative rule; never used for text |
| amber `#a85f00` on cream `#f4ead6` | light | 4.5 | ~4.6:1 | MARGINAL PASS (serve-unverified) |

## 5. Deviations & Waivers

| Item | Treatise clause | Deviation | Rationale | Approved by |
|------|-----------------|-----------|-----------|-------------|
| typography.yaml not authored | §4 flat ≈1.15 scale | base type scale kept | wholesale-replace trap; base scale acceptable, flat-scale polish deferred | Stage C agent |
| Light-mode accents | §3 amber | darkened to `#a85f00` in light | `#ffb000` on cream ≈1.6:1; light is faithful secondary fallback, not an independent design | Stage C agent |
| No high-contrast mode | §9 | none authored | treatise §3 explicitly waives it (monochrome already maximizes intensity) | treatise |
| ⚠ target-section not in page-sections (8 snippets) | — | benign | self-scoped css-snippets still compile/emit; the styleguide preview page just has no matching section slot — shipped `workbench` theme emits the same ⚠ | Stage C agent |

## 6. Standing Cautions

| Caution | Trigger to recheck |
|---------|--------------------|
| A base component that reads `var(--slate-*)`/`var(--gray-*)` **directly** (not via `--surface`/`--text`/`--border`) would render off-hue (bluish) in dark; the main surface/text/border tokens are overridden but stray direct refs are not | Any base-theme update, or a component that looks non-amber in dark |
| brand-blue/brand-yellow are collapsed to amber; a future base element routed through them expecting a distinct 2nd hue will render amber (intended) | Base cascade adds a new brand-blue/-yellow-driven chrome element |
| Light-mode literal color-modes maps unverified on the legacy path | When `npx @noizu/styleguide serve` becomes available |
| muted amber `#8a5e00` is ~2.9:1 — decorative/borders only | Any use of `#8a5e00` for text |

## 7. Escalations to trl-user-experience-engineer / base owner

| # | Issue | § | Status |
|---|-------|---|--------|
| 1 | Base `theme-style-guide/style-guide.scoped-vars.yaml` brightens dark brand-red/blue/yellow **and** semantic states from LITERAL hexes (`#e20613`/`#0047ab`/`#f5c518`/`#1a8a3f`/…) instead of `var(--brand-*)`/`var(--<semantic>)`, forcing every non-Bauhaus dark theme to re-declare the whole family. Phosphor works around it with a full scoped-vars dark block. Recommend base brightens from the variables. (Same defect npl-minimal escalated.) | §3 | open (worked around) |
| 2 | Legacy `generate-css` fallback does not emit `color-modes.yaml`'s literal light/dark maps — dark/light *map* verification is blocked until `npx @noizu/styleguide serve` (public npm 404s on `@noizu/styleguide`). | §3 | open (infra) |

## 8. Session History

| Date | Workflow | Summary | Verdict after |
|------|----------|---------|---------------|
| 2026-07-17 | new-theme (extract-seeds + tune-facets) | Built theme-phosphor/ from treatise rev 2 (6 facets): monochrome-amber dark (true mode) + cream light fallback; full scoped-vars dark block neutralizes the base Bauhaus/navy/gold/green leak (grep-verified in compiled CSS); 5 slice screens rendered at `--quality medium` (high tier 429'd in the render storm); treatise promoted sketch → full. | CONFORMANT |
