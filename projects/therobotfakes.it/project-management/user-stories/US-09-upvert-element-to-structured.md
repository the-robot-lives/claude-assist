# US-09 — Upvert a text element to the structured form

**As** the frontend engineer (`design-system-frontend-engineer`)
**I want** to upvert a text element to a richer XHTML-like structured representation,
**so that** I can express fine-grained control the coarse text form can't, and feed generation-quality markup into export.

**Priority:** P1  **Size:** M

## Acceptance criteria
- Any element can be upverted to the structured representation on demand.
- The structured form exposes finer control (nested structure, per-node attributes/classes) than text.
- The upverted representation becomes the input used to generate Next.js / HTML / CSS / Lit output for that item.
- Re-rendering an upverted element is visually consistent with its prior text render unless deliberately changed.
- Upvert is reversible/inspectable against the retained text source (see US-11).

## Notes / linked README concept
§4 "Upverting (text → fine-grained format)". The richer form is what drives final code generation.
