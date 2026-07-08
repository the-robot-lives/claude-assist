# Noizu Intellect — Consolidation of Past Attempts

> Consolidation of 10 prior iterations of the multi-agent LLM harness under `past-attempts/swarms/`.
> Each was a false start; together they describe one coherent system. This document is the synthesis —
> the forward-looking reference for building `noizu-intellect` fresh.
>
> Surveyed 2026-07-08.

---

## 1. TL;DR

Every substantive attempt independently specified the **same core vision** — multiple AI agents collaborating over channels, **running alternative solution paths in parallel**, and selecting the best outcome (with the human's pick feeding back into how future plans are decomposed). **None of them implemented the parallel-path execution layer.** That is the single unifying gap, and it is the thing `noizu-intellect` must actually build.

The attempts are complementary fragments of one system:

| Attempt | What it actually delivered |
|---|---|
| **intellect.legacy** | The most *built*: 57 DB tables, a fully-coded agent loop, audience-confidence routing, 3-pass (Plan→Reply→Reflect) prompting. Parallel-path = aspirational doc only. |
| **noizu-teams** | The most *OTP-mature*: per-agent GenServer under a per-project DynamicSupervisor, hybrid DB+PubSub+direct-call message passing, reflection-patch self-memory. Parallel-path = README prose only. |
| **noizu-ai** | The most *designed*: the parallel-path model specified in fullest detail (tag/checkout forking, generate-then-rank, human-in-the-loop reward backprop). All `:nyi` stubs. |
| **noizu-labs-ai** | The richest *ontology*: a grade-and-pick lifecycle, `nested_path` materialized path, versioned-content entities, and the three hard problems explicitly flagged. Scaffolding only. |
| **intellect.copy** | The richest *DDL*: complete org/channel/agent/feed/message schema, versioned primitives, `service_type_enum` with `:intuition_pump`. Scaffolding only. |
| **virtual_teams** | Stalled at "identity platform." Contributes an enums wishlist + syn-scoped LiveView pubsub. |
| **noizu-collab** | Bare scaffold. Contributes the `CORE.*` per-agent prompt taxonomy + a batch tool-call envelope. |
| **intellect / noizu_intellect / the-robot-lives** | Pure `phx.new` stubs. Contribute only a curated dependency bill of materials. |

**Recommendation:** Do not start from `mix phx.new`. Start from the agent/message layer (the lesson of every scaffold that stalled). Build on **noizu-teams' supervision topology** + **intellect.legacy's schema/routing** + **noizu-ai's parallel-path model** + **noizu-labs-ai's lifecycle**, and solve the three flagged hard problems up front (§9).

---

## 2. The Attempts at a Glance

| Repo | App | `.ex` | Substance | Parallel-path code |
|---|---|---:|---|---|
| intellect.legacy | `:noizu_intellect` | 123 | Full coded loop + 57 tables | None (doc only) |
| noizu-teams | `:noizu_teams` | 61 | Per-agent GenServers + cognition tables | None (README only) |
| noizu-ai | `:nai` | 2 | 1339-line design README | None (stubs) |
| noizu-labs-ai | `:intellect` | 122 | Scaffolding + TODO.md ontology | None (TODO only) |
| intellect.copy | `:intellect` | 83 | Scaffolding + full DDL | None |
| virtual_teams | `:virtual_teams` | 114 | Identity platform only | None |
| noizu-collab | `:noizu_collab` | 14 | Scaffold + prompt-history design | None |
| intellect | `:intellect` | 15 | phx.new stub | None |
| noizu_intellect | `:noizu_intellect` | 15 | phx.new stub | None |
| the-robot-lives | `:intellect` | 16 | phx.new stub | None |

Tech stack converged across the serious attempts:
`genai` (LLM provider abstraction, often the `3_model_manager` branch) · `noizu_labs_entities` + `noizu_labs_services` (entity persistence + supervision) · `noizu_labs_open_ai` (OpenAI client) · `oban` (queues) · `redix` (cache) · `pgvector` + `noizu_weaviate` (vectors) · `mnesia_rocksdb` + `amnesia` (hot cache) · TimescaleDB/Postgres (durable) · `bandit` + Phoenix LiveView (UI) · `dns_cluster` (distribution) · `semaphore` (concurrency limiting).

---

## 3. The Recurring Vision: Parallel-Path Multi-Agent Execution

This is the conceptual centerpiece and the thing every attempt failed to ship. It surfaces in three convergent articulations.

### 3.1 The `noizu-ai` model (fullest)

From the 1339-line README (the canonical statement of the idea). Two layers:

**Layer A — Fan-out a single prompt, then rank.** Run one thread against N candidate models in parallel, keep the top-K responses, feed them to a downstream "best-response" picker model:

```elixir
responses = NAI.ChatResponse.bizbop_body(chat, pick: 3)   # run N fast models, keep top 3
chat3 = NAI.Chat.checkout(chat, :base)
  |> NAI.Chat.message(pick_best_response_prompt(responses))
  |> NAI.Chat.with_model(UserCustomModel.best_response_nn)
```

**Layer B — Alternative-path planning with reward feedback (the headline).** A user request fans out into K independent *plans*; each plan runs as an agent↔agent message loop taking the locally-optimal step at each chunk; plans run **in parallel**; the top outcomes surface to a human operator; the pick is a **reward signal** that increases the weight of every decision factor along the winning path:

```
                                                     / Plan 1  ......... Outcome 1
User -> Request  AgentA |  Plan 2 ...
                         \ Plan 3 -> AgentB -> |  Plan 2 ...
                                                \ Plan 3 -> ...      Outcome N

Pick best 5 outcomes. User picked outcome 3 ->
  increase weight of decision factors behind all intermediate plan steps leading to outcome 3.
```

The novelty: **RLHF-style credit assignment applied to the plan-step decomposition**, not to the prose. The "policy" being refined is the meta-planner that decides how to decompose a request into steps and agent assignments.

Key primitives the README defines for this:
- **`tag(:name)`** — snapshot/commit the current thread state at a checkpoint.
- **`checkout(:name)`** — return an independent **fork** of the thread at that tag (git-style branching for LLM threads).
- **Inter-agent handoff** = extract a thread's body at a tag (`NAI.ChatResponse.body(checkout(thread, :tag))`) and append it as a new message into another agent's fork. No mailbox; value-passing at tags.
- **Deferred/lambda messages** — `message(&NAI.ChatResponse.body/2, as: :assistant)` makes a message block synchronously await another thread's tagged completion before appending (cheap futures inside a declarative pipeline).
- **Per-branch dynamic model selection** — `with_model(NAI.Model.fastest(for: Task))`, with constraint honoring (`set_stream(required: true)`).

**Crucial reconciliation semantics:** competing plans do *not* message each other mid-flight. They race independently. Inter-agent messaging happens *within* a plan (AgentA↔AgentB turn-taking to advance that one plan). Reconciliation is **post-hoc**: human-in-the-loop top-K selection + weight backprop along the chosen path. (User stories SET-028/029/030 formalize this.)

### 3.2 The `noizu-labs-ai` lifecycle

The most concrete *process* articulation, from TODO.md:

```
Route  ->  Plan  ->  [ProceedAndPlanFurther  in PARALLEL  down multiple approved paths]
       ->  ReviewProgress / PlanComplete / ReviewCompletion / Summarize / ReviewSummary
       ->  GradeAndPickBestResponse   (Review Agent selects one approved response)
       ->  discard memories from non-approved paths
```

This names the *stages* as agent roles and is the natural runtime pipeline for Layer B above.

### 3.3 The `intellect.legacy` aspiration

References "Tree of Thought" and "intuition pumps"; ships a 43KB `tree-of-thought-conversation.md` epic (Epic 5.2 "Enhanced Parallel Processing for Initial Processing Stages") and an empty `intuition_pump` DB table. Never coded. The `message_nesting` / `message_relates_to` tables and `depth` column are the relational skeleton a tree would hang off of.

### 3.4 Synthesis — what the parallel-path layer must be

Converging the three: **a request is decomposed by a Planner into N independent *paths*. Each path is an ordered sequence of agent turns (a sub-conversation) executed concurrently. Each path maintains its own short-term memory. A Reviewer grades completed paths; a Picker (or a human) selects the winner(s). The winner's decision-path is recorded as a positive example for the meta-planner; losing paths' memories are discarded (or down-weighted).** Paths fork from a shared base context (the `tag`/`checkout` primitive); they do not exchange messages with sibling paths mid-execution.

---

## 4. Architecture & Supervision

### 4.1 The converged topology (take from noizu-teams + intellect.legacy)

```
Application (one_for_one)
├── Repo (Ecto/Postgres+Timescale)
├── Redis pool (Redix, :persistent_term cached channels)
├── Phoenix.PubSub  ×2  (app bus + LiveView/UI bus — keep them separate)
├── Finch (HTTP to LLM providers)
├── Oban (queues: ingestion, path-execution, memory)
├── Services.Supervisor
│   └── ProjectManager  (DynamicSupervisor)
│       └── per Project.Supervisor  (one per org/project)
│           └── per Agent GenServer  (:"Agent_<uuid>")     ← the agent runtime
└── Endpoint
```

- **One long-lived GenServer per agent**, keyed by agent UUID, supervised under a per-project supervisor under a `DynamicSupervisor`. This is noizu-teams' shape and it is the right one. (intellect.legacy uses the Noizu.Service worker framework to the same end.)
- **Separate the app PubSub from the LiveView PubSub** (noizu-teams' `PubSub` vs `LiveView.Interop` split). Agent dispatch should not be coupled to UI streaming.
- intellect.legacy's `bring_online/1` wakes all agents on boot — useful for a persistent-agent workspace.

### 4.2 The agent turn (take from intellect.legacy)

A **3-pass LLM pipeline per agent turn**, each pass a separate completion call:
1. **Plan** — decide what to do / whether to reply / whom to address.
2. **Reply** — produce the response.
3. **Reflect** — emit a structured patch (memory/agenda/mood/mind updates) written back to the agent's cognition tables.

The model output is parsed (YAML or tagged blocks) into action tuples: `{:reply, ...}`, `{:ack, ...}`, `{:objective, ...}`, `{:follow_up, ...}`, `{:memories, ...}`.

(noizu-teams does a two-call variant: primary completion → temp-0.1 reflection call emitting a YAML `patch:` block. intellect.legacy's three-pass is the superset.)

### 4.3 Agent context assembly (take from noizu-teams + intellect.legacy)

Per-turn system prompt assembles: team roster + short-term memory + long-term memory + observations + opinions + mind-reading + mood + active objectives, YAML-encoded. intellect.legacy adds tiered summarization by age (`message_token_size` heuristic = chars/3) and a `recent_graph` recursive query reconstructing threaded context.

---

## 5. Message Passing

Three distinct models appeared. **They are not mutually exclusive — the consolidated system wants all three at different scales.**

### 5.1 Model 1 — Shared persistent inbox per channel (intellect.legacy)

Agents do **not** cast to each other. Every message is a DB row in a channel's inbox. Each (agent, channel) has a heartbeat-driven ingestion worker that polls for unread messages, pulls relevant/recent history, and runs its turn.

- **Audience-confidence routing**: instead of explicit recipients, every message gets a `message_audience` row per channel member with a 0–100 confidence score (`@slug` → 100, `@everyone`/`@channel` → 70, otherwise lower). Agents process messages where `confidence >= 50`.
- Decoupled, durable, naturally resumable. Best for the **channel/chat** layer.

### 5.2 Model 2 — Hybrid DB + PubSub + direct GenServer call (noizu-teams)

`Channel.send/4` is the hub: insert the message row → `LiveMessage.publish(...)` (wildcard PubSub: `subject:instance:event` with `*` fan-out keys) → **direct GenServer `call`** to each routed agent recipient. `@slug` mentions are parsed via regex; `@everyone` fans to all members; `:direct` channel type suppresses fan-out for private agent↔agent side-channels. Agent replies stream back via `:stream`/`:stream_end` PubSub events.

- Synchronous, low-latency, good for **live inter-agent coordination within a single path**.

### 5.3 Model 3 — In-thread accumulation + tag/checkout value-passing (noizu-ai)

No mailbox. An LLM thread is an append-only instruction tree. `tag(:x)` commits a checkpoint; `checkout(:x)` forks it. Inter-agent handoff = extract a thread's body at a tag and append it as a new message into another agent's fork. Deferred lambda messages block on another thread's tagged completion.

- This is the **parallel-path primitive** itself — the mechanism by which alternative continuations of a conversation are expressed and run concurrently (§3, §7).

### 5.4 Recommendation

Use **Model 1 (inbox + audience-confidence)** for durable channel messaging, **Model 2 (PubSub + direct call)** for live UI streaming and intra-path coordination, and **Model 3 (tag/checkout forking)** as the substrate for parallel-path execution. They map cleanly onto distinct concerns.

---

## 6. Agent & Team Model

### 6.1 Agent as entity + process

- **Entity/record**: `Agent` with `handle/slug`, `name`, `description`, `profile_prompt`, `profile_image`, `model`, `mood`, `purpose`, `self_image`. Persisted (Postgres + Redis cache; optional Weaviate vector for memory).
- **Process**: a GenServer holding `{agent, chat_log, chat_summary, memories}` (noizu-teams runtime state).
- **Membership**: a polymorphic `member` join (`member_type` ∈ `{:user, :agent}`) on a Project/Org, with a `role`. A "team" is the roster of members of a project — **no dedicated `Team` table** (noizu-teams tried and abandoned one; the project *is* the team). virtual_teams' `organization_role_enum [:admin, :user]` and `channel_type_enum [:external, :internal, :direct, :group]` are worth carrying.

### 6.2 Agent cognition (the `CORE.*` taxonomy, made concrete)

noizu-collab's prompt taxonomy and noizu-teams' 5 cognition tables are the same idea:

| Cognition facet | noizu-teams table | CORE.* prompt | Purpose |
|---|---|---|---|
| Memory | `project_agent_memories` | `.context` (short/long-term) | Facts the agent retains |
| Observation | `project_agent_observations` | `.observation` | Failure-tracking reinforcement |
| Opinion | `project_agent_opinions` | `.opinion` | Sentiment toward others |
| Mind-reading | `project_agent_mind_readings` | `.mind-reading` | Beliefs about others' state |
| (identity) | — | `.purpose` / `.identity` / `.specification` / `.self-image` | Who the agent is |

The reflection pass (§4.2) writes patches back into these tables after each turn. intellect.legacy adds **objectives** (`account_agent_objective` + participants/parents/context) and **reminders** (`account_agent_reminder`) emitted via `{:objective, ...}` / `{:follow_up, ...}` tuples.

---

## 7. Schema (Consolidated Entity Model)

Drawing the union, with attribution. All UUID PKs; polymorphic actor refs (`author_ref` + `author_ref_type`) so users and agents share threads.

**Core workspace**
- `organization` / `account` / `project` — the workspace.
- `organization_member` / `account_member` — polymorphic membership (`member_ref`, `member_ref_type`, `role`).
- `organization_agent` / `account_agent` — agent defs (handle, model, name/description/bio/instructions/profile_prompt/profile_image, mood, purpose, self_image, settings).
- `organization_user` / `account_member` (human) — parallel to agents.

**Channels & messaging**
- `channel` (`type` ∈ external/internal/direct/group/session; slug, organization, name, image).
- `channel_member` — membership.
- `channel_message` / `message` — `author_ref`+`author_ref_type`, `channel`, `contents` (→ versioned string), `event`, `status`, `mood`, `depth`, `brief`, `meta`, `token_size`, `weaviate_object`, `responding_to`, `read_on`.
- `message_audience` — per-recipient confidence score (intellect.legacy). *Soft routing.*
- `message_responding_to` — reply edges with confidence.
- `message_read` — read receipts.
- `message_nesting` / `message_relates_to` — tree ancestry / related-message graph (intellect.legacy). *The skeleton a parallel-path tree hangs off of.*
- `nested_path` materialized path column on messages (noizu-labs-ai) — *alternative encoding for tree membership; pick one.*
- `channel_message_versions`, `channel_shares`, `channel_events`, `channel_notifications`, `channel_pins`, `channel_spaces` (intellect.copy) — full feed model.

**Agent cognition & objectives**
- `agent_memory` (`subject`, `topic`, `memory`).
- `agent_observation`, `agent_opinion`, `agent_mind_reading`.
- `agent_objective` (+ `_participant`, `_parent`, `_context`), `agent_reminder`.
- `intuition_pump` — *placeholder for the parallel-path/tree-of-thought heuristics; currently empty everywhere. This is where the new system's path-execution records live.*

**Versioned content (content-addressed primitives — intellect.legacy, noizu-labs-ai, intellect.copy)**
- `versioned_string`, `versioned_name`, `versioned_description`, `versioned_uri` (+ `_history`). Every mutable text field (prompts, bios, message contents) is an FK to an immutable versioned row. Diff-able, auditable. **Carry this verbatim.**

**Services & tools**
- `service`, `function`, `agent_service`, `agent_function`, `message_service`, `message_function` (intellect.legacy — stubbed). `service_type_enum [:service, :tool, :intuition_pump, :other]` (intellect.copy/virtual_teams). *Agent-as-typed-service registry.*

**Memory / vector**
- Weaviate classes: `Message` (`content, action, sender, features, audience, responding_to`) and `Memory` (`identifier, content, created_on, features, agent, messages`) (intellect.legacy). pgvector columns for local embeddings. intellect.legacy's `synthetic-memory.md` is a prompt template that distills a conversation into Weaviate memory records.

**Identity infra**
- `user`, `user_credential` (password + oauth), `user_session`, `user_device`, `auth_provider`, `terms_of_service`. (Standard; lift from any attempt.)

---

## 8. Reusable Nuggets Catalog

Ranked by value to the fresh attempt:

1. **Per-agent GenServer under a per-project DynamicSupervisor** (noizu-teams) — the OTP topology.
2. **`tag`/`checkout` forking primitive** (noizu-ai) — git-style branching for LLM threads; the mechanism for parallel alternative continuations.
3. **Generate-then-rank fan-out + judge model** (noizu-ai `bizbop_body(chat, pick: N)` → `best_response_nn`) — concrete two-stage API.
4. **Grade-and-pick lifecycle** (noizu-labs-ai: Route→Plan→parallel ProceedAndPlanFurther→Review→GradeAndPickBestResponse→discard) — the runtime pipeline.
5. **Audience-confidence routing** (intellect.legacy: 0–100 per recipient, `@slug`→100, `@everyone`→70, threshold 50) — soft message routing.
6. **3-pass prompt decomposition** Plan/Reply/Reflect (intellect.legacy) — separating planning, response, reflection into distinct calls.
7. **Reflection-patch YAML protocol → cognition tables** (noizu-teams) — lightweight self-memory loop; the same model emits a structured `patch:` block parsed back into per-agent state.
8. **Versioned-content entities** (noizu-labs-ai/intellect.copy) — content-addressed, immutable, diff-able prompts/bios/messages.
9. **`CORE.*` per-agent prompt taxonomy** (noizu-collab) — purpose/identity/specification/self-image/observation/opinion/mind-reading/context.
10. **Full org/channel/agent/feed DDL** (intellect.copy `20241113030009_create_organizations.exs`) — complete relational sketch ready to lift.
11. **Weaviate Message/Memory class schemas** (intellect.legacy) — minimal viable vector schema.
12. **Hybrid Amnesia(RocksDB)+Ecto persistence** (noizu-labs-ai) — hot cache + durable via Noizu `@persistence` macros.
13. **Polymorphic actor refs** (`author_ref`+`author_ref_type`) (noizu-labs-ai/intellect.legacy) — users and agents share channels without a table per role.
14. **Message-graph query patterns** (intellect.legacy `recent_graph` recursive CTE with `array_agg`) — threaded-context reconstruction.
15. **`LiveMessage` syn-scoped wildcard pub/sub** (noizu-teams/virtual_teams) — `{subject, instance}` routing with `*` fan-out.
16. **Deferred/lambda messages** (noizu-ai) — cheap futures inside a declarative pipeline.
17. **`master` batch-request envelope** (noizu-collab) — `{requests: [{subsystem: {request: params}}]}` tool-call batching format.
18. **Dependency bill of materials** (intellect stub) — genai + Noizu entities/services + Mnesia/RocksDB + pgvector + Oban + Redis + TimescaleDB + Weaviate.

---

## 9. The Hard Problems (solve these up front)

noizu-labs-ai's TODO.md explicitly flagged these as unresolved — every attempt stalled before answering them. They are the real architectural work.

1. **Memory isolation & merging across competing paths.** When N parallel paths run against one request, each builds short-term memory. Only the winner's memory should persist (noizu-labs-ai discards non-approved-path memories). *Decide: per-path memory sandbox; winner-takes-all write-back; or partial merge. The reward-backprop model (noizu-ai) additionally needs to record the winning decision-path as a positive example.*
2. **Encoding the execution tree in Postgres.** `nested_path` materialized path (noizu-labs-ai) vs `message_nesting`/`message_relates_to` edge tables (intellect.legacy) vs a `depth`+`responding_to` self-reference (intellect.legacy). *Pick one and make path membership, ancestry, and sibling queries efficient.*
3. **Synchronization & merging of parallel results.** Paths run concurrently; the Picker needs their outputs normalized and comparable. *Decide the Review/Grade contract: what each path emits, how outcomes are ranked, where the human sits in the loop, and how the decision-weight store is updated.*

A fourth, implicit: **the meta-planner itself.** noizu-ai's model refines *how requests are decomposed into plan steps and agent assignments*, not just the prose. The decision-weight store (§3.1) needs a schema and an update rule. None of the attempts specified it.

---

## 10. Recommended Starting Approach

1. **Do not `mix phx.new` first.** Every scaffold stalled. Start from the agent/message/runtime layer on `noizu_labs_services` + `genai`; add the web surface later.
2. **Stand up the supervision topology** (§4.1): per-agent GenServer under a per-project DynamicSupervisor, dual PubSub, Oban, Redis, Ecto.
3. **Lift the schema** from §7: versioned-content primitives + organization/agent/member/channel/message + audience-confidence + cognition tables + a real `intuition_pump`/path-execution table (not empty).
4. **Build the agent turn** as the 3-pass Plan/Reply/Reflect pipeline (§4.2) with reflection-patch write-back to cognition tables.
5. **Implement the parallel-path layer — the thing nobody shipped:** the Planner (decompose → N paths), the path executor (concurrent agent-turn sequences forking from a shared `tag`/`checkout` base), the Reviewer/Picker (grade + human top-K selection), and the decision-weight store (reward backprop along the winning path).
6. **Solve §9 before wiring #5 end-to-end** — the memory-isolation, tree-encoding, and merge rules are load-bearing and were every attempt's failure point.

---

## Appendix: Source Map

| § drew from | Primary repos |
|---|---|
| Parallel-path vision (3) | noizu-ai (Layer A+B, tag/checkout), noizu-labs-ai (lifecycle), intellect.legacy (ToT aspiration) |
| Supervision (4) | noizu-teams (per-agent GenServer/DynamicSupervisor, dual PubSub), intellect.legacy (3-pass, bring_online) |
| Message passing (5) | intellect.legacy (inbox + audience-confidence), noizu-teams (PubSub + direct call), noizu-ai (tag/checkout value-passing) |
| Agent/team/cognition (6) | noizu-teams (cognition tables, reflection patch), noizu-collab (CORE.* taxonomy), intellect.legacy (objectives/reminders) |
| Schema (7) | intellect.legacy (57 tables, audience, nesting, versioned), intellect.copy (full feed DDL), noizu-labs-ai (nested_path, versioned), virtual_teams (enums) |
| Nuggets (8) | all |
| Hard problems (9) | noizu-labs-ai (TODO.md), noizu-ai (decision-weight store) |

Full per-repo digests available in the subagent extraction transcripts under this session.
