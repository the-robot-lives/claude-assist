# US-15 — Define a finite state machine for a prototype

**As** the AI / agent engineer (`agent-mcp-operator`)
**I want** to define an FSM for a prototype with states and transitions fired by user interaction,
**so that** the prototype is interactive program state I can read, mutate, and re-run — not static layout.

**Priority:** P0  **Size:** M

## Acceptance criteria
- A prototype can declare named states and an initial state.
- Transitions are defined between states with triggers (clicks, input, navigation).
- User interaction in the Prototype Player fires the matching transition and advances state.
- Current state is queryable and drives what the screen renders.
- An invalid/dangling transition target is reported at definition time.

## Notes / linked README concept
§6 "Interactivity: FSM + integrations" + Key Pages "Prototype Player". The backbone interactions hang off.
