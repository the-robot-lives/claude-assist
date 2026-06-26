# Design Theme Candidates

These are three distinct styleguide themes for `therobotsdayjob.com`, each using the
engine file convention (`style-guide.meta.yaml`, `style-guide.vars.yaml`, `branding.yaml`,
`style-guide.color-modes.yaml`):

1. **theme-control-floor** (`theme-control-floor/`, slug `control-floor`)
   - Minimal Tech / operations software.
   - Inter + IBM Plex Mono, compact 8px grid, 6px radius.
   - Cool white/slate surfaces, blue primary actions, teal operations accent.
   - Best fit when positioning as a serious workflow-control product.

2. **theme-warm-robotics** (`theme-warm-robotics/`, slug `warm-robotics`)
   - Consumer Playful / service-product warmth.
   - Nunito + Space Mono, roomier 10px grid, 18px radius.
   - Cream/paper surfaces, coral primary, teal secondary, sunny yellow accent.
   - Best fit for a human-friendly product launch narrative.

3. **theme-nocturne-command** (`theme-nocturne-command/`, slug `nocturne-command`)
   - Nocturne / command-console interface.
   - IBM Plex Sans Condensed + JetBrains Mono, dense 6px grid, 3px radius.
   - Near-black surfaces, cyan signal primary, magenta danger, phosphor yellow review state.
   - Best fit for technical teams and high-assurance operations.

Each candidate defines `vars`, `typography`, `color-palette`, `spacing`, `branding`,
and `color-modes` so the viewer has enough information to render an actual visual
direction, not only seed colors.

Keep slugs bare. The current viewer reconstructs directories as `theme-{slug}`, so a
slug that already includes `theme-` will resolve to `theme-theme-{name}`.
