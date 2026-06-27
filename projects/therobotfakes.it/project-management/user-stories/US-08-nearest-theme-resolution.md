# US-08 — Nearest-theme resolution in the tree

**As** the product designer (`figma-product-designer`)
**I want** the nearest theme set in an element's ancestor chain to supply the CSS classes when rendering high-fi,
**so that** I can apply different themes to different regions of one screen and have each region pick up the right styles.

**Priority:** P2  **Size:** M

## Acceptance criteria
- A theme can be assigned to any subtree, not only the screen root.
- For a high-fi element, the nearest ancestor theme provides its generated CSS classes.
- An element with no theme in its chain uses the project/default theme.
- Changing a subtree's theme re-resolves classes for that subtree only.
- Theme resolution is independent of fidelity-toggle resolution but composes with it.

## Notes / linked README concept
§3 "the nearest theme in the tree supplies the CSS classes". Distinct axis from the fidelity toggle's nearest-wins.
