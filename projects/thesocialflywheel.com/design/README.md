# Flywheel — Design Directions

Three **circle-centric** "social-networking-with-a-twist" theme candidates for
thesocialflywheel.com. Each is a complete styleguide-engine theme (meta + vars +
branding + color-modes) plus a standalone SVG logo. All three render the product's
core mechanic — a web of mutuals across degrees — as a circular motif, but each
takes a different conceptual *twist*.

| Theme | Slug | Twist (the "novel" hook) | Mood / style | Circle motif |
|-------|------|--------------------------|--------------|--------------|
| **Orbit** | `orbit` | Mutuals are **bodies in orbit**; degrees of separation are orbital rings; the web has *gravity*. | Cosmic Nocturne (dark-native) + Minimal Tech | Concentric orbital ellipses around a luminous core |
| **Ripple** | `ripple` | Every post is a **stone dropped in water** — ideas ripple outward through your web; opposing views ripple **back** from the far edge. | Calm light, Minimal Tech + Consumer Playful | Concentric ripples; coral outer counter-current |
| **Commons** | `commons` | You connect through **both common ground *and* difference** — overlapping **Venn** circles; the shared lens is where serendipity lives. | Bold Expressive, warm | Three overlapping saturated circles (Venn) |

## Palettes (seed colors)

| Theme | Canvas | Primary | Secondary | Tertiary | Counter / opposing |
|-------|--------|---------|-----------|----------|--------------------|
| Orbit | `#080b16` deep-space indigo | `#3ce0ff` cyan core | `#8b7bff` violet orbit | `#ffd166` star gold | `#fb7185` |
| Ripple | `#f6fbfb` sea-foam | `#10b3b8` teal drop | `#1d9bf0` water blue | `#ffc94d` sun gold | `#ff6b5e` coral |
| Commons | `#fbf7ef` cream | `#e5337a` magenta | `#4733e5` indigo | `#f2a900` amber | `#2bb673` |

> In the engine's seed schema the accent slots are named `red`/`blue`/`yellow` —
> those names are just the seed keys; the actual hues are the brand colors above.

## Files

```
design/
  theme/
    theme-orbit/    { style-guide.meta.yaml, style-guide.vars.yaml,
    theme-ripple/     branding.yaml (inline SVG logo), style-guide.color-modes.yaml }
    theme-commons/
  logos/
    flywheel-orbit.svg     flywheel-ripple.svg     flywheel-commons.svg
```

Each `branding.yaml` embeds a 34px navbar logomark (in `logo-style.html`) that
references the theme's CSS custom properties, so the mark recolors with the theme.
The `logos/*.svg` files are larger standalone combomarks with literal colors for
portability (decks, favicons, handoff). Logo text is still live `<text>` — convert
to paths before production delivery.

## Preview the themes (interactive style guide)

From this project directory, point the styleguide launcher at the theme folder —
it auto-copies the canonical base theme, generates CSS, and starts the viewer with
a theme picker so you can compare all three side by side and toggle light/dark:

```bash
npx @noizu/styleguide serve ./design/theme/
# add --clean to rebuild a stale viewer cache after a package upgrade
```

Resolve any `✗` (red, breaks render) then `⚠` (amber, degrades) messages shown in
the console and the in-viewer alert card.

## Status

Candidate directions for selection. Next steps once one (or a blend) is chosen:
spacing/typography refinement, full favicon + reversed/mono logo variants, and
wiring the chosen theme into the project frontend.
