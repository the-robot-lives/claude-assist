# Memory UI / MCP — API Contract (Phase D)

Shared contract between the Phoenix backend, the Next.js frontend, and the MCP
tool surface. Backend and frontend are implemented against this document;
deviations must be reflected here first.

All routes live under the `:authenticated` pipeline (Guardian JWT). Roles:
`viewer` may read graph data and run recall previews; `editor`+ may tweak
weights. All memory access is additionally owner/classification-gated by
Sentinel — the API must never return memories the requesting context could not
recall.

## GET /api/v1/memory/agents

List agents with memory state (from `memory_agent_state` + memory counts).

```json
{ "agents": [ { "agent_id": "local", "current_bucket": "neutral",
                "memory_count": 1234, "edge_count": 5678 } ] }
```

## GET /api/v1/memory/agents/:agent_id/graph

Query params: `compartment` (optional), `min_weight` (float, default 0.2),
`hops` (int, default 2, max 3, only used with `seed`), `seed` (memory uuid —
when present return the traversal neighborhood, else the whole ≥min_weight
subgraph), `limit` (node cap, default 500).

```json
{
  "nodes": [ { "id": "uuid", "summary": "…", "content_type": "episodic",
               "state": "active", "compartment": "default",
               "salience": 0.83, "decay_weight": 0.9, "pinned": false,
               "valence": 0.2, "arousal": 0.5,
               "recall_count": 4, "occurred_at": "…" } ],
  "edges": [ { "id": "uuid", "source": "uuid", "target": "uuid",
               "type": "semantic", "weight": 0.7,
               "reinforcement_count": 3, "last_reinforced_at": "…" } ],
  "truncated": false
}
```

## POST /api/v1/memory/agents/:agent_id/recall/preview

Side-effect-free recall: MUST NOT enqueue Hebbian reinforcement; the
`recall_log` row is either skipped or written with `mode: "preview"`.

Request:
```json
{ "query": "text …",
  "mood": { "valence": 0.1, "arousal": 0.4, "dominance": 0.0,
            "cortisol": 0.3, "dopamine": 0.5, "oxytocin": 0.4, "serotonin": 0.5 },
  "limit": 12,
  "overrides": { "rrf_k": 60, "vector_weights": { "content": 1.0 } } }
```
`query` and `mood` are each optional but at least one is required; `overrides`
maps onto `Recall.config/0` knobs and is optional.

Response — per-result RRF contribution breakdown (sources match recall.ex rank
list tags):
```json
{ "results": [ { "memory": { "id": "…", "summary": "…", "content_type": "…",
                             "salience": 0.8 },
                 "score": 0.0312,
                 "contributions": [
                   { "source": "weaviate:content", "rank": 1, "score": 0.0164 },
                   { "source": "emotional:vad",    "rank": 7, "score": 0.0075 },
                   { "source": "graph:cte",        "rank": 3, "score": 0.0073 } ] } ],
  "duration_ms": 142 }
```

## PATCH /api/v1/memory/agents/:agent_id/edges/:edge_id

Editor+. Body: `{ "weight": 0.65, "reason": "user adjustment" }` — clamped
[0.0, 1.0]. Audited: sets `created_by`-style provenance
(`"user:<user_id>"`) and `reason` on the edge row; the change flows to the AGE
projection via GraphMirror (including removal when < 0.2). Response: updated
edge JSON (shape as in /graph), wrapped as `{ "edge": { … } }` per the API's
single-entity convention.

## PATCH /api/v1/memory/agents/:agent_id/memories/:memory_id

Editor+. Body accepts any of `{ "decay_weight": 0.8, "pinned": true }` —
decay_weight clamped [0.05, 1.0] (ADR-005). Also
`POST …/memories/:memory_id/reinforce` and `…/denforce` for standard-step
Hebbian nudges (reuse `Reinforcement.reinforce/denforce`). Response: updated
memory JSON (node shape as in /graph), wrapped as `{ "memory": { … } }` per
the API's single-entity convention.

## MCP tools (server `tobor_memory`)

Existing: remember, recall, recall_by_emotion, reinforce, denforce,
memory_associations. Additions — each delegates to the same context functions
as the HTTP endpoints above (one shared internal API):

