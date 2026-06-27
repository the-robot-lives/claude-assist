# US-20 — Run a prototype over MCP with structured results

**As** the AI / agent engineer (`agent-mcp-operator`)
**I want** to run a prototype and drive its FSM via MCP, receiving structured state and outputs,
**so that** I can compose TRFI runs into larger agent pipelines (gen spec → build → run → evaluate).

**Priority:** P1  **Size:** M

## Acceptance criteria
- An MCP tool starts/loads a prototype run and returns its current state.
- An MCP tool fires a named transition (with inputs) and returns the resulting state + element data.
- Key-value store reads/writes are available over MCP during a run.
- Responses are structured (machine-parseable), not just rendered HTML.
- A run is reproducible given the same inputs and seeds.

## Notes / linked README concept
§7 "run a prototype … exposed as an MCP tool" + persona Sam's reproducible-pipeline goal.
