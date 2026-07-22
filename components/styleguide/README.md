# Styleguide

YAML-driven design system for the Noizu portfolio.

| Path | Role | Status |
|------|------|--------|
| **`../hologram-start-app`** | Interactive viewer + Hologram components | **Canonical** |
| **`app/`** | Optional CSS generator + legacy Next.js / npm package | Node tooling only |
| **`hologram/`** | Pointer only — viewer was moved into hologram-start-app | Retired |

## Run the viewer

```bash
cd ../hologram-start-app/backend
mix deps.get
HOLOGRAM_START=1 mix holo
# /styleguide  ·  /styleguide/tailwind-plus
```

## Roles

- **`hologram-start-app`** — full style guide, multi-theme YAML, Tailwind Plus demos, and app scaffold UI.
- **`app/`** — historical Next.js engine and `@noizu/styleguide` React package for projects that still need npm. Do not treat as the interactive viewer.
