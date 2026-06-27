# Sam Velez — AI / Agent Engineer ("The Robot" Operator)

**Tagline:** "I don't open the editor — my agent does. Every operation has to be an MCP tool."

## Demographics / context
- 36, builds autonomous agent workflows; orchestrates LLM tool-use pipelines.
- Drives TRFI almost entirely through MCP from his own agent harness, not the GUI.
- Thinks in tool surfaces, idempotency, and deterministic state — not mouse clicks.
- Runs prototypes as part of larger "fake the product, then test it" agent loops.

## Goals
- Have an agent author, theme, wire, and run a prototype end-to-end with no human in the editor.
- Treat the prototype as program state the robot can read, mutate, and re-run reliably.
- Compose TRFI operations into bigger pipelines (gen spec → build screens → run → evaluate).
- Get clean, structured tool responses he can branch on programmatically.

## Frustrations / pain points with current tools
- Design tools are mouse-bound and effectively un-driveable by an agent.
- "API access" to prototyping tools is usually a thin afterthought, not the full surface.
- Faked prototypes can't hit real endpoints or models, so agent tests aren't realistic.
- State is hidden in a GUI session instead of being addressable and persistable.

## How he'd use TRFI specifically
- Calls **MCP tools** to create screens, set element attributes, define theme tokens, toggle fidelity, upvert regions, wire FSM transitions, and run the prototype.
- Has the robot write the **text DSL** directly — it's the most agent-writable authoring form.
- Binds **FSM transitions to real APIs/webhooks and LLM calls** so the fake behaves like production under test.
- Uses the **key-value store** as durable agent state across a prototype run.
- Exports **Lit/HTML** programmatically as the artifact handed to downstream steps.

## Key features he cares about
- **MCP-managed everything** — full parity between GUI and tool surface.
- **FSM + API/webhook + LLM bindings** — convincing, testable behavior.
- **Key-value store** — addressable, persistent prototype state.
- **Text DSL** — the canonical, agent-friendly authoring format.
- **Programmatic export** — prototypes flow into the next pipeline stage.

## Representative quote
> "If a human can do it in the editor but my agent can't do it over MCP, that operation effectively doesn't exist to me."

## Success looks like
His agent goes from a one-line product brief to a running, API-backed prototype and a Lit export with zero GUI interaction — and the run is reproducible.
