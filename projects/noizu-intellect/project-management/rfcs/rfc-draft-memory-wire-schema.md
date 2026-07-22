# Q9 — Memory Schema Diff: therobotremembers (trr) vs npl-mcp memory domain

Sources: trr `schema/memory/{memory,association_edge,agent_state,compartment,recall_log,quarantine}.ex`
+ `memory/{store,recall,reinforcement,emotion}.ex` + `mcp.ex`/`mcp/tools/*`; npl-mcp
`domains/memory/{memory.ex,store.ex,weaver.ex,emotion.ex,recall.ex,tools/*}` + `schema/memory/*.ex`
(incl. `agent_call_sign.ex`, npl-mcp-only); `priv/conventions/pumps.yaml` synthetic-hormones section.

## 1. Field-by-field diff

### Entity: Memory (table `memories`)

| Field | trr | npl-mcp | Verdict |
|---|---|---|---|
| id | Ecto.UUID pk | same | identical |
| ownership | `owner_agent :string` (flat, default "anonymous" via context) | `organization_id` + `scope_type` enum(persona\|weego\|team_member) + `scope_id` (polymorphic UUID) | **semantic-drift** — trr: flat string identity; npl-mcp: structured multi-tenant scope |
| organization_id | present, optional | present, **required** | renamed-requiredness |
| project_id | present, optional | present, optional | identical |
| source_agent | `:string, default "external"` | same | identical |
| content/context/reflection/tangent/summary | all `:string` | same | identical |
| content_type | enum episodic\|semantic\|procedural, default episodic | same | identical |
| emotional_embedding | **`Pgvector.Ecto.Vector` column on the row** — pgvector ANN lives in Postgres (hot path, no external deps) | **absent from the row** — moduledoc: "all FIVE vectors... live in Weaviate"; the 7-d vector is a Weaviate named vector, not a Postgres column | **only-in-one / architecture-drift** (see note below) |
| valence/arousal/dominance | float, raw components kept for explainability | same | identical |
| cortisol/dopamine/oxytocin/serotonin | float | same | identical |
| frustration_index | float, default 0.0 | same | identical |
| confidence | string, default "low", validated ∈ {high,medium,low} | same | identical |
| occurred_at/time_of_day/day_of_week/season | same | same | identical |
| domain/topic/session_id/turn/modality | same | same | identical |
| collaborators | `{:array, :string}` | same | identical |
| environment | `:map` | same | identical |
| state | enum active\|consolidating\|archived\|quarantined\|pruned | same | identical |
| decay_weight/pinned/last_recalled_at/last_reinforced_at | same | same | identical |
| recall_count/reinforcement_count/denforcement_count | same | same | identical |
| consolidation_ids/pruned_at | same | same | identical |
| compartment/classification | same | same | identical |
| salience | read-only generated column | same | identical |
| embedding_model/embedding_version/vectors_synced | same | same | identical |
| required-on-insert | `owner_agent, content, emotional_embedding, valence, arousal, dominance, cortisol, dopamine, oxytocin, serotonin` | `organization_id, scope_type, scope_id, content, valence, arousal, dominance, cortisol, dopamine, oxytocin, serotonin` (no `emotional_embedding` — it's not a column) | drift follows from the embedding-location split above |

**Architecture note (important for Q9):** trr keeps the emotional vector *in Postgres* (pgvector column) specifically so `by_emotion` works "with no external services" (see trr `Recall` moduledoc). npl-mcp moved it entirely into Weaviate as a fifth named vector, dropping the pgvector dependency from the row. This is not a cosmetic rename — it changes the recall hot path's dependency graph. Any shared wire schema must treat `emotional_embedding` as *derived/optional* (computable from `mood`+`hormones` via `Emotion.build_vector/2`, which is otherwise byte-for-byte identical in both codebases) rather than a required stored field.

### Entity: AssociationEdge (table `association_edges`)

| Field | trr | npl-mcp | Verdict |
|---|---|---|---|
| all fields (source_memory_id, target_memory_id, weight, edge_type enum[8 values], created_by, reinforcement_count, denforcement_count, reason, emotional_similarity, temporal_proximity, last_reinforced_at, timestamps) | — | — | **identical**, including the `edge_type` enum value list and the `uq_edge` unique constraint. Byte-for-byte matching changeset/validation logic. |

Edge-creation locus differs: npl-mcp has an explicit `Weaver` module (5 dimensions: emotional/temporal/contextual/tangent/semantic, all scope-filtered). No equivalent `weaver.ex` was found in trr's `memory/` directory in this pass (candidates: `graph_store.ex`/an embedding worker) — flagged as an open question rather than asserted absent.

### Entity: AgentState (table `memory_agent_state`)

| Field | trr | npl-mcp | Verdict |
|---|---|---|---|
| primary key | `agent_id :string` (single natural key) | composite `{organization_id, scope_type, scope_id}` (`@primary_key false`) | **semantic-drift**, mirrors the Memory ownership split |
| current_emotional / baseline_emotional | `Pgvector.Ecto.Vector` | `{:array, :float}` — moduledoc explicitly: "no pgvector" | **semantic-drift** — same field, different storage representation (native vector type vs plain float array) |
| status/current_bucket/last_bucket_refresh/metrics | identical | identical | identical |

### Entity: Compartment (table `memory_compartments`)

| Field | trr | npl-mcp | Verdict |
|---|---|---|---|
| owner | `owner_agent :string` | `organization_id + scope_type + scope_id` | semantic-drift (ownership split, as above) |
| slug/classification/settings | identical | identical | identical |
| unique constraint | `[owner_agent, slug]` | `[organization_id, scope_type, scope_id, slug]` | follows from ownership split |

### Entity: RecallLog

| Field | trr | npl-mcp | Verdict |
|---|---|---|---|
| **table name** | `recall_log` | `memory_recall_log` | **renamed** (table itself, not just fields) |
| owner | `owner_agent :string` | `organization_id + scope_type + scope_id` | semantic-drift |
| requester_id/mode/query/total_candidates/returned_count/hot_index_hit/duration_ms/result_memory_ids/path_breakdown/occurred_at | identical | identical | identical |

### Entity: Quarantine (table `memory_quarantine`)

| Field | trr | npl-mcp | Verdict |
|---|---|---|---|
| owner | `owner_agent :string` | `organization_id + scope_type + scope_id` | semantic-drift |
| memory_id/reason/payload/resolved | identical | identical | identical |

### Entity: AgentCallSign — **only-in-npl-mcp**

No trr counterpart. Registry table (`agent_call_signs`) giving weego/team_member scopes a stable, org-unique `call_sign` + `id` (used as `scope_id`). trr has no registry — it resolves `owner_agent` directly from an `agent` string via `MCP.Auth.resolve_agent/2`, no backing table read in the path shown. This is the clearest structural expansion unique to npl-mcp's multi-tenant model.

### MCP tool surface (trr `mcp.ex` vs npl-mcp `domains/memory/mcp.ex`)

| Tool | trr | npl-mcp | Verdict |
|---|---|---|---|
| Remember, Recall, RecallByEmotion, Reinforce, Denforce, MemoryAssociations | present in both | present in both | identical intent; **npl-mcp's input schema adds `organization`(required) + `scope_type`(required) + optional `agent`**, resolved via `Tools.Scope.resolve/1` → context map. trr's input adds only optional `agent`, resolved via `MCP.Auth.resolve_agent/2` → `owner_agent` string. |
| MemoryArchive, MemoryRestore, GraphSubgraph, EdgeSetWeight, MemorySet, RecallPreview, AgentMoodGet, AgentMoodSet, CompartmentsList, GraphExplainPath | **present** (Phase D console + ADR-006 graph seam) | **absent** | only-in-trr — npl-mcp's tool surface is a strict subset, lagging trr's ops/console/graph-explain surface |
| AgentRegister, AgentList | absent | **present** (`Tools.AgentRegister`/`Tools.AgentList`, category "Memory.Agents") | only-in-npl-mcp — the counterpart to the AgentCallSign registry above |
| Overview | absent | present | only-in-npl-mcp |
| `recall/3` `recent/2` variant | not found in trr's `Recall` (only `by_emotion/3`, `active/3`, `preview/3`) | present (`Recall.recent/2`) | only-in-npl-mcp |

## 2. Wire schema draft — shared `MemoryEntry` exchange format

```jsonc
{
  "$id": "https://noizu.dev/schemas/memory-entry.json",
  "title": "MemoryEntry",
  "type": "object",
  "required": ["id", "owner", "content", "mood", "state", "provenance"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },

    // Union of trr's flat owner_agent and npl-mcp's structured scope. Wire format carries
    // BOTH shapes; a receiving system picks whichever it natively models and treats the
    // other as opaque passthrough (round-trips without loss even across the ownership split).
    "owner": {
      "type": "object",
      "oneOf": [
        { "required": ["owner_agent"],
          "properties": { "owner_agent": { "type": "string" } } },
        { "required": ["organization_id", "scope_type", "scope_id"],
          "properties": {
            "organization_id": { "type": "string", "format": "uuid" },
            "scope_type": { "enum": ["persona", "weego", "team_member"] },
            "scope_id": { "type": "string", "format": "uuid" }
          } }
      ]
    },
    "project_id": { "type": ["string", "null"], "format": "uuid" },
    "source_agent": { "type": "string", "default": "external" },

    "content": { "type": "string" },
    "context": { "type": ["string", "null"] },
    "reflection": { "type": ["string", "null"] },
    "tangent": { "type": ["string", "null"] },
    "summary": { "type": ["string", "null"] },
    "content_type": { "enum": ["episodic", "semantic", "procedural"], "default": "episodic" },

    "mood": {
      "type": "object",
      "required": ["valence", "arousal", "dominance"],
      "properties": {
        "valence": { "type": "number", "minimum": -1.0, "maximum": 1.0 },
        "arousal": { "type": "number", "minimum": 0.0, "maximum": 1.0 },
        "dominance": { "type": "number", "minimum": 0.0, "maximum": 1.0 }
      }
    },
    "hormones": {
      "type": "object",
      "description": "NPL-4 projection (cortisol/dopamine/oxytocin/serotonin). See hormone appendix for the NPL-7 superset mapping.",
      "properties": {
        "cortisol": { "type": "number" },
        "dopamine": { "type": "number" },
        "oxytocin": { "type": "number" },
        "serotonin": { "type": "number" }
      }
    },
    "frustration_index": { "type": "number", "default": 0.0 },
    "confidence": { "enum": ["high", "medium", "low"], "default": "low" },

    // Derived, not stored: either system can recompute via Emotion.build_vector(mood, hormones)
    // (identical implementation in both codebases). Wire format allows a source to attach the
    // precomputed vector, but a receiver MUST NOT treat its absence as data loss.
    "emotional_embedding": {
      "type": ["array", "null"],
      "items": { "type": "number" },
      "minItems": 7, "maxItems": 7,
      "description": "Optional precomputed 7-d vector [valence,arousal,dominance,cortisol,dopamine,oxytocin,serotonin] (pre-weighted). trr stores this in Postgres (pgvector); npl-mcp stores it as a Weaviate named vector. Derivable from mood+hormones; not required on the wire."
    },

    "occurred_at": { "type": "string", "format": "date-time" },
    "time_of_day": { "type": ["string", "null"] },
    "day_of_week": { "type": ["integer", "null"] },
    "season": { "type": ["string", "null"] },
    "domain": { "type": ["string", "null"] },
    "topic": { "type": ["string", "null"] },
    "session_id": { "type": ["string", "null"], "format": "uuid" },
    "turn": { "type": ["integer", "null"] },
    "modality": { "type": ["string", "null"] },
    "collaborators": { "type": "array", "items": { "type": "string" }, "default": [] },
    "environment": { "type": "object", "default": {} },

    "state": { "enum": ["active", "consolidating", "archived", "quarantined", "pruned"] },
    "decay_weight": { "type": "number", "default": 1.0 },
    "pinned": { "type": "boolean", "default": false },
    "last_recalled_at": { "type": ["string", "null"], "format": "date-time" },
    "last_reinforced_at": { "type": ["string", "null"], "format": "date-time" },
    "recall_count": { "type": "integer", "default": 0 },
    "reinforcement_count": { "type": "integer", "default": 0 },
    "denforcement_count": { "type": "integer", "default": 0 },
    "consolidation_ids": { "type": "array", "items": { "type": "string", "format": "uuid" }, "default": [] },
    "pruned_at": { "type": ["string", "null"], "format": "date-time" },

    "compartment": { "type": "string", "default": "default" },
    "classification": { "enum": ["open", "restricted", "sealed"], "default": "open" },
    "salience": { "type": ["number", "null"], "readOnly": true },
    "embedding_model": { "type": ["string", "null"] },
    "embedding_version": { "type": "integer", "default": 1 },
    "vectors_synced": { "type": "boolean", "default": false },

    "provenance": {
      "type": "object",
      "required": ["source_system", "thread_span", "authenticity"],
      "properties": {
        "source_system": { "enum": ["therobotremembers", "npl-mcp"] },
        "thread_span": {
          "type": "string",
          "description": "Placeholder address into the originating conversation/session thread this memory was formed from (format TBD by the thread-span workstream — e.g. `session_uuid#turn_range`)."
        },
        "authenticity": { "enum": ["authentic", "edited", "idealized"],
          "description": "authentic = verbatim capture at time of occurrence; edited = human/agent revised post-hoc; idealized = synthetic/simulated (e.g. sim_loader/seeds fixtures)." }
      }
    }
  }
}
```

## 3. Hormone mapping appendix

NPL-7 synthetic hormones (`pumps.yaml` synthetic-hormones section) → therobotremembers/npl-mcp NPL-4 + VAD, as a **superset schema with per-source provenance**:

| NPL-7 hormone | Symbol | Biological analog (pumps.yaml) | Superset field | Memory-domain projection |
|---|---|---|---|---|
| Momentum | MTM | Dopamine | `hormones.momentum` | → `dopamine` (partial; see Curiosity) |
| Curiosity | CRS | Dopamine (novelty) | `hormones.curiosity` | → `dopamine` (partial; see Momentum) |
| Tension | TNS | Cortisol | `hormones.tension` | → `cortisol` (direct) |
| Confidence | CNF | Testosterone | `hormones.confidence` | **no memory-domain analog** — memory schema's `confidence` field (high/medium/low) is an unrelated concept (evidential confidence in a recalled memory's mood tagging, not a hormone). Do not conflate. |
| Affinity | AFN | Oxytocin | `hormones.affinity` | → `oxytocin` (direct) |
| Fatigue | FTG | Adenosine | `hormones.fatigue` | **no memory-domain analog** |
| Restlessness | RST | Norepinephrine | `hormones.restlessness` | **no memory-domain analog** |
| — | — | — | — | `serotonin` ← **no NPL-7 source; TBD/derived** |

Projection as specified for the wire-schema `hormones` block (NPL-4, both codebases identical):

```
dopamine  ← f(Momentum, Curiosity)     -- UNCERTAIN: pumps.yaml gives no combination function;
                                            both hormones map to dopamine 1:1 in the treatise text,
                                            memory-domain code takes a single scalar. Candidate:
                                            mean(Momentum, Curiosity) or max — needs an authoring decision.
