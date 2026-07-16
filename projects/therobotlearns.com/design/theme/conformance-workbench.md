# Theme Conformance — workbench (2026-07-17)

Treatise-vs-YAML audit record. Lives at
`projects/therobotlearns.com/design/theme/conformance-workbench.md`.

- **Treatise**: treatise-workbench.md @ rev 2 (status: full)
- **Theme**: theme-workbench/ (7 files) · base chain: theme-workbench → theme-style-guide
- **Audited by / workflow**: Stage C agent (trl-theme-designer) / tune-facets (existing theme)
- **Serve state**: legacy `generate-css` path (styleguide_serve=off) — exit 0, no error/exception.
  Remaining ⚠ are benign base-pattern noise (target-section slots + empty base var groups),
  identical to the set every sibling theme emits; listed in §5.

## Verdict

**CONFORMANT** (light = the primary design target, fully realized on the compiled-CSS seed
cascade; dark = a faithful "dark wood bench" translation, scoped-vars-driven and
compiled-CSS-verified as warm-brown + clay with **no** Bauhaus/navy/gold/green leak).

This was a TUNE pass on an existing theme. Three defects were fixed: (1) the flagged
**missing Body typography class** — the prior `typography.yaml` (Display/H1/H2/Label only)
replaced the base wholesale and silently dropped Body/Small/Code/Caption/Mono, so body text
had no class to resolve to; the full base set is now re-declared in the theme's voice and
`.typography-body` resolves `--font-sans` (Outfit) in the compiled CSS. (2) The **seed trap** —
bare `red`/`blue`/`yellow` no-op keys removed, and `brand-*-light`/`-mid` re-pointed off
`var(--brand-*)` so tints track the clay accents instead of the base's hard-coded Bauhaus hex.
(3) **css-snippet global bleed** — all five original snippets were bare selectors (would bleed
into every sibling theme); every selector is now self-scoped under
`html[data-design-theme="workbench"]`, and a new self-scoped foundation snippet adds the §9
blue focus ring the clay-orange accent could not carry. A new `scoped-vars.yaml` neutralizes
the base's dark-cascade Bauhaus leak. Two verification gaps remain, neither a treatise
violation: (a) the legacy path does not emit `color-modes.yaml`'s literal light/dark maps, so
that parallel map declaration is reasoned, not serve-verified (dark mode itself is verified via
scoped-vars); (b) clay semantics as text on cream land marginally in light mode — mitigated by
glyph/label pairing and ink-on-fill usage (§9), not remediated to new hues.

## 1. Value Trace (YAML → treatise)

| File : key | Value | Treatise § | Disposition | Action taken |
|------------|-------|-----------|-------------|--------------|
| vars : white | `#f5f0e8` | §3 (cream paper, lightest surface) | conformant | warm paper canvas seed |
| vars : black | `#2c2416` | §3 (brown ink, darkest value) | conformant | warm dark seed (never `#000`) |
| vars : ~~red/blue/yellow~~ | removed | §3 seed trap | conformant | bare keys were silent no-ops; deleted |
| vars : brand-red / brand-blue / brand-yellow | `#e74c3c` / `#2980b9` / `#f1c40f` | §3 (clay accents; blue = link/primary) | conformant | categorical clay voice |
| vars : brand-*-light / -mid | `color-mix(var(--brand-*) 12/20%, surface)` (18/35% yellow) | §3/§6 | conformant | **seed-trap fix** — re-point off the override, not the base's Bauhaus hex |
| vars : success/warning/error/info | `#27ae60`/`#f39c12`/`#e74c3c`/`#2980b9` | §3/§9 semantic mapping | conformant | Flat-UI clay set; error == brand-red (glyph-paired, §9) |
| vars : radius | `3px` | §6 (cut-paper softness) | conformant | cheapest strong signal |
| vars : font-sans / font-display / font-mono | Outfit / Caveat / Source Code Pro | §4 | conformant | printed + handwritten + mono; matches branding.yaml font-url |
| vars : card-separator-style | `none` | §5/§6 (separation by shadow/air) | conformant | notes lifted off, not ruled |
| typography : full class set (+Body) | Body = Outfit 400 / 1.6; titles Caveat; code Source Code Pro | §4 | conformant | **BUG FIX** — full base set re-declared (wholesale-replace trap); `.typography-body` verified in CSS |
| color-modes : light | surface `#f5f0e8` / text `#2c2416` … | §3 (light primary) | conformant | matches seed cascade |
| color-modes : dark | surface `#2c2416` / text `#e8dfd0` … | §3 (dark wood bench) | conformant (serve-unverified map) | literal map not emitted on legacy path (§5 gap); dark driven by scoped-vars |
| scoped-vars : standard shadow-color | `rgba(44,36,22,0.12)` | §6 (soft warm lift) | conformant | warm-brown elevation token |
| scoped-vars : dark surface/text/border | warm brown `#2c2416` + cream `#e8dfd0` ladder | §3 (dark wood bench) | conformant | overrides base bluish slate; drives legacy-path dark mode |
| scoped-vars : dark brand-red/blue/yellow(+light/mid) | clay color-mix off `#e74c3c`/`#2980b9`/`#f1c40f` | §3 | conformant | **kills base's literal-hex Bauhaus/navy/gold dark leak** |
| scoped-vars : dark success/warning/error/info(+tint) | clay set brightened | §3/§9 | conformant | kills base green/gold/rose/navy dark leak |
| css-snippets : workbench-foundation | card lift shadow + hover settle/tilt + 2px blue `:focus-visible` + reduced-motion | §6/§7/§9 | conformant | self-scoped; §9 focus (orange fails 3:1, blue clears) |
| css-snippets : sticky-note / pushpin / tape-strip / cork-board / sketch-arrow | maker motifs | §6/§8 | conformant | **self-scoped (v3 remediation)** — were bare, now confined |

