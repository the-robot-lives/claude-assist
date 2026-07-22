# Theme Conformance — chalkboard (2026-07-17)

Treatise-vs-YAML audit record. Lives at
`projects/therobotlearns.com/design/theme/conformance-chalkboard.md`.

- **Treatise**: treatise-chalkboard.md @ rev2 (2026-07-17)
- **Theme**: theme-chalkboard/ (8 files: meta, vars, scoped-vars [new], color-modes, branding, typography, css-snippets, globals) · base chain: theme-chalkboard → theme-style-guide
- **Audited by / workflow**: Stage C agent (uplift pipeline) / tune-facets + audit-theme-vs-treatise
- **Serve state**: legacy `generate-css` path (styleguide_serve=off); exit 0, no error/exception. ⚠/✗ severity distinction unavailable on this path — only the 3 pre-existing **base-theme** warnings (empty base vars groups; base card-glow/demo snippets) surfaced; none from chalkboard.

## Verdict

**CONFORMANT (with 3 documented waivers)**

The shipped chalkboard YAML was reverse-engineered from Stage A and carried three latent
defects, all now fixed and verified against the compiled CSS: (1) a dead Roboto Slab font
import, (2) the pre-existing seed-trap (bare `red`/`blue`/`yellow` no-ops + `brand-*-light/-mid`
pinned to Bauhaus color-mix) plus the dark-mode brand-tint leak (base `.dark` re-brightens
brand-red/blue/yellow from literal Bauhaus/navy/gold), and (3) css-snippets/globals with bare
selectors bleeding into every sibling theme. The treatise's design theory (dark board, chalk
palette, hand type, radius 0, dashed rules) is realized and validated; the two prior "honest
flags" (always-dark, dead font) are now deliberate, documented decisions. Three waivers stand:
intentional always-dark (no true light mode), colored-chalk near-the-line contrast handled by
§9's label-size + non-color reinforcement, and the base-cascade dark-tint defect (escalated, not
fixable from a Stage C run).

## 1. Value Trace (YAML → treatise)

| File : key | Value | Treatise § | Disposition | Action taken |
|------------|-------|-----------|-------------|--------------|
| vars : white | `#e8e4d8` | §3 neutrals (chalk ink) | conformant | — |
| vars : black | `#1e2a1e` | §3 neutrals (board) | conformant | — |
| vars : brand-red | `#e06060` | §3 rose chalk (primary+error) | conformant | — |
| vars : brand-blue | `#6cb4dc` | §3 blue chalk (info/links) | conformant | — |
| vars : brand-yellow | `#e8d44c` | §3 yellow chalk (emphasis) | conformant | — |
| vars : brand-{red,blue,yellow}-{light,mid} | `color-mix(var(--brand-*) …)` | §3 | was **violation** (seed-trap: base pinned to Bauhaus hex) | re-pointed to read `var(--brand-*)` |
| vars : (bare `red`/`blue`/`yellow`) | *removed* | §3 | was **orphan** (silent no-op keys) | deleted; accents live on `brand-*` |
| vars : success/warning/error/info | `#50b878`/`#d8b840`/`#e06060`/`#6cb4dc` | §3 semantics | conformant | — |
| vars : font-sans | `'Patrick Hand',…` | §4 | conformant (matches font-url) | — |
| vars : font-display / font-mono | Architects Daughter / Roboto Mono | §4 | conformant | — |
| vars : font-size-base / line-height | `18px` / `1.65` | §4 scale | conformant | — |
| vars : radius | `0px` | §6 flat board | conformant (compiled `--radius: 0px`) | — |
| vars : card-separator-style/color | `dashed` / `rgba(232,228,216,0.3)` | §5/§6 dashed rules | conformant | — |
| scoped-vars : brand-{red,blue,yellow}(+light/mid) .dark | chalk hexes / `var(--brand-*)` mixes | §3 (dark) | was **violation** (base dark leak → Bauhaus) | new file re-points all 3 families in `.dark` |
| branding : font-url | 3-face URL (no Slab) | §1/§4/§10 | was **violation** (dead Slab import) | dropped Roboto Slab; HTTP 200 verified |
| color-modes : light/dark | both dark board maps | §3 modes | conformant (deliberate always-dark) | documented decision in-file |
| css-snippets : all selectors | `html[data-design-theme="chalkboard"] …` | §6/§7/§8 | was **violation** (bare → global bleed) | self-scoped every selector |
| globals : body / ::selection | scoped to chalkboard | §8 | was **violation** (bare → bleed) | self-scoped theme-token rules |

