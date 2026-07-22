# THEMES — therobotlearns.com

Stage B similitude gate, effective-direction count, and the new directions authored to
reach ~7 effective. Screen allocation lives in
`design/asset-prompts/screens/allocation.yaml`.

## Framing: this is a terminal-first product

The Robot Learns has **no web server** — the "backend" is a Claude Code agent running in
`~/.config/the-robot-learns-kb/`. Of the 20 extracted screens, **19 are terminal / TUI
surfaces** (slash-command output, pagers, wizards, dashboards rendered *in a terminal*), and
**exactly one (`07-quiz-spa`) is a real browser page** (and even that is explicitly themeable
per US-052). These theme directories are still `@noizu/styleguide` CSS themes, but the
**surface Stage C renders them onto is a terminal window**, not a web page — the theme
supplies the color scheme / prompt styling / ANSI-adjacent palette, and Stage C should mock a
terminal, not a marketing page. The two new directions below lean deliberately into terminal
aesthetics to fit that reality; the existing seven were authored (in Stage A) as web themes
and vary in how naturally they survive being rendered as a terminal (see the render-set note).

## Similitude matrix (existing named themes, n = 7)

`theme-style-guide` (the shared base) is excluded per the gate rules. Scores `s(i,j) ∈ [0,1]`
judged across five axes: accent hue/value, palette temperature, typography family choice,
radius/shape language, and branding tone/keywords. `0` = no meaningful resemblance, `1` =
essentially the same theme.

|            | atlas | chalkbd | comic | deep-focus | scholar | spark | workbench |
|------------|:-----:|:-------:|:-----:|:----------:|:-------:|:-----:|:---------:|
| atlas      |   —   |  0.15   | 0.05  |    0.20    |  0.20   | 0.10  |   0.30    |
| chalkboard | 0.15  |    —    | 0.30  |    0.20    |  0.10   | 0.20  |   0.40    |
| comic      | 0.05  |  0.30   |   —   |    0.10    |  0.05   | 0.35  |   0.30    |
| deep-focus | 0.20  |  0.20   | 0.10  |     —      |  0.45   | 0.20  |   0.10    |
| scholar    | 0.20  |  0.10   | 0.05  |    0.45    |    —    | 0.20  |   0.10    |
| spark      | 0.10  |  0.20   | 0.35  |    0.20    |  0.20   |   —   |   0.30    |
| workbench  | 0.30  |  0.40   | 0.30  |    0.10    |  0.10   | 0.30  |     —     |

**Notable clusters (what pulls E down):**
- **deep-focus ↔ scholar = 0.45** — the two "minimal tech" siblings: neutral grotesque sans
  (IBM Plex Sans / Inter), no display face, Tailwind-derived semantics, low ornament,
  developer audience. They split only on primary mode (nocturne dark vs near-white) and accent
  (teal `#14b8a6` vs indigo `#6366F1`).
- **chalkboard ↔ workbench = 0.40** — the two "hand-drawn teaching" siblings: cursive/marker
  display faces (Patrick Hand / Caveat), full 13-color palettes, a "draw-it-out / sketch-it"
  metaphor, and the heavier structural tier (both ship `typography.yaml` + `css-snippets` +
  `globals`). They split on surface (dark green board vs cream paper) and palette family
  (desaturated chalk vs Flat-UI clay).
- **comic ↔ spark = 0.35** — both playful/vibrant and both lead with Nunito, but comic is loud
  high-saturation ink-outline (radius 0) while spark is soft rounded (radius 12) violet.

## E calculation

```
E = Σ_i [ Σ_{j≠i} (1 − s(i,j)) ] / (n − 1)          with n = 7
  = 7 − (2 / (n−1)) · Σ_{i<j} s(i,j)
  = 7 − (2 / 6) · 4.35
E = 5.55
```

(Σ of the 21 upper-triangle scores = 4.35; mean pairwise similitude s̄ = 0.207, so
`E = 7·(1 − s̄) = 5.55`.) The seven existing themes are genuinely diverse — but not seven
fully-distinct directions: the two clusters above cost ~1.45 effective directions.

**New directions needed:** `ceil(7 − E) = ceil(1.45) = 2`.

## New directions (2) — both terminal-native, mutually distinct

Chosen to be low-similitude against the existing seven **and** each other, and to fill the gap
none of the existing themes occupy: a genuine terminal aesthetic for a terminal-first product.

- **phosphor** — a monochrome amber-CRT terminal. Single-hue amber phosphor glow on true dark,
  fixed-width mono as the *primary UI face* (not just code), radius 0, box-drawing chrome. No
  existing theme is monochrome or mono-primary; distinct from deep-focus (teal/sans/web-minimal)
  and from the greens of chalkboard. Retro, warm, machine.
- **cockpit** — a modern dense TUI / "mission control" (k9s / btop / lazygit lineage). Cool
  graphite base, box-drawing panes + meter bars, a single electric-magenta signal with
  disciplined semantic status colors, mono for data + a tight grotesk for labels, radius 0–1.
  Distinct from phosphor (modern/cool/multi-signal vs retro/warm/monochrome) and from deep-focus
  (dense instrument vs calm minimal). Serves the dashboard/console screens directly.

`s(phosphor, cockpit) ≈ 0.20` (shared DNA: dark terminal surface — deliberate, per the brief;
split on era, temperature, and signal discipline). Both score ≤ 0.25 against every existing
theme. Effective directions after adding both ≈ **7.1**.

## Render set vs deferred (a screen-count constraint, flagged for template v2)

`verify.md` §B hard-fails any theme with < 5 allocated screens. With **20 screens** the
`unique` set must hold all 20 (the <30-screen rule), and `overlap` is capped at 5 pairs, so the
**maximum render slots = 20 + 2·5 = 30**. Nine themes at 5 each need 45; even seven need 35.
**At most 6 themes can pass the per-theme 5–8 check at this screen count** — this would fail for
the full roster regardless of how many new themes were authored.

Resolution for this pass: **all 9 themes get treatises** (design intent fully captured), but
`allocation.yaml` distributes renders to the **6 most terminal-appropriate** directions, each
exactly 5 screens (clean §B pass):

- **Rendered (6):** `phosphor`, `cockpit`, `deep-focus`, `scholar`, `chalkboard`, `workbench`
  — the six that read naturally as a terminal/TUI surface.
- **Deferred (3):** `atlas` (editorial serif — a long-form *reading page*, least terminal-like),
  `comic` (graphic-novel panels), `spark` (rounded consumer web). Treatises are written and
  kept; these are simply absent from `allocation.yaml` this pass (so §B only scores the six
  rendered themes) and are seeded `status: deferred` in `stage_c.themes`. They can render in a
  later pass if screens are added or the per-theme floor is relaxed for high-theme projects.

**Template friction:** the §B per-theme 5–8 floor and the §3 "distribute across every theme"
instruction are jointly unsatisfiable when `screens < 5 × themes`. Recommend a v2 fix (e.g.
raise the overlap cap, or scale the per-theme floor by `screens / themes`).
