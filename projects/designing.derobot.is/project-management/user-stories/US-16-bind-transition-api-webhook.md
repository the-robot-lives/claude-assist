# US-16 — Bind a transition to an API / webhook call

**As** the UX researcher / PM (`ux-researcher-pm`)
**I want** to bind an FSM transition to a real API or webhook call that populates elements with live data,
**so that** my test prototype returns real-looking results and participants experience genuine behavior.

**Priority:** P1  **Size:** M

## Acceptance criteria
- A transition can be configured to call an HTTP API/webhook with method, URL, headers, and body.
- The response can be mapped into element values/content on the resulting state.
- Loading, success, and error outcomes can drive different transitions/states.
- Secrets/auth for the call are configurable without hard-coding into the shared artifact.
- The call fires live during a Prototype Player run.

## Notes / linked README concept
§6 "Call APIs / webhooks to populate elements with live data." Lets the fake hit a real endpoint.
