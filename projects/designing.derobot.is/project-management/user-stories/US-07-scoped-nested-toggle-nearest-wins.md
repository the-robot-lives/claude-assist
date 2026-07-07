# US-07 — Scoped, nested toggle with nearest-wins resolution

**As** the UX researcher / PM (`ux-researcher-pm`)
**I want** to set the fidelity toggle on any subtree (e.g. a single card) with the nearest toggle in the ancestor chain winning for a given element,
**so that** I can present a mostly-sketched screen with one or two regions brought to life to direct attention.

**Priority:** P1  **Size:** M

## Acceptance criteria
- A toggle can be attached to any container/subtree, not just the screen root.
- Flipping a card to high-fi renders only that card hi-fi while its parents stay low-fi.
- When multiple toggles exist in an ancestor chain, the nearest ancestor toggle determines an element's mode.
- An element with no toggle in its chain falls back to the screen-level default.
- Nesting is unbounded; arbitrarily deep subtree toggles resolve correctly.

## Notes / linked README concept
§3 "The toggle is scoped and nested … the nearest one wins". Enables progressive, region-by-region fidelity.