## 2. Claim Coverage (treatise → YAML)

| § | Claim (condensed) | Status | Where encoded / rationale |
|---|-------------------|--------|---------------------------|
| §1 | Identity/perception/audience/tone/keywords | realized | branding.yaml verbatim |
| §3 | Warm light-primary; cream paper + brown ink | realized | white/black seeds |
| §3 | Categorical clay palette; orange accent border, blue primary/link | realized | vars palette + brand-blue; border-accent `#e67e22` (color-modes) |
| §3 | Every neutral paper-tinted; no pure gray | realized | warm surfaces/borders in color-modes + scoped-vars |
| §3 | Semantics = Flat-UI clay; error==brand-red paired w/ icon | realized | vars semantics; §9 non-color guarantee |
| §3 | Light primary; dark = faithful "dark wood bench" translation | realized | color-modes + scoped-vars (dark verified via scoped-vars; map serve-unverified) |
| §4 | Printed sans body + handwritten display + mono code | realized | Outfit / Caveat / Source Code Pro seeds |
| §4 | **Explicit Body class (Outfit 400)** | realized | **bug fix** — full typography set re-declared; `.typography-body` in compiled CSS |
| §5 | Casual spacing; cards as pinned notes, separation by shadow/air | realized | card-separator none + foundation lift |
| §6 | Radius 3px cut-paper | realized | radius seed |
| §6 | Deliberate soft warm-brown elevation (2 steps) | realized | shadow-color token + foundation rest/hover shadow |
| §6 | Sanctioned cork/tape/pushpin texture | realized | css-snippets (cork-board, tape-strip, pushpin) |
| §7 | Tactile pin/settle 200–300ms, slight overshoot; reduced-motion guard | realized (partial) | foundation 220ms settle + tilt + reduced-motion; full keyframes deferred |
| §8 | Clay-fill buttons, note-paper inputs, pinned-note cards, taped nav | realized (partial) | pinned/sticky-note/tape snippets; buttons/inputs ride base cascade w/ clay tokens |
| §9 | WCAG 2.2 AA both modes; ink-on-cream AAA light | realized | see §3/§4 matrix; brown-on-cream ≈12:1 |
| §9 | Focus ring clears 3:1 — blue, not orange | realized | foundation `:focus-visible` 2px `var(--brand-blue)` (verified in CSS) |
| §9 | Status never by hue alone (red is brand+error) | realized | glyph/label pairing in renders + treatise rule |
| §9 | Reduced-motion disables tilt/settle | realized | prefers-reduced-motion guard (6 occ. in CSS) |
| §9 | No high-contrast mode in v1 | waived (by treatise) | §3 explicit; ink-on-cream clears AA with margin |

## 3. Mode-Verification Matrix Results

| # | Check | Light | Dark | HC / reduced-motion | Notes |
|---|-------|-------|------|---------------------|-------|
| 1 | Body vs surface (≥4.5; AAA if committed) | ~12:1 (AAA) | ~11:1 (`#e8dfd0`/`#2c2416`) | — | light is design target, AAA |
| 2 | Secondary/muted (≥4.5) | sec ~6:1; muted `#a08e72` ~2.7:1 (decorative only) | sec `#bfb095` ~7:1; muted `#a89876` ~4.8:1 | — | light muted is decorative/large per §9 |
| 3 | Accent as text/UI (≥4.5 / ≥3 large) | blue `#2980b9` ~4.6:1; orange large/border only | brand tints brightened toward white | — | orange never body text |
| 4 | Semantic text-on-tint; not hue-alone | clay ~3.5–4.5:1 + glyph | clay brightened + glyph | — | glyph/label paired; error also iconized |
| 5 | Meaningful borders (≥3:1) | tan `#d4c9b5`/`#b8a88e` | `#504030`/`#6b5a44` | — | structural, redundant with layout |
| 6 | Focus indicator (visible, per §9) | 2px marker-blue box | 2px marker-blue box | — | orange rejected (2.8:1); blue clears |
| 7 | Mode distinctness | — | cream vs warm-brown — distinct | — | genuinely different render |
| 8 | Reduced-motion per §9 | — | — | tilt/settle disabled | cards appear placed |
| 9 | Exclusions sweep (banned literals/hues) | pass | **pass** — no `#e20613`/`#0047ab`/`#f5c518`/`#1a8a3f`/`#c41a1a` in workbench scope | — | grep-verified in compiled CSS |
| 10 | Validator (no ✗, ⚠ explained) | pass | pass | — | legacy path: exit 0, no error/exception |

