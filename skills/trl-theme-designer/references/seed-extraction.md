# Seed Extraction

> The mechanics of `style-guide.vars.yaml`: the ~12 seeds, how the engine's 4-pass cascade expands them into 300+ CSS custom properties, and where in the resolution order an override should land. Tune seeds before facets — a one-line seed change outperforms fifty component overrides.

---

## 1. The vars.yaml Schema

Seeds live in named groups under `vars.groups`. This is a **hard requirement**: an
empty or missing `vars.groups` is a `✗` error and the page renders unstyled.

```yaml
# style-guide.vars.yaml
vars:
  groups:
    - name: Surfaces
      vars:
        white: "#f5efe8"          # top of the derived gray ramp
        black: "#141110"          # bottom of the derived gray ramp
        # off-white, gray-50 … gray-900 are auto-derived — do not hand-set

    - name: Brand
      vars:
        brand-red: "#e8763a"      # primary accent (slot name is fixed; hue is yours)
        # brand-red-light / brand-red-mid are auto-derived

    - name: Semantic
      vars:
        success: "#8aa84f"
        warning: "#d9a83c"
        error: "#cc4433"
        info: "#6a8caf"
        # {semantic}-tint backgrounds are auto-derived

    - name: Typography
      vars:
        font-sans: "'Inter', -apple-system, sans-serif"
        font-mono: "'JetBrains Mono', 'Menlo', monospace"
        # font-size scale + line-heights are auto-derived

    - name: Layout
      vars:
        radius: "4px"
        # unit: "8px"             # override only when the treatise demands non-default rhythm
```

Group names are documentation (they label the token browser); the **var keys** are the
contract with the cascade. Values become `var(--white)`, `var(--brand-red)`, etc.

## 2. The 12 Canonical Seeds

| # | Seed | Drives | Notes |
|---|------|--------|-------|
| 1 | `white` | gray-50…gray ramp top, light surfaces | Not necessarily `#ffffff` — tinted paper is a seed decision |
| 2 | `black` | gray ramp bottom, dark surfaces, default text | Tinted charcoals here tint the whole derived ramp |
| 3 | `brand-red` | primary accent + `-light`/`-mid` tints | The slot NAME is fixed by the engine; put your primary accent here whatever its hue |
| 4 | `brand-blue` | secondary accent + tints | Leave unset if the treatise says single-accent |
| 5 | `brand-yellow` | tertiary accent + tints | Same |
| 6 | `success` | success + `success-tint` | Harmonize temperature with the palette |
| 7 | `warning` | warning + `warning-tint` | Must stay distinguishable from a warm brand accent |
| 8 | `error` | error + `error-tint` | Must stay distinguishable from `brand-red` when brand is red/orange |
| 9 | `info` | info + `info-tint` | Often the one permitted "off-temperature" hue |
| 10 | `font-sans` | entire UI type system | Must match families loaded via `branding.yaml` `font-url` |
| 11 | `font-mono` | code/data type | Same |
| 12 | `radius` | full border-radius scale | The cheapest strong personality signal |

Layout extras (`unit`, spacing steps) are available but default well — override only on
an explicit §5 claim.

## 3. The 4-Pass Cascade

The engine (`resolveDefaults()` in `@noizu/styleguide/css-gen`) expands seeds in four
passes. Full engine reference: `styleguide-engine/app/docs/reference/cascade.md`.

```
Pass 1  SEEDS            your vars.groups values (~12)
   ↓
Pass 2  PRIMITIVES       white/black → gray-50…gray-900 ramp
                         brand-* → -light/-mid tints
                         base sizes → font-size-xs…display, space-1…space-24, radius scale
   ↓
Pass 3  SEMANTICS        surface / surface-alt / text / text-secondary / text-muted /
                         border / border-strong … mapped from primitives per color mode
   ↓
Pass 4  COMPONENTS       btn-*, card-*, input-*, nav-* defaults from semantics
```

