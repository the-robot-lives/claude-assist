# Color Theory for Tuning

> Just enough color mechanics to adjust seed and palette values with intent — hue geometry, temperature, saturation budgets, tinted neutrals, and WCAG contrast math, all expressed as operations on `vars.yaml` seeds and `color-modes.yaml` values. This is deliberately duplicated theory (adapted from the UX Engineer's design references) so this skill functions standalone; it covers tuning existing decisions, not making new brand ones.

---

## 1. Hue Geometry as a Tuning Instrument

Hue is an angle (0-360°). Treatises pin hues as degree bands ("15-45° warm band",
"accent ±5°"), so you need the map:

| Band | Hues | Reads as |
|---|---|---|
| 0-15° | red | alarm, error, heat |
| 15-45° | orange/amber | warmth, energy, ember |
| 45-70° | yellow | caution, highlight |
| 70-160° | green | success, growth |
| 160-200° | cyan/teal | technology, clarity |
| 200-260° | blue | trust, info, cold |
| 260-310° | violet/purple | creativity, AI |
| 310-350° | magenta/rose | boldness, nightlife |

Relationships you'll tune against:

- **Monochrome + accent** — one hue family + neutrals. Tuning rule: a "second color" request is answered with a lightness/saturation step of the SAME hue, not a new hue, unless the treatise permits it.
- **Analogous** (within ~60°) — hues feel related; safe for secondary accents.
- **Complementary** (~180° apart) — maximum tension; in tuning, usually reserved for the one semantic that must break temperature (e.g., info-blue in a warm theme).
- **Collision distance** — two saturated hues within ~15° at similar lightness read as "the same color, slightly off" (looks like a bug). This is why treatises demand error red be "clearly redder" than a warm-orange brand: push ≥ 15-20° apart or separate strongly by lightness/saturation.

**Seed mapping:** hue decisions land in the `brand-*` and semantic seeds. When a treatise
gives a band (±5°), tune INSIDE the band to fix contrast before reaching for lightness
changes that alter the color's character.

## 2. Temperature and Tinted Neutrals

Temperature is the warm (red/orange/yellow) vs cool (blue/green) axis. A theme's
temperature lives less in its accent than in its **neutrals**:

- **Pure neutrals** (`#ffffff`/`#000000` seeds) → clinical, default-feeling. Fine for minimal-tech; wrong for any theme whose treatise says "warm" or "cool."
- **Tinted neutrals** — seed `white`/`black` with 2-8% saturation toward the theme hue; the engine's derived gray ramp then inherits the tint across all ~10 steps. This is the single highest-leverage temperature move in the engine: two seed values re-temperature the entire UI.

```yaml
# Warm theme (ember):        # Cool theme (phosphor):
white: "#f5efe8"             white: "#f2f5f8"
black: "#141110"             black: "#0e1116"
```

Tuning heuristics:

- Tint strength beyond ~10% saturation on near-black makes derived mid-grays visibly "muddy brown"/"navy" — if mid-ramp steps look dirty, reduce the seed's saturation, not its hue.
- Dark-native themes should rarely seed `black: "#000000"`: pure black kills the tint signal and creates harsh OLED smearing edges. `#101014`-region minimums keep material identity.
- Verify temperature coherence after tuning: semantic greens/blues in a warm theme usually need warming (olive over mint, slate over azure) or they'll look pasted in — this is the "harmonize, don't match" clause most treatises carry.

## 3. Saturation Budgets

Saturation is attention. The practical budget rule for tool UIs: **one fully saturated
element region per screen** (the primary action / active state); everything else muted.

| Layer | Saturation guidance |
|---|---|
| Canvas & surfaces | ≤ 10% (tint only) |
| Borders, dividers | ≤ 15% |
| Secondary UI, tags | 20-45% (often the accent's `-mid` derived tint) |
| Primary accent, CTAs | 60-90% |
| Semantic states | 45-70% — assertive but below the accent, unless state IS the point (dashboards) |

Tuning consequence: if a screen feels "loud," the fix is usually desaturating derived
usage (component vars pointing at `-light`/`-mid` tints) rather than dulling the accent
seed itself — the seed also drives the CTA where full saturation is correct.

## 4. Lightness, Elevation, and Dark-Mode Mechanics

- **Light modes** create depth with shadows on near-equal surfaces; **dark modes** create depth by stepping surface lightness up (~+4-8% per elevation step). In the engine: dark `color-modes` maps give `surface` < `surface-alt` < raised-surface snippets.
- **Accents brighten in dark mode.** A hue that passes 4.5:1 on white almost never passes on near-black at the same hex (and vice versa). Standard move: keep the seed for the primary mode, add a per-mode override via `scoped-vars` for the other (e.g., ember `#e8763a` dark / `#c85a20` light).
- **Never use pure white text on dark canvas** for body copy — 15:1+ contrast causes halation (glow blur) for astigmatic users. Warm/cool off-whites in the 12-15:1 range read more comfortably; the treatise's `white` seed usually already handles this.

## 5. WCAG Contrast Math

Contrast ratio = `(L1 + 0.05) / (L2 + 0.05)` where L is relative luminance (0-1).
Range 1:1 → 21:1. You don't compute this by hand — use a checker — but you must know
the thresholds and what counts:

| WCAG 2.2 criterion | Threshold | Applies to |
|---|---|---|
| 1.4.3 AA text | **4.5:1** | body-size text (< 24px / < 18.66px bold) vs its background |
| 1.4.3 AA large text | **3:1** | ≥ 24px, or ≥ 18.66px bold |
| 1.4.11 non-text | **3:1** | UI component boundaries, focus indicators, meaningful icons/graphics |
| 1.4.6 AAA text | **7:1** | when the treatise commits to AAA (long-session tools often do for dark body text) |

Quick luminance intuition for tuning direction:

- Contrast is dominated by **lightness difference**, not hue. Rotating hue barely moves the ratio; lightening/darkening moves it fast.
- Mid-lightness saturated hues (pure orange, medium blue) hover near 3-5:1 against both white AND black — the classic "accent as text" trap. Fix by reserving the accent for large text/UI (3:1 rule) or making a darker/lighter text-grade variant.
- The `-tint` backgrounds the cascade derives are light — dark semantic text on its own tint usually passes; white text on a tint usually fails. Check `semantic-classes` `color`-on-`background` pairs specifically.

**Checking without leaving the terminal:** any of

```bash
# quick single pair (node one-liner using WCAG formula)
node -e '
const L=h=>{const c=h.match(/\w\w/g).map(x=>parseInt(x,16)/255).map(v=>v<=0.03928?v/12.92:((v+0.055)/1.055)**2.4);return 0.2126*c[0]+0.7152*c[1]+0.0722*c[2]};
const [a,b]=process.argv.slice(1);const r=(Math.max(L(a),L(b))+0.05)/(Math.min(L(a),L(b))+0.05);
console.log(r.toFixed(2)+":1")' f5efe8 1a1512
```

plus the visual pass in the served viewer's color-palette section (see
`verification-and-drift.md`).

## 6. Worked Example: Fixing a Failing Pair Inside the Treatise's Constraints

Situation (ember): treatise §9 flags "secondary text must stay ≥ 4.5:1 — the warm tint
tempts it darker." First-draft dark `text-secondary: "#a89684"` measures **4.1:1** on
surface `#1a1512`. Fail.

Constraints in play: §3 warm band (stay ~25-35° hue), §3 contrast stance ("secondary may
drop to ~5:1 but never below 4.5:1"), §9 AA.

Options, evaluated:

| Move | Effect | Verdict |
|---|---|---|
| Rotate hue cooler | +0.1:1 at best; breaks §3 warm band | reject |
| Saturate more | negligible ratio change, louder chrome | reject |
| Lighten `#a89684` → `#c9beb2` | 4.1 → **6.8:1**; stays 28° warm | overshoot but safe; try midpoint |
| Midpoint `#b8ab9d` | **5.4:1**; matches the "~5:1" stance verbatim | **accept** |

Fix lands in `color-modes.yaml` (a semantic, not a seed — the seeds were right):

```yaml
color-modes:
  dark:
    text-secondary: "#b8ab9d"   # was #a89684 (4.1:1) — §9 fix, now 5.4:1 on #1a1512
```

Record in the conformance report: pair, before/after ratios, treatise clauses honored.
That traceability is what makes the next tuner trust the value.
