# US-01 — Author a screen in the text DSL

**As** the solo founder (`solo-founder-validating`)
**I want** to author a screen as indented, declarative text where each line is a typed element with an optional label/value,
**so that** I can sketch a whole screen by typing instead of dragging boxes with a mouse.

**Priority:** P0  **Size:** S

## Acceptance criteria
- A `screen "Name" { ... }` block with nested `stack`/`row` containers parses into a render tree.
- Each line accepts `type`, an optional quoted label/value, and inline attributes (e.g. `gap=lg`, `placeholder="…"`).
- Indentation/braces establish parent-child nesting in the rendered output.
- A syntax error reports the offending line and column without discarding valid siblings.
- The exact text source is preserved verbatim as the canonical artifact.

## Notes / linked README concept
Core loop entry point — §1 "The text DSL (the sketch you can type)". This is the canonical source that every later stage enriches.
