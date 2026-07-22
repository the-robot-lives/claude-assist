# M2 — Script Graph & Agent Connectors

**Impl-plan stages:** 3, 4 · **Stories:** 25

## Mission

Ship the two things a run needs as input: a published script version and a published
agent version. Lane A builds the conversation-graph editor — the product's hero
surface — with nodes, edges, expectations, versioning, diff, fork, and YAML round-trip.
Lane B builds the agent adapter layer with health checks, cost caps, and multiple
providers. The lanes are independent and run in parallel.

## Entry criteria

- M1 exit: prompts, rubrics, personas publishable; reference stubs in schema.
- YAML script schema frozen (M0 Lane B).

## Exit criteria

- A script with system/user/terminal/freeball-anchor nodes, prompt references,
  weighted expectations, and match-condition edges can be authored in the graph editor
  and published as v1.
- YAML import → export round-trips losslessly against the frozen schema (US-007/008).
- Stub references finalized: US-011 (prompt-in-node), US-034 (rubric-on-expectation),
  US-051 (persona-layered expectations) now resolve end-to-end.
- An OpenAI agent passes a health check and is published as a version (US-012/013/014).

## Lane A — Script graph & versioning (15 stories)

**Zone / exclusive surfaces:** `app/backend/lib/codefresh/scripts/`, graph-editor +
script list/diff screens in `app/frontend/` (graph-canvas, node-detail-pane,
edge-inspector components).

| Story | Title | Pri |
|---|---|---|
| US-001 | Create an empty script with name and description | P0 |
| US-002 | Add a user-turn node to a script | P0 |
| US-003 | Attach a prompt to a script node | P0 |
| US-004 | Add an expectation to a script node | P0 |
| US-005 | Add a directed edge between two nodes with a match condition | P0 |
| US-006 | Publish the first version of a script | P0 |
| US-007 | Import a script from a YAML file | P0 |
| US-008 | Export a script to YAML | P0 |
| US-041 | Add a system-prompt node to a script | P1 |
| US-042 | Add a terminal node to mark the end of a conversation path | P1 |
| US-043 | Add a freeball-anchor node to explicitly invite freeball from a point | P1 |
| US-044 | Start a new draft from a published script version | P1 |
| US-045 | Diff two script versions visually | P1 |
| US-046 | Fork a published script into a new independent head | P1 |
| US-047 | Archive a script | P1 |

(US-111, US-112, US-113 were in this area and are cancelled.)

## Lane B — Agent connectors (10 stories)

**Zone / exclusive surfaces:** `app/backend/lib/codefresh/agents/` (incl. `adapters/`),
agent list/detail screens, adapter-config-form component.

| Story | Title | Pri |
|---|---|---|
| US-012 | Configure an OpenAI agent adapter | P0 |
| US-013 | Test agent connectivity with a health check | P0 |
| US-014 | Publish an agent version | P0 |
| US-061 | Configure an Anthropic agent adapter | P1 |
| US-062 | Configure a LangChain agent adapter | P1 |
| US-063 | Configure an arbitrary HTTP agent adapter | P1 |
| US-064 | Set per-agent cost cap and rate limit | P1 |
| US-065 | See agent connection health at a glance on the agent list | P1 |
| US-122 | Bedrock and Vertex AI agent adapters | P2 |
| US-123 | Agent response streaming support | P2 |

## Cross-lane integration task

Author a script in the editor that references a published prompt, attach a rubric-backed
expectation and a persona-layered expectation, publish it, export to YAML, re-import,
and confirm the published OpenAI agent is selectable as a run target (run trigger itself
lands in M3).
