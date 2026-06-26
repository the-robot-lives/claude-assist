# Design Theme Candidates

These are three distinct styleguide themes for `therobotsdayjob.com`, each using the
engine file convention (`style-guide.meta.yaml`, `style-guide.vars.yaml`, `branding.yaml`,
`style-guide.color-modes.yaml`):

1. **theme-control-floor** (`theme-control-floor/`, slug `control-floor`)
   - Minimal Tech baseline.
   - High contrast, dense dashboard feel.
   - Best fit when positioning as an operational control product.

2. **theme-warm-robotics** (`theme-warm-robotics/`, slug `warm-robotics`)
   - Consumer Playful/Editorial mix, warm and approachable.
   - Larger radius and brighter accents.
   - Best fit for a human-friendly product launch narrative.

3. **theme-nocturne-command** (`theme-nocturne-command/`, slug `nocturne-command`)
   - Nocturne command-console style.
   - Dark-first palette, low visual noise, strong status signals.
   - Best fit for technical teams and high-assurance operations.

Keep slugs bare. The current viewer reconstructs directories as `theme-{slug}`, so a
slug that already includes `theme-` will resolve to `theme-theme-{name}`.
