# US-19 — MCP agent-driven authoring

**As** the AI / agent engineer (`agent-mcp-operator`)
**I want** every editor operation — create screen, edit element, define theme token, toggle fidelity, upvert a region, wire an FSM transition, export — exposed as an MCP tool,
**so that** my agent can author a prototype end-to-end with no human in the editor.

**Priority:** P0  **Size:** M

## Acceptance criteria
- There is full parity: every operation available in the GUI is available as an MCP tool.
- MCP tools cover create/edit screen + element, theme token edits, fidelity toggle, upvert (incl. hybrid), FSM wiring, and export.
- Tool responses are structured so an agent can branch on results programmatically.
- Operations are idempotent/addressable enough to be safely re-run.
- A human and an agent can operate on the same prototype (human-in-the-loop).

## Notes / linked README concept
§7 "MCP-managed" — "Agents drive TRFI the same way a human does through the editor." Persona Sam's hard requirement.
