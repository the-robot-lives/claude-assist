# US-12 — Export Lit web components

**As** the frontend engineer (`design-system-frontend-engineer`)
**I want** to export each widget as a standards-based Lit custom element,
**so that** a prototyped component is reusable everywhere custom elements run, without a rewrite.

**Priority:** P0  **Size:** M

## Acceptance criteria
- A screen or selected widget exports as one or more Lit web components.
- Exported elements are standards-based custom elements (encapsulated, no global CSS leakage).
- Generated styles come from the resolved `theme.yaml`-derived CSS.
- Authored `aria-*`/`data-*` are present on the exported element.
- The export is driven by the upverted structured form where one exists, the DSL otherwise.

## Notes / linked README concept
§5 "Lit web components (primary)" + Key Pages "Export panel". Lit preferred precisely so components travel everywhere.