## 2. Claim Coverage (treatise → YAML)

| § | Claim (condensed) | Status | Where encoded / rationale |
|---|-------------------|--------|---------------------------|
| §1 | Identity, keywords, tone verbatim | realized | branding.yaml, meta.yaml |
| §3 | Dark forest-green board; chalk-white ink | realized | white/black seeds + color-modes |
| §3 | 3 chalk primaries + 13-hue palette + light variants | realized | vars.yaml Primaries + Palette |
| §3 | Semantics on chalk set (success/warning/error/info) | realized | vars.yaml Semantic |
| §3 | Red chalk = brand AND error → reinforce w/ underline/icon | realized (design rule) | §9 non-color emphasis; rose used as marks not text |
| §3 | Both modes dark (no true light mode) | realized (deliberate) | color-modes.yaml + waiver W1 |
| §4 | Patrick Hand body / Architects Daughter display / Roboto Mono | realized | vars + typography + branding font-url |
| §4 | Drop dead Roboto Slab | realized | branding.yaml (removed) |
| §4 | 18px/1.65 generous rhythm, single-weight 400 | realized | vars.yaml |
| §5 | Roomy density, dashed chalk separators | realized | card-separator vars |
| §6 | radius 0, flat, dashed borders, sanctioned texture | realized | radius seed + css-snippets (chalk-dust/eraser) |
| §7 | Didactic write-on motion, reduced-motion guard | partial/base | base motion inherited; bespoke keyframes not added this pass (noted C1) |
| §8 | Chalk-outline buttons, underline inputs, dashed cards, underlined active nav | realized (components) | css-snippets (chalk-box/underline/arrow), self-scoped |
| §9 | AA on dark board; colored chalks label-size; focus ring; non-color emphasis | realized + waiver W2 | contrast §4 below; near-the-line chalks documented |

## 3. Mode-Verification Matrix Results

