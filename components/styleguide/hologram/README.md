# Styleguide Hologram viewer — moved

The interactive Hologram design-system viewer and components now live in:

**`components/hologram-start-app`**

| What | Where |
|------|--------|
| Components (`Btn`, `Card`, `ColorSwatch`, …) | `hologram-start-app/backend/lib/starter_web/hologram/components/` |
| Viewer sections | `…/hologram/sections/` |
| Style guide page | `/styleguide` → `StyleGuidePage` |
| Tailwind Plus | `/styleguide/tailwind-plus` |
| Theme YAML | `hologram-start-app/backend/themes/theme-*/` |
| Theme CSS | `hologram-start-app/backend/priv/static/themes/` |

```bash
cd components/hologram-start-app/backend
mix deps.get
HOLOGRAM_START=1 mix holo
# open http://localhost:5585/styleguide  (or your configured port)
```

This directory is intentionally empty of application code so scaffolds do not
duplicate the component library. Optional Node CSS generation remains in
`../app/` (`@noizu/styleguide` package).
