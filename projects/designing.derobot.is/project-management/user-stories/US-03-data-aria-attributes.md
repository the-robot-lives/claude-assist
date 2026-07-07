# US-03 — First-class data-* and aria-* attributes

**As** the product designer (`figma-product-designer`)
**I want** to write `data-*` and `aria-*` attributes directly on any element in the DSL,
**so that** accessibility and behavior intent are authored in from the start and survive all the way to export.

**Priority:** P1  **Size:** S

## Acceptance criteria
- `aria-required=true`, `aria-label="…"`, `data-action="submit"` etc. parse on any element.
- Attribute values support booleans, numbers, and quoted strings.
- Authored `data-*`/`aria-*` appear unchanged in low-fi render, high-fi render, and every export target.
- Upverting an element retains its `data-*`/`aria-*` attributes in the structured form.
- Invalid attribute syntax errors on the specific attribute, not the whole element.

## Notes / linked README concept
§1 "`data-*` and `aria-*` attributes are first-class". Key to a11y intent surviving handoff (see persona Devon).