Modes here = daytime board (`light` #2d4a2d) and evening board (`dark` #1e2a1e); both dark by design.

| # | Check | Daytime (light) | Evening (dark) | HC / reduced-motion | Notes |
|---|-------|-------|------|---------------------|-------|
| 1 | Body text vs surface (≥4.5; AAA 7) | PASS 7.76:1 | PASS 9.73:1 | n/a (no HC mode) | chalk-white ink |
| 2 | Secondary / muted text | secondary PASS 5.43:1; **muted 2.78:1 (decorative-only)** | secondary PASS 5.73:1; muted 3.05:1 | — | muted never body (treatise §9) |
| 3 | Accent as text/UI (≥4.5 / ≥3 large) | yellow 6.55 PASS; blue 4.32, green 3.98 (large/label); **rose 2.82 (marks only)** | yellow 9.93, blue 6.55, green 6.03, rose 4.28 — all ≥3 | — | colored chalks = label-size marks, §9 |
| 4 | Semantic text-on-tint; not hue-alone | PASS (reinforced) | PASS | not color-alone: underline/icon | error(rose) always + underline/icon |
| 5 | Meaningful borders (≥3:1) | border-strong ~2.2 (decorative dashed); chalk-box uses `--text` (7.76) | higher | — | structural boxes use chalk-white, not tint |
| 6 | Focus ring visible (§9 bright-chalk ring) | PASS (focus-ring token present) | PASS | — | color-modes focus-ring rgba set both modes |
| 7 | Mode distinctness | — | PASS (surfaces 1.52:1 apart) | — | daytime vs evening board genuinely distinct |
| 8 | Reduced-motion per §9 | — | — | inherits base guard (C1) | no bespoke keyframes added this pass |
| 9 | Exclusions sweep (no Bauhaus/neon) | PASS | PASS | — | 0 `#e20613/#0047ab/#f5c518` in chalkboard `.dark` |
| 10 | Validator (no ✗/⚠) | exit 0, no error/exception | same | — | legacy path lacks ✗/⚠ severity (see head note) |

## 4. Contrast Measurements (near-the-line pairs)

WCAG 2.1 relative luminance; foreground on board surface.

| Pair | Mode | Required | Measured | Result |
|------|------|----------|----------|--------|
| chalk-white #e8e4d8 / board #2d4a2d | daytime | 4.5 (AAA 7) | 7.76:1 | PASS (≈ treatise's 8:1) |
| text-secondary #c8c0a8 / #2d4a2d | daytime | 4.5 | 5.43:1 | PASS |
| text-muted #90886c / #2d4a2d | daytime | (decorative) | 2.78:1 | WAIVED — decorative/large only |
| blue chalk #6cb4dc / #2d4a2d | daytime | 3 large | 4.32:1 | PASS large/label |
| yellow chalk #e8d44c / #2d4a2d | daytime | 4.5 | 6.55:1 | PASS |
| green chalk #50b878 / #2d4a2d | daytime | 3 large | 3.98:1 | PASS large/label |
| rose chalk #e06060 / #2d4a2d | daytime | 3 (mark) | 2.82:1 | WAIVED — mark+icon, not text (W2) |
| chalk-white #d8d0bc / board #1e2a1e | evening | 4.5 | 9.73:1 | PASS |
| rose chalk #e06060 / #1e2a1e | evening | 3 | 4.28:1 | PASS |
| ::selection black #1e2a1e on yellow #e8d44c | both | 4.5 | 9.93:1 | PASS |

## 5. Deviations & Waivers

| # | Item | Treatise clause | Deviation | Rationale | Approved by |
|---|------|-----------------|-----------|-----------|-------------|
| W1 | Always-dark (no true light mode) | §3 modes | `light` map is a dark board, not a pale surface | Chalk-on-dark-board is the identity (§1/§2); a light/paper mode belongs to sibling `workbench` and would collapse the distinction | treatise rev2 (self) |
| W2 | Colored chalks below AA-as-text on daytime board (rose 2.82, green 3.98, blue 4.32) | §9 | used as label-size marks + non-color reinforcement, not body text | §9 commits colored chalk to label-size emphasis reinforced by underline/icon; meaning never rests on chalk color alone; hues are deliberately dusty (§2 anti-neon) so brightening would break identity | treatise §9 (self) |
| W3 | text-muted 2.78:1 (daytime) | §9 | below AA | treatise explicitly scopes muted to "decorative/large only, never body" | treatise §9 |

## 6. Standing Cautions

Re-check after ANY seed or color-mode change.

| Caution | Trigger to recheck |
|---------|--------------------|
| C1 — §7 didactic write-on/draw motion not yet authored as bespoke keyframes (inherits base motion + reduced-motion guard) | when motion polish is scheduled; add to css-snippets self-scoped |
| C2 — rose (`brand-red` == error) must stay a mark/underline/border + icon, never a text fill (2.82:1 daytime) | any component that would render error as rose *text* |
| C3 — dark-mode brand re-point lives in scoped-vars as literal chalk hexes; if `brand-*` seeds change, the `.dark` literals must be updated in lockstep | any change to brand-red/blue/yellow hex |
| C4 — color-modes literal light/dark maps are UNVERIFIED on the legacy generate-css path (only white/black seed cascade resolves); dark-map correctness assumes authored values | when `npx @noizu/styleguide serve` becomes available |

## 7. Escalations to trl-user-experience-engineer

| # | Issue | § | Status |
|---|-------|---|--------|
| E1 | Base `theme-style-guide/style-guide.scoped-vars.yaml` brightens brand-red/blue/yellow (+light/mid) for dark mode from **literal Bauhaus/navy/gold hex**, not `var(--brand-*)` — every child theme with a non-Bauhaus accent silently reverts in dark mode. Worked around here via a per-theme scoped-vars delta. | §3 | open (base-cascade defect; do not fix from Stage C) |
| E2 | Legacy `generate-css` fallback does not emit `color-modes` literal light/dark maps — dark-mode color-modes conformance is unverifiable until the npx serve path is restored. | §3 | open (tooling) |

## 8. Session History

| Date | Workflow | Summary | Verdict after |
|------|----------|---------|---------------|
| 2026-06-14 | extract-seeds (Stage A) | Reverse-engineered theme-chalkboard/ from shipped YAML; treatise rev1 sketch | (sketch) |
| 2026-07-17 | tune-facets + audit (Stage C) | Fixed dead Roboto Slab import; fixed seed-trap + dark brand-tint leak (new scoped-vars, all 3 families); self-scoped css-snippets + globals; affirmed always-dark; rendered + reviewed 5 slice screens (01,05,09,11,12; 09 re-rendered once); treatise rev2 full | CONFORMANT (3 waivers) |
