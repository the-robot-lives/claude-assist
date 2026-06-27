# US-17 — LLM-populated / responsive content

**As** the agency consultant (`agency-consultant-demos`)
**I want** to bind a transition to an LLM call that generates or responds to content,
**so that** the one feature a client doubts actually works live in the pitch.

**Priority:** P1  **Size:** M

## Acceptance criteria
- A transition can invoke an LLM with a prompt that interpolates current state / input / key-value data.
- The model output maps into element content on the resulting state.
- Streaming or completed responses both render acceptably in the player.
- LLM provider/model and credentials are configurable per prototype.
- Errors/timeouts route to a defined fallback state.

## Notes / linked README concept
§6 "Call LLMs to generate or respond to content." Part of what lets the robot "fake it" convincingly.