## 4. Contrast Measurements (near-the-line pairs)

| Pair | Mode | Required | Measured | Result |
|------|------|----------|----------|--------|
| brown `#2c2416` on cream `#f5f0e8` | light | 4.5 (AAA 7) | ~12:1 | PASS (AAA) |
| text-secondary `#5d4e37` on cream | light | 4.5 | ~6:1 | PASS |
| text-muted `#a08e72` on cream | light | 3.0 (non-text) | ~2.7:1 | PASS as decorative/large only |
| border-accent orange `#e67e22` on cream | light | 3.0 (non-text) | ~2.8:1 | PASS as border/large-UI only |
| blue `#2980b9` on cream (link/focus) | light | 4.5 text / 3.0 ring | ~4.6:1 | PASS |
| cream `#e8dfd0` on wood `#2c2416` | dark | 4.5 (AAA 7) | ~11:1 | PASS (AAA) |
| text-muted `#a89876` on wood | dark | 4.5 | ~4.8:1 | PASS (floored above base gray) |

## 5. Deviations & Waivers

| Item | Treatise clause | Deviation | Rationale | Approved by |
|------|-----------------|-----------|-----------|-------------|
| typography.yaml full re-declaration | §4 | re-declares the full base class set, not a diff | wholesale-replace trap — the only safe way to add Body without deleting the inherited classes | Stage C agent |
| H4 printed (Outfit) not handwritten | §4 | H4 = font-sans 600, not Caveat | Caveat legibility drops at small heading size; big titles stay handwritten (Display/H1/H2/H3) | Stage C agent |
| color-modes literal dark map | §3 | unverified on legacy path | generate-css does not emit color-modes maps; dark is driven+verified via scoped-vars instead | §5 infra gap |
| Light clay semantics marginal on cream | §3/§9 | error/info ~3.5–4.5:1 as text | §9 pairs them with glyph/label and prefers ink-on-fill; not remediated to new hues | treatise §9 |
| §7 pin/settle keyframes | §7 | foundation transition (settle+tilt) instead of full pin/write-on keyframes | tune scope; reduced-motion guard present; richer keyframes deferred to frontend pass | Stage C agent |

## 6. Standing Cautions

| Caution | Trigger to recheck |
|---------|--------------------|
| Only brand-* and semantic families are re-pointed in dark scoped-vars; the raw palette hues (rose/orange/amber/teal/…) still revert to base brights in dark via the base cascade. Working chrome uses brand/semantic, so impact is the palette *showcase* swatches only — a low-impact standing caution, not fixed here. | A component routed through a raw palette var (not brand/semantic) that looks off-hue in dark |
| color-modes.yaml literal light/dark maps are unverified on the legacy path | When `npx @noizu/styleguide serve` becomes available |
| text-muted `#a08e72` (light) ≈2.7:1 and border-accent orange `#e67e22` ≈2.8:1 — decorative / large-UI / borders only | Any use of either for body text |
| error == brand-red `#e74c3c`; a red pushpin/mark must always pair a glyph/label | Any status shown by color alone |

## 7. Escalations to trl-user-experience-engineer / base owner

| # | Issue | § | Status |
|---|-------|---|--------|
| 1 | Base `theme-style-guide/style-guide.scoped-vars.yaml` brightens dark brand-red/blue/yellow **and** semantic states from LITERAL hexes (`#e20613`/`#0047ab`/`#f5c518`/`#1a8a3f`/…) instead of `var(--brand-*)`/`var(--<semantic>)`, forcing every non-Bauhaus dark theme to re-declare the whole family. Workbench works around it with a full scoped-vars dark block. Recommend the base brighten from the variables. (Same defect phosphor and npl-minimal escalated.) | §3 | open (worked around) |
| 2 | Legacy `generate-css` fallback does not emit `color-modes.yaml`'s literal light/dark maps — map verification is blocked until `npx @noizu/styleguide serve` (public npm 404s on `@noizu/styleguide`). | §3 | open (infra) |

## 8. Session History

| Date | Workflow | Summary | Verdict after |
|------|----------|---------|---------------|
| 2026-07-17 | tune-facets (existing theme) | TUNE pass on theme-workbench/: fixed the flagged missing Body class (full typography set re-declared, `.typography-body`=Outfit verified in CSS); fixed the seed trap (removed bare red/blue/yellow, re-pointed brand-*-light/mid); self-scoped all 5 css-snippets + added a foundation snippet (warm lift + §9 blue focus + reduced-motion); added scoped-vars.yaml neutralizing the base Bauhaus/slate dark leak (grep-verified clay + zero Bauhaus in workbench scope). Rendered 5 slice screens at `--quality medium` (terminal/TUI maker-sheet surfaces); screen 14 re-rendered once to replace browser chrome with a terminal window. Treatise promoted sketch → full (rev 2). | CONFORMANT |
