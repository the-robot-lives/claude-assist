# US-18 — Key-value store for state persistence

**As** the UX researcher / PM (`ux-researcher-pm`)
**I want** the prototype to persist state through a built-in key-value store,
**so that** the flow remembers data across a session and behaves like the finished product during a test.

**Priority:** P1  **Size:** M

## Acceptance criteria
- Transitions can read and write named keys in a built-in key-value store.
- Stored values persist across state transitions within a session.
- Stored values can be interpolated into element content, API bodies, and LLM prompts.
- The store can be inspected and reset between participants/runs.
- Persistence scope (per-session vs per-prototype) is defined and documented.

## Notes / linked README concept
§6 "Persist state through a built-in key-value store … remember state across a session."
