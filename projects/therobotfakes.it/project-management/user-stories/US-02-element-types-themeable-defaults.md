# US-02 — Element types with themeable default classes

**As** the product designer (`figma-product-designer`)
**I want** each element type (`heading`, `text`, `field`, `button`, `row`, `stack`, `card`, `table`, `list`, `image`, `tabs`, …) to carry sensible default classes configurable per project and per theme,
**so that** I get coherent structure and styling from a bare type name without restyling every element by hand.

**Priority:** P0  **Size:** S

## Acceptance criteria
- A documented set of built-in element types each renders with a default class set.
- Defaults are overridable at the project level and at the theme level.
- A modifier keyword (e.g. `button primary`, `text muted`) maps to a variant class.
- Unknown element types surface a clear, recoverable error.
- Per-type form definitions are sourced from `theme.yaml` (mirroring `components/styleguide`).

## Notes / linked README concept
§1 element types + §2 "per-type form definitions". Defaults are the leverage that makes one typed line produce styled output.
