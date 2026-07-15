# Styleguide

YAML-driven design system for the Noizu portfolio.

| Path | Role | Status |
|------|------|--------|
| **`hologram/`** | Interactive viewer (Elixir + Hologram + static HTML/CSS/YAML) | **Canonical — no TypeScript** |
| **`app/`** | Optional CSS generator + legacy Next.js / npm package | Not required to run the Hologram viewer |

## Run the viewer

```bash
cd hologram
mix deps.get
HOLOGRAM_START=1 mix holo
# http://localhost:4500
# http://localhost:4500/tailwind-plus
```

## Roles

- **`hologram/`** — full style guide + Tailwind Plus catalog. Pure Elixir/Hologram; demos and theme CSS are committed static files under `priv/static/`.
- **`app/`** — historical Next.js engine and `@noizu/styleguide` React package for projects that still need npm. Do not treat as the viewer.

## Assets in Hologram

| Asset | Location |
|-------|----------|
| Theme CSS | `hologram/priv/static/themes/*.css` |
| Tailwind Plus demos | `hologram/priv/static/twp/demos/**/*.html` |
| Catalog index | `hologram/priv/static/twp/registry.json` |
| Theme YAML (reference) | `hologram/themes/theme-*/` |

Edit those files in place. There is no TypeScript source of truth inside `hologram/`.
