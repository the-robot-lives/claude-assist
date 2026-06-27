# US-23 — Accessibility check on a screen

**As** the product designer (`figma-product-designer`)
**I want** TRFI to surface basic accessibility issues against my authored `aria-*`/roles and the rendered structure,
**so that** a11y intent is verified before export rather than discovered in production.

**Priority:** P2  **Size:** M

## Acceptance criteria
- A screen can be checked for common a11y issues (missing labels/alt, contrast, heading order, required roles).
- Findings reference the specific element and the relevant `aria-*`/`data-*`/contrast rule.
- Authored `aria-*` attributes are respected and not flagged as missing when present.
- The check runs in the Editor and (at least) before/at export.
- Findings can be reviewed without blocking export (advisory) with severity levels.

## Notes / linked README concept
Builds on §1 first-class `aria-*` attributes; serves the a11y-conformance goals of personas Devon and Priya.