cortisol  ← Tension                     -- direct, high confidence
oxytocin  ← Affinity                    -- direct, high confidence
serotonin ← TBD / derived               -- UNCERTAIN: no NPL-7 hormone models serotonin's biological
                                            role (mood stability/contentment) in pumps.yaml. The memory
                                            schema's `hormone_baseline` default (serotonin: 0.5) suggests
                                            it was added independently of the NPL-7 set, not derived from
                                            it. Needs either a new NPL-8th synthetic hormone or an explicit
                                            "no source, use baseline" wire annotation.
```

Confidence/Fatigue/Restlessness have **no representation** in the memory hormone quadruple at all — they're session/harness-behavioral signals (pumps.yaml's own domain: agent working-state modulation), not memory-formation emotional context. A superset wire schema should carry them as a separate optional `harness_state` block, not force them into `hormones`.

## 4. Recommendation (does the diff support Q9-A?)

The diff **supports Q9-A but with one load-bearing caveat**. Every entity except the emotional-vector storage location is either identical or differs only along the single, well-isolated ownership axis (`owner_agent` string vs `organization_id/scope_type/scope_id`) — a mechanical rename, not independent design. `Emotion`, `AssociationEdge`, and the tool contracts are near-verbatim forks of one lineage, and npl-mcp's tool surface is a strict subset of trr's (no graph-explain, archive/restore, mood-get/set, compartments-list, recall-preview) — consistent with trr being the more mature, canonical implementation and npl-mcp being the newer scope-aware proxy. The one real complication: npl-mcp deliberately dropped the Postgres pgvector column trr depends on for its no-external-deps `by_emotion` hot path, moving the emotional vector entirely into Weaviate — canonicalizing on trr's schema would need to either restore that column in npl-mcp or accept Weaviate as a hard dependency for emotional recall project-wide. That's a real architectural decision, not a wire-format nuance, and should be surfaced explicitly before Q9-A is finalized.
