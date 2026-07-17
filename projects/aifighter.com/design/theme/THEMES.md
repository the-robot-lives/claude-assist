# AI Fighter — Theme Directions & Similitude

Stage B similitude gate for `aifighter.com`.

## Existing themes and E

Census `existing_named_themes: []` — there are **zero** named theme directories under
`design/theme/`. (The `app/frontend/src/config/theme-style-guide/` scaffold is the engine base,
not a project theme, and is excluded per the gate rules.)

With `n = 0` existing themes there is nothing to score pairwise, so the effective-direction
count is:

```
E = 0        (n = 0 ⇒ E = 0; no similitude matrix — nothing on disk to compare)
new_themes_needed = ceil(7 − E) = ceil(7 − 0) = 7
```

All **7** directions below are authored fresh. The README ships one stated aesthetic intent
("Neural Neon" — Bold Expressive + Minimal Tech); that intent is captured faithfully by the
`neural-neon` direction, and the other six deliberately stake out genuinely different aesthetic
territory so the pilot review gate has real alternatives, not six flavors of the same neon.

## The 7 fresh directions

| Slug | Name | Territory | Register | Dominant hue | Shape | Type signal |
|---|---|---|---|---|---|---|
| `neural-neon` | Neural Neon | Cyber-arcade, "inside the machine" | Dark, electric, maximal | Electric mint 160° + blue 225° + pink 340° | Glassmorphism, 8–12px, neon glow | Extended display (Monument/Space Grotesk) |
| `signal` | Signal | Scientific instrument / oscilloscope | **Light**, cool, precise, restrained | Single phosphor teal 172° | Thin 1px grid, 2–4px, flat | **Mono-forward** (JetBrains/IBM Plex Mono) |
| `arcade` | Arcade | Warm CRT fighting cabinet | Dark-**warm**, punchy, nostalgic | Arcade red 350° + cabinet amber 44° | Chunky bevels, 2–6px, thick 2–3px bezels | Condensed heavy marquee |
| `biolume` | Biolume | Living neural tissue, bioluminescence | Dark-**violet**, soft, wondrous | Bio-teal 165° + neuron magenta 285° | **Organic**, 12–20px, soft diffuse glow | Rounded humanist |
| `versus` | Versus | Brutalist esports scoreboard | **Light**, achromatic, aggressive | **Pure neutrals** + one blood-orange 14° signal | **Hard 0px**, 2–3px black rules, flat | Heavy grotesque (Archivo Black / Anton) |
| `obsidian` | Obsidian | Premium cinematic collector | Dark, warm-**neutral**, restrained luxury | Near-monochrome + single molten-gold 42° | Refined 4–8px, hairline + tonal elevation | **Serif display** (the only serif) |
| `sandbox` | Sandbox | Playful toy / "not a textbook" | **Light**, warm-bright, candy | Multi-hue candy: coral 7°, sunny 46°, grape 258° | Soft 16–24px, pills, big soft shadows | Rounded playful bold (Fredoka/Nunito) |

## Why they are mutually distinct

Distinctness is engineered along five axes so no two directions collapse into one effective
direction. The spread:

- **Mode/temperature:** 3 dark (neural-neon cool-blue, biolume violet, obsidian warm-neutral —
  three *different* black hues), 1 dark-warm (arcade), 3 light (signal cool, versus achromatic,
  sandbox warm-candy).
- **Saturation discipline:** maximal multi-hue (neural-neon, sandbox), single restrained accent
  (signal, obsidian), one hot signal on neutrals (versus), soft-diffuse organic (biolume),
  warm-punchy dual (arcade).
- **Shape language:** hard 0px (versus) → sharp 2–4px flat (signal) → chunky beveled (arcade) →
  glassy 8–12px (neural-neon) → refined 4–8px tonal (obsidian) → soft 16–24px (biolume, sandbox).
- **Type voice:** the seven pick *seven different* display registers — extended, mono-forward,
  condensed marquee, rounded humanist, heavy grotesque, serif, rounded playful — so a screenshot
  is identifiable by its lettering alone.
- **Motion:** instrumental-snappy (signal, versus) vs punchy-juice (arcade) vs breathing-organic
  (biolume) vs cinematic-smooth (obsidian) vs bouncy-delight (sandbox) vs confirm-causality glow
  (neural-neon).

## Target (intended) similitude

No on-disk matrix exists (n = 0). These are the **design targets** I held while authoring — the
maximum acceptable pairwise similitude `s ∈ [0,1]`, `0` = unrelated, `1` = same theme. Every pair
is kept at or below ~0.30; the two closest pairs are handled deliberately:

| Closest pairs | Shared trait | How they are split | Target s |
|---|---|---|---|
| neural-neon ↔ biolume | both dark + glow | blue-black hard neon + geometric/extended vs violet-black soft bioluminescence + organic/rounded + breathing motion | ~0.30 |
| signal ↔ versus | both light + restrained | cool-thin-precise mono instrument vs achromatic-heavy-loud brutalist grotesque | ~0.30 |
| biolume ↔ sandbox | both rounded | dark bioluminescent flowing vs light candy bouncy | ~0.25 |
| signal ↔ sandbox | both light | cool serious instrument vs warm playful toy | ~0.20 |
| obsidian ↔ arcade | both warm-dark | refined near-monochrome serif vs punchy red/amber marquee CRT | ~0.20 |
| all other pairs | — | different mode + hue + shape + type | ≤ 0.15 |

Mean cross-direction distinctness `(1 − s)` ≈ 0.82 — the seven read as seven, giving the review
gate a genuine span from clinical-light to cyber-dark to premium-collector to playful-toy.

Each direction has a full treatise at `treatise-{slug}.md` (10 canonical sections, `status:
sketch`). Screen allocation across all seven is in
`design/asset-prompts/screens/allocation.yaml`.