**Resolution order when a token is referenced** (most specific wins):

```
1. component override (your YAML)      e.g. card-radius in a vars group
2. semantic override (your YAML)       e.g. color-modes.dark.surface
3. primitive override (your YAML)      e.g. hand-set gray-100 (rare — usually wrong)
4. engine-computed semantic
5. engine-computed primitive (from your seeds)
6. engine hard default
```

Most themes should live at levels 5 (seeds) and 2 (color-mode semantics), with a few
level-1 component vars for §8 inflections.

## 4. Cascade Behavior You Must Anticipate

| Behavior | Consequence for tuning |
|---|---|
| Gray ramp is interpolated between `white` and `black` | Tinted seeds tint EVERY derived gray — which is exactly why treatises re-seed them. Check text-muted contrast after any change to either seed |
| `-light`/`-mid` brand tints derive from the brand hex | You cannot pick tint hexes independently at seed level; if the derived tint is wrong, override the specific token (level 3) and note it in the conformance report |
| `{semantic}-tint` backgrounds derive from each semantic seed | Darkening a semantic seed darkens its tint too — verify badge/alert text on the new tint |
| `radius` scales the whole radius system | Per-component radius exceptions (chips at 2px when base is 4px) are component vars or snippets, not a second seed |
| Fonts don't self-load | `font-sans`/`font-mono` must match `branding.yaml` `font-url` families and weights or you render fallbacks |
| Seeds feed BOTH modes | `color-modes.yaml` remaps semantics per mode, but primitives are shared — a dark-first accent often needs a per-mode override for light |

## 5. Where NOT to Override

- **Never hand-set the gray ramp** unless the treatise pins specific steps — you forfeit the tint coherence the seeds buy you.
- **Never restate a base-theme default** ("override" equal to what the base already computes). It's drift bait: the value silently diverges when the base updates.
- **Never encode mode differences as seeds.** That's `color-modes.yaml` / `scoped-vars.yaml` territory.

## 6. Worked Example: Ember Seed Extraction

From `treatise-ember.md` (§3, §4, §6), the complete seed set with reasoning:

```yaml
# theme-ember/style-guide.vars.yaml
vars:
  groups:
    - name: Surfaces
      vars:
        white: "#f5efe8"    # §3 neutral strategy: warm off-white; ramp inherits tint
        black: "#141110"    # §3: warm near-black; canvas #1a1512 emerges in the derived ramp

    - name: Brand
      vars:
        brand-red: "#e8763a"  # §3 accent, pinned ±5° hue / ±8% sat
        # brand-blue, brand-yellow deliberately unset — §3 "no secondary brand hue"

    - name: Semantic
      vars:
        success: "#8aa84f"  # §3: olive-warm green, not cold mint
        warning: "#d9a83c"  # §3: yellower + lighter than ember, so it never reads as accent
        error: "#cc4433"    # §3: clearly redder (~5°) and more saturated than ember
        info: "#6a8caf"     # §3: the one permitted cool; desaturated slate

    - name: Typography
      vars:
        font-sans: "'Inter', -apple-system, sans-serif"          # §4
        font-mono: "'JetBrains Mono', 'Menlo', monospace"        # §4

    - name: Layout
      vars:
        radius: "4px"       # §6: soft-technical base; 2px chips are a component exception
```

Deliberate non-actions (as important as the values):

- No gray steps set — §3 delegates the ramp to the cascade.
- No `unit` override — §5 inherits the 8px base.
- Chip radius (2px) and elevation-by-tone deferred to component vars / snippets (see `facet-tuning-guide.md`).

After writing seeds, run `npx @noizu/styleguide serve projects/{domain}/design/theme/`
and confirm: no `✗ vars:` errors, the derived ramp visibly carries the warm tint in the
token browser, and the §9 near-the-line pairs still pass (see
`verification-and-drift.md`).