| tool | purpose |
|---|---|
| `memory_archive` / `memory_restore` | expose existing `Memory.archive/restore` |
| `graph_subgraph` | same semantics as GET /graph |
| `edge_set_weight` | same semantics as PATCH /edges/:id |
| `memory_set` | decay_weight/pinned, as PATCH /memories/:id |
| `recall_preview` | same semantics as POST /recall/preview |
| `agent_mood_get` / `agent_mood_set` | read/write memory_agent_state current_emotional (Monitor stub aware) |
| `compartments_list` | list memory_compartments for the agent |

MCP auth: optional Guardian gating of the `/mcp` mount behind
`MCP_AUTH_REQUIRED` (default false to preserve Phase-0 dev-open behavior).

## Frontend

- Graph view: `app/app/agents/[agentId]/memory` — cytoscape.js (client-only,
  dynamic import), nodes colored by `content_type`, sized by `salience`,
  edge color by `type`, width by `weight`; `min_weight` threshold slider,
  compartment filter, list/graph toggle; node click → detail panel with
  reinforce/denforce/pin; edge click → weight slider (PATCH).
- Recall playground: `app/app/agents/[agentId]/memory/playground` — query box +
  mood sliders (VAD + 4 hormones) → preview results with per-contribution
  score bars.
- All calls added as methods on the `api` object in `frontend/src/lib/api.ts`;
  styling via generated design-system semantic classes.

## Backend implementation notes (Phase D backend)

The request/response shapes above are implemented exactly. These clarify decisions the
contract left open and note where implementation had to deviate:

- **Role gating.** "editor+ for mutations" is realized as the **global admin flag**
  (`RequireAdmin`), not `RequireRole`. `RequireRole` is org-scoped (it needs an `org_id` path
  param and checks org membership), but these memory routes are per-agent and org-less, so it
  cannot apply. Reads + preview run under `:authenticated` (any authenticated user = viewer);
  edge/memory mutations run under `:authenticated` + `:admin`. Refining "editor" to a non-admin
  role needs a global (non-org) role concept, which does not exist yet.
- **Shared internal API.** Both HTTP (`TheRobotRemembersWeb.MemoryController`) and every MCP
  tool delegate to `TheRobotRemembers.Memory.Console`, so the two surfaces stay identical.
- **Tenant safety.** `/graph` returns only nodes owned by `:agent_id` (states `active` /
  `consolidating` — recall-visible), and only edges whose **both** endpoints are in that node
  set. Association edges can cross owners (a no-owner recall's Hebbian `co_occurrence` edges),
  so an owner filter on one endpoint is not enough. Edge PATCH rejects (`403`) any edge whose
  source or target is not owned by `:agent_id`.
- **`recall_log`.** Preview writes a row with `mode: "preview"` (kept, not skipped) so the
  history feed stays useful. Preview never enqueues reinforcement.
- **Preview `overrides`.** `rrf_k` and `vector_weights` are honored; other `Recall.config` knobs
  are accepted but currently no-op. `overrides`, `mood`, and `query` may be string- or atom-keyed.
- **Preview `results[].memory`.** Returned as the full node shape (same as `/graph` nodes), a
  superset of the abbreviated example above.
- **Non-null serializer fields.** To match the frontend `MemoryNode`/`MemoryAgent` types, a node's
  `summary` is coerced to `""` when unset (the frontend supplies its own label fallbacks, so it is
  not backfilled from `content`), and an agent's `current_bucket` defaults to `"neutral"` until the
  Monitor persists real state. `occurred_at` / `last_reinforced_at` remain nullable per the types.
- **Verified against `frontend/src/lib/api.ts`.** Every response field name/shape and all request
  params, paths, and bodies cross-checked against the merged frontend interfaces. Single-entity
  mutations return the pinned `{ edge }` / `{ memory }` wrapping.
- **MCP `recall_preview` / `agent_mood_set`** take flat scalar mood fields
  (`valence`…`serotonin`) rather than a nested `mood` object, matching the existing tool DSL.
- **MCP auth agent binding.** When `MCP_AUTH_REQUIRED=true`, the `/mcp` mount requires a valid
  Guardian JWT (`TheRobotRemembersWeb.Plugs.MCPAuth`). The effective agent is bound to an
  explicit `agent` **claim** if the token carries one (a self-asserted `agent` that disagrees is
  rejected). A standard user JWT's subject is a user-session ref, not an agent identity, and
  there is no user↔agent mapping in the schema — so without an `agent` claim the authenticated
  caller's self-asserted `agent` is trusted. Binding users to agents is a follow-up. Dev-open
  (default) behavior is unchanged.
