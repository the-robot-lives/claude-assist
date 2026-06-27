# US-05 — Edit theme.yaml seed tokens and watch generated CSS

**As** the product designer (`figma-product-designer`)
**I want** to declare a small set of seed values (fonts, color roles, gap/spacing scale, radii, per-type form defs) in `theme.yaml` and have TRFI generate the full CSS,
**so that** I write ~12 values and the engine derives the type ramps, spacing tokens, and component classes.

**Priority:** P0  **Size:** M

## Acceptance criteria
- Theme Studio exposes the seed tokens (color roles, type, spacing/gap scale, radii, per-type forms).
- Changing a seed value regenerates derived CSS and updates the high-fi canvas live.
- Generated artifacts include type ramps, spacing tokens, and per-type component classes.
- `theme.yaml` mirrors the `components/styleguide` syntax.
- An invalid token value reports an error without breaking the last good generated CSS.

## Notes / linked README concept
§2 "Style values (the styleguide layer)" + Key Pages "Theme Studio". Few seeds → hundreds of derived values.
