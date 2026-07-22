---
title: Agent Runtime Contract
lane: WS-J (Agent Platform & Governance)
milestone: M0 (Baseline Audit & Platform Contracts)
status: draft — pending lane-lead sign-off
gates: US-076 (M1) · US-077/079/081/082 (M2) · US-078/080/083 (M3) · US-084/085 (M4)
grounded_against: app/backend commit on branch feat/ex-litellm; changelogs 001–034
---

# Agent Runtime Contract

The single interface boundary for how AI agents are declared, dispatched, permissioned,
audited, metered, and surfaced in **therobotplans** (tobornalp.com). WS-J owns
`domains/agents`; every other lane that invokes an agent, assigns work to one, or reads
its activity does so **only through the functions and channels named here** — never by
reaching into `domains/agents` tables.

This contract is implementation-ready: an engineer or agent worker can build **US-076**
(M1) from Section 1 + Section 4 + Section 8 + Section 9 without re-reading the story.
Later-milestone sections (2, 3, 5, 6, 7) specify the seams US-076 must leave open so the
M2–M4 stories slot in without reshaping M1 code.

---

## 0. Substrate reality — build-on vs build

Grounded in a full read of `app/backend/lib/therobotplans/` (recon 2026-07-22). This
decides *extend vs create* for every section below.

| Capability | State | Anchor |
|---|---|---|
| MCP multi-server plane | **build-on** (mature) | `Therobotplans.MCPServers`, `router.ex` host-scopes, `Noizu.MCP.Server` macro, `domains/<d>/tools/*` |
| Noizu.Entity dual-layer, UUID ids, `organization_id` scoping | **build-on** | `entities/**` (business) over `schema/**` (Ecto); `def_entity`/`def_repo` |
| PBAC authz | **build-on, with a hard gap** | `Therobotplans.Authz`, `Authz.PolicyEvaluator`, `schema/authz/scoped_membership.ex` |
| Oban | **build-on** | queues `mailer/default/cleanup`; workers in `lib/therobotplans/workers/` |
| PubSub + event bus | **build-on, must extend allowlist** | `Therobotplans.Events` (topic `"events"`, **fixed** `@type_list`), `Therobotplans.PubSub` |
| Inbox notifications | **build-on** | `Domains.Notifications.notify/1` + `Notifications.Dispatch` (`safe/1`-guarded fan-out) |
| Liquibase changelogs | **build-on, restructure** | flat `db/changelog/`, highest = `034-item-rank-dates-events.yaml`, **no `lanes/`** |
| Phoenix channels | **build-on, minimal** | `user_socket.ex` (`org:*`→`OrgChannel`, Guardian JWT), only channel is `org:<id>` |
| **Agent / persona / registry** | **BUILD — absent** | no `domains/agents`, no agent/persona entity anywhere |
| **GenAI/LLM provider wiring** | **BUILD — dep only, unwired** | `{:genai, "~> 0.3.0"}` in `mix.exs`, **zero** `GenAI` usage, no `llm_models` table |
| **Non-human principal** | **BUILD — blocked by enum** | `member_type_enum('user','group')` (changelog 013); `Authz.get_effective_policies` hardcodes `member_type = 'user'`; MCP caller is always a user UUID (`Mcp.Resolve.current_user_id`) |
| **Agent job queue / workers** | **BUILD — absent** | Oban present, no agent queue/worker/table |

**Two facts drive the two load-bearing decisions in this contract:**
- Agents are a *greenfield* domain, so we build `domains/agents` cleanly in house style.
- The existing PBAC subject is *hard-bound to users* (enum + hardcoded query + JWT `sub`).
  Rather than fork core authz, WS-J builds a **parallel agent PBAC that reuses the
  actor-agnostic `PolicyEvaluator` engine** and binds each agent to an **operator user**
  (Section 2). This keeps `entities/authz.ex` untouched.

---

## 1. Agent registry model

### 1.1 `agents` table — migration `145`

Business entity `Therobotplans.Domains.Agents.Agent` (Noizu.Entity) over Ecto schema
`Therobotplans.Schema.Agents.Agent`, matching the house pattern verbatim (cf.
`entities/organizations/organization.ex`): `use Noizu.Entities`, `@repo`, `@sref "agent"`,
`@persistence ecto_store(...)`, `id(:uuid)`.

```elixir
defmodule Therobotplans.Domains.Agents.Agent do
  use Noizu.Entities
  @vsn 1.0
  @repo Therobotplans.Domains.Agents
  @sref "agent"
  @persistence ecto_store(Therobotplans.Schema.Agents.Agent, Therobotplans.Repo)
  @derive Noizu.Entity.Store.Ecto.EntityProtocol
  def_entity do
    id(:uuid)
    field :organization_id,       nil,      :uuid    # tenant scope (required, indexed)
    field :owner_user_id,         nil,      :uuid    # operator / on-behalf principal (FK users)
    field :name,                  nil,      :string
    field :handle,                nil,      :string  # unique per org; used in channel topics + @mentions
    field :kind,                  :builtin, :atom    # :builtin | :custom  (custom = US-083)
    field :role_label,            nil,      :string  # display role, e.g. "Code Reviewer" (≠ permission role)
    field :provider,              nil,      :string  # genai provider id, e.g. "anthropic"
    field :model,                 nil,      :string  # e.g. "claude-sonnet-5"
    field :system_prompt,         nil,      :string  # M1: inline; migrates to prompt_version_ref (see 1.5)
    field :system_prompt_ref,     nil,      :uuid    # nullable ref → WS-K prompt_versions (US-086), later
    field :config,                %{},      :map     # tool allow/deny stub, temperature, max_tokens, constraints, budget
    field :capabilities,          [],       {:list, :string}  # for the assignee-reference contract (1.6)
    field :avatar_url,            nil,      :string
    field :status,                :registered, :atom # lifecycle, see 1.3
    field :default_permission_role, :observer, :atom # observer|contributor|operator|admin (enforced from M2)
    field :last_heartbeat_at,     nil,      :utc_datetime
    field :time_stamp,            nil,      Noizu.Entity.TimeStamp
  end
  jason_encoder()
end
```

Repo `Therobotplans.Domains.Agents` — `use Noizu.Repo` + `def_repo(entity: Agent)`. Ecto
twin `Therobotplans.Schema.Agents.Agent` carries the columns above plus a unique index on
`(organization_id, handle)` and a btree index on `(organization_id, status)`.

### 1.2 `agent_activity_log` table — migration `146`

The **operational** activity record that powers the M1 dashboard health indicators and
the real-time feed. It is a projection of the canonical envelope (Section 4.1); the
hardened append-only **compliance** log (`agent_audit_log`, migration `345`, US-078) lands
in M3 behind the *same* `emit/1` seam (Section 4.3). M1 writes here; M3 adds the audit
table without changing callers.

Columns: `id uuid pk`, `organization_id uuid`, `agent_id uuid`, `trace_id uuid`,
`event_type varchar`, `outcome varchar`, `target_type varchar`, `target_id uuid`,
`summary text`, `metrics jsonb` (tokens/cost/duration when present), `inserted_at`.
Index `(agent_id, inserted_at desc)` and `(organization_id, inserted_at desc)`.

### 1.3 Lifecycle states + transitions

```
registered ─enable→ enabled ⇄ suspended            (suspend = US-081 pause; queue+context frozen)
                        │  └──────────┐
                        └─disable→ disabled ─remove→ removed (soft-delete; row retained for audit)
   suspended ─disable→ disabled
```

| From | Event | To | Guard (from M2; open in M1) |
|---|---|---|---|
| — | register | `registered` | permission `agents:create` in org scope |
| registered / suspended / disabled | enable | `enabled` | `agents:manage` |
| enabled | suspend (pause) | `suspended` | `agents:operate` (or self via US-081) |
| suspended | resume | `enabled` | `agents:operate` |
| enabled / suspended | disable | `disabled` | `agents:manage` |
| disabled | remove | `removed` | `agents:manage` |

`removed` is a **soft-delete** — the row is retained forever (audit integrity; never
hard-deleted). Only `enabled` agents appear on the active dashboard and accept dispatch.
`suspended` agents keep their queue and serialized context (US-081, table `247`) and
consume no compute/credits.

Transition API (single funnel — all state changes emit an audit event, Section 4):
`Agents.transition(agent_id, event, actor_ctx) :: {:ok, Agent.t} | {:error, term}`.

### 1.4 Declaration — config seeds builtins, DB is runtime truth

- **Builtin agents** (`kind: :builtin`, e.g. `monitor`, `planner`) are declared in
  `config/agents.exs` and **upserted into `agents` on boot** by a seeder
  (`Agents.Seeder`, run from `application.ex` start or a release task). Editable at
  runtime; config is the default, not a lock.
- **Custom agents** (`kind: :custom`, US-083 / M3) are created via the builder API →
  DB rows. No config entry.
- At runtime the `agents` table is the **single source of truth**; the provider/model
  binding is resolved from the row's `provider`+`model` fields (1.5).

### 1.5 Provider / model binding

The `genai` dep is present but unwired and there is **no `llm_models` table**. The
provider layer is net-new. This contract names the seam and defers the registry-ownership
question to sign-off (Open Q5):

```elixir
# WS-J-owned adapter over the genai dep. M1 may ship an echo/no-op impl if genai wiring
# is not yet done — the interface is what US-076 must not paint around.
Therobotplans.Domains.Agents.Provider.invoke(agent, request) ::
  {:ok, %{output: term, metrics: %{tokens_in, tokens_out, model, provider, cost_usd, duration_ms}}}
  | {:error, term}
```

`invoke/2` resolves `agent.provider`/`agent.model` → a genai provider/model config,
runs the completion, and returns output **plus the metrics envelope** that feeds audit
(Section 4), metrics (Section 5), and cost (US-085). A shared LLM pricing table
(`config/llm_pricing.exs` or a future `llm_models` row) supplies `cost_usd = price(model) × tokens`.

### 1.6 Assignee-reference read model — **M1 cross-lane contract**

Published for WS-C US-024 (human/agent assignee picker) and WS-K US-096 (rate agent
output). Consumers **read this, never `agents` directly**.

```elixir
Agents.assignee_reference(organization_id) :: [%{
  agent_id:     uuid,
  name:         String.t,
  handle:       String.t,
  avatar_url:   String.t | nil,
  capabilities: [String.t],
  status:       :enabled | :suspended | :disabled  # pickers filter to :enabled
}]
```

### 1.7 Today-view read model row — **M1 cross-lane contract**

For WS-L US-001/US-002. Matches the platform read-model shape (`id, title, priority,
source, link`) plus agent status:

```elixir
Agents.today_read_model(organization_id) :: [%{
  id: uuid, title: String.t, priority: integer, source: :agent,
  link: String.t,               # deep link to /app/<org>/agents/<agent_id>
  agent_status: :idle | :working | :blocked | :error, current_task: String.t | nil
}]
```

---

## 2. Role & permission integration (US-077, M2 — gates M3)

### 2.1 Design decision: parallel agent PBAC reusing `PolicyEvaluator`

The existing subject is hard-bound to users (Section 0). We do **not** extend
`member_type_enum` or touch the `'user'`-hardcoded core query in v1. Instead:

- Migration `245` adds `agent_roles` and `agent_permissions` (as the roadmap already
  allocates). These define grants for agent principals.
- A new `Therobotplans.Domains.Agents.Authz` module resolves an agent's effective
  policy statements and runs them through the **existing, actor-agnostic**
  `Therobotplans.Authz.PolicyEvaluator.evaluate/6` (which already takes a role +
  action + resource + context, not a user). Zero change to `entities/authz.ex`.

```elixir
Agents.Authz.check_permission(agent_id, resource_type, resource_id, action, context \\ %{}) ::
  {:ok, :allowed} | {:error, :denied | :agent_suspended | :exceeds_operator_ceiling}
```

### 2.2 Roles, scopes, defaults

- Default roles: **observer** (read-only), **contributor** (read + create/comment),
  **operator** (read/write/execute), **admin** (all + approve). Custom roles supported
  (US-077 AC).
- Grants scope to **workspace/org · project · item-type · specific item** (matches
  human PBAC scope tiers), stored as `agent_permissions` rows with
  `(read|write|execute|approve)` per `resource_type`.
- **Deny-by-default**: a newly registered agent gets `default_permission_role: :observer`
  on its assigned scope; every mutation requires an explicit grant.

### 2.3 Operator ceiling (trust boundary)

Every agent has an `owner_user_id` (operator). An agent's effective permission is the
**intersection** of its own grant AND the operator's permission on the same resource — an
agent can never exceed the human who runs it. This answers US-077's "cannot act beyond
mandate" and is the safety backstop for MCP tool calls (Section 7). *(Confirm — Open Q2.)*

### 2.4 Enforcement point + time-boxed escalation

- Enforcement is a **middleware on every agent action path** — dispatch (Section 3),
  tool invocation (Section 7), and state transition (1.3) all call
  `Agents.Authz.check_permission/5` before acting. A blocked attempt is **not silently
  dropped**: it emits an `blocked` audit event (Section 4) and returns `{:error, :denied}`.
- Time-boxed escalation (US-077 note): a grant may carry `expires_at`; the evaluator
  drops expired grants. This reuses `PolicyEvaluator`'s existing `Date*` condition
  operators — no new mechanism.

### 2.5 M1 stub

US-076 ships **before** US-077. In M1 there is no enforced permission model: builtin
agents run with an implicit operator ceiling only. M1 must route all action paths through
a single `Agents.Authz.check_permission/5` function that returns `{:ok, :allowed}` as a
stub, so M2 fills in the body without moving call sites.

---

## 3. Task queue & dispatch (US-079, M2)

### 3.1 Two layers: durable queue (DB) + execution (Oban)

- **`agent_task_queue`** (migration `246`) is the user-visible, reorderable "sprint
  board" for agents (US-079): priority order, status, ETA, status history. This is what
  the queue UI reads and drag-reorders.
- **Oban `agent` queue** (add to `config.exs` `queues:`) is the execution mechanism.
  Enqueuing a task inserts both an `agent_task_queue` row and an
  `Agents.Workers.DispatchWorker` Oban job. Reprioritize/pause/cancel operate on the
  queue row; the worker checks row state before executing.

`agent_task_queue` columns: `id uuid`, `organization_id uuid`, `agent_id uuid`,
`trace_id uuid`, `status varchar` (`pending|in_progress|completed|failed|blocked|cancelled`),
`priority integer` (lexorank or integer, reorderable), `input jsonb`, `context_ref jsonb`,
`deadline utc_datetime null`, `estimated_completion utc_datetime null`, `result jsonb null`,
`enqueued_by uuid`, `inserted_at`, `updated_at`.

### 3.2 Dispatch envelope (input to a dispatched task)

The single shape a caller (any lane, or the assign-to-agent flow US-024) passes to enqueue:

```elixir
Agents.enqueue(%{
  agent_id:        uuid,       # required; must be :enabled
  organization_id: uuid,       # required (tenant scope)
  input:           map,        # the task payload (prompt vars, item ref, etc.)
  context_ref:     map,        # {type, id} pointers into other domains (item/goal/bug…)
  priority:        integer,    # default mid-band; reorderable later
  deadline:        DateTime.t | nil,
  enqueued_by:     uuid,       # user or agent id that requested the work
  trace_id:        uuid | nil  # supply to chain into an existing trace (Section 6); else generated
}) :: {:ok, %{task_id: uuid, trace_id: uuid}} | {:error, :agent_unavailable | :denied | term}
```

`enqueue/1` checks `Agents.Authz.check_permission(agent_id, :task, resource, :execute)`
(queue respects role boundaries — US-079 AC), assigns a `trace_id`, writes the row,
inserts the Oban job.

### 3.3 Result / callback shape

`DispatchWorker` invokes `Provider.invoke/2` (1.5), captures the metrics envelope, then:

```elixir
%{
  task_id:  uuid, agent_id: uuid, trace_id: uuid,
  status:   :completed | :failed | :blocked,
  output:   term,          # nil on failure
  artifacts: [%{type, ref}],  # created items/comments/reports, as domain refs
  metrics:  %{tokens_in, tokens_out, model, provider, cost_usd, duration_ms},
  error:    term | nil
}
```

On terminal status the worker: (a) updates the `agent_task_queue` row, (b) emits the
matching audit event(s) (`errored` / completion / `cost_recorded`), (c) dispatches the
**`:agent_task_completed`** domain event (3.4) that WS-K US-096/US-089 consume.

### 3.4 `:agent_task_completed` — cross-lane completion event

WS-K US-096 (rate output) and US-089 (compare versions) trigger off task completion. This
is a `Therobotplans.Events.dispatch(:agent_task_completed, payload)` broadcast:

```elixir
payload = %{agent_id, task_id, trace_id, organization_id, outcome, prompt_ref}
```

`Therobotplans.Events` has a **fixed `@type_list` allowlist** (user/org events only);
unknown types are dropped. WS-J must file a WS-L interface ticket at M1 milestone start to
add agent event types to the allowlist (Open Q3): `:agent_registered`,
`:agent_status_changed`, `:agent_task_enqueued`, `:agent_task_completed`,
`:agent_action_logged`, `:agent_blocked`.

---

## 4. Audit log (US-078, M3 — the cross-lane spine)

This is the M3 cross-lane spine: **every agent-invoking story in M3** (US-018/019/023/
028/034/037/038/051/055/059/067/071) and WS-K's US-095 emit through the one function in
4.3. Get the envelope and the function stable in M1 even though the hardened table is M3.

### 4.1 Canonical event envelope

One shape underlies the M1 activity log (146), the M3 audit log (345), the metrics rollup
(346), and cost (US-085). Superset of US-078 + US-080 + US-085 needs:

```elixir
%Agents.Event{
  id:              uuid,
  organization_id: uuid,
  agent_id:        uuid,
  operator_user_id: uuid | nil,   # on-behalf principal (Section 2.3)
  action:          atom,          # see enumerated set below
  target_type:     String.t | nil,# "item" | "goal" | "bug" | "incident" | "prompt" | ...
  target_id:       uuid | nil,
  input_context:   map,           # task ref, prompt ref, param summary (compact)
  outcome:         :success | :failure | :blocked,
  rationale:       String.t | nil,# decision reasoning (for :decided / :handoff)
  trace_id:        uuid,          # groups a multi-step invocation / protocol run
  parent_span_id:  uuid | nil,    # handoff / sub-step lineage (Section 6)
  metrics:         %{tokens_in, tokens_out, model, provider, cost_usd, duration_ms} | nil,
  prev_hash:       String.t | nil,# tamper-evident chain (M3, per agent stream)
  hash:            String.t | nil,
  inserted_at:     DateTime.t
}
```

**Action set (enumerated):** `:invoked`, `:decided`, `:tool_called`, `:item_created`,
`:item_updated`, `:status_transition`, `:checklist_modified`, `:report_generated`,
`:errored`, `:blocked`, `:escalated`, `:cost_recorded`, `:handoff`. New actions are
additive; consumers must ignore unknown actions.

### 4.2 `agent_audit_log` table — migration `345` (M3)

Append-only + tamper-evident, enforced **at the DB role level** (US-078 AC): the
application's runtime DB role is granted `INSERT, SELECT` only — **no `UPDATE`/`DELETE`**
on `agent_audit_log`. Per-agent hash chain: `hash = sha256(prev_hash || canonical(row))`;
export verifies the chain. This is why `removed` agents are never hard-deleted (1.3).
Columns mirror the envelope (4.1). Indexes: `(agent_id, inserted_at)`,
`(organization_id, action, inserted_at)`, `(trace_id)`.

Retention is configurable per workspace (US-078 note) — a config value, not a DELETE on
the table (compaction/export to cold storage, not row deletion).

### 4.3 The public emit contract — **the seam other lanes call**

One function. Stable across M1→M3. Best-effort and `safe/1`-guarded like the existing
`Notifications.Dispatch` pattern (a failed emit must never fail the caller's write path):

```elixir
Therobotplans.Domains.Agents.Audit.emit(event_attrs :: map) :: :ok
```

- **M1 behavior:** writes an `agent_activity_log` (146) row from the envelope subset +
  broadcasts to the activity/trace channels (Section 8).
- **M3 behavior (same signature):** additionally writes the append-only, hash-chained
  `agent_audit_log` (345) row. Callers do not change.

Other lanes emit like this (they pass their own agent+task identity from the dispatch
context they received):

```elixir
Agents.Audit.emit(%{
  agent_id: id, organization_id: org, action: :item_updated,
  target_type: "item", target_id: item_id, outcome: :success,
  trace_id: trace, input_context: %{task_id: t}
})
```

Filter/query + export API for the viewer (US-078 AC): `Agents.Audit.query(org_id,
filters)` where filters ∈ `{agent_id, action, resource_type, time_range, outcome}`;
`Agents.Audit.export(org_id, filters, :json | :csv)`.

---

## 5. Metrics & cost (US-080 M3 · US-085 M4)

### 5.1 Capture

Cost/usage is captured **on the envelope** at invocation time — `metrics` map from
`Provider.invoke/2` (1.5) rides every `:invoked` / `:cost_recorded` audit event. No
separate capture path; the audit log is the source of truth (US-080 pairs with US-078 as
its data source, per story notes).

### 5.2 Rollup — migration `346` `agent_performance_metric` (US-080)

`Agents.Metrics.rollup/2` is an Oban job (`Agents.Workers.MetricsWorker`, cron) that reads
`agent_audit_log` and writes per-agent, per-period rows: `tasks_completed`, `error_rate`,
`avg_time_to_completion`, `human_override_rate`, `token_cost`, `period`. Trend =
period-over-period delta. ROI = `human_baseline_estimate − agent_cost`. Threshold alerts
(error rate > X, cost > budget) route through the notification service (Section 9).

### 5.3 Real-time cost + budget (US-085)

- Real-time per-agent counter = sum of `metrics.cost_usd` over the current billing period
  (from audit log, or a maintained counter for hot paths).
- Budget caps live on `agent.config.budget = %{limit, action}` where `action ∈
  :warn | :pause | :hard_stop`. `DispatchWorker` checks budget **pre-invoke**: `:pause`
  transitions the agent to `suspended` (1.3); `:hard_stop` refuses dispatch.
- Cost is **tagged** by `agent_id`, `project` (from `context_ref`), and `client` (org
  attribute) for Diana's per-client invoicing export. Degrades gracefully: when exact
  provider cost is unavailable, emit token counts + estimated cost, never nothing
  (US-085 note).

---

## 6. Orchestration (US-084, M4 — seam only in v1)

Keep v1 minimal; name the seam so M1–M3 don't foreclose it.

- **The envelope already carries `trace_id` + `parent_span_id`** (4.1). A handoff chain
  (Coder→Reviewer→Approver) is expressible *today* as a sequence of dispatches sharing a
  `trace_id`, each new task's `parent_span_id` pointing at the prior span. No new
  primitive is needed for a linear chain — the audit trace *is* the protocol log
  (US-084 AC "auditable trace showing each step").

- **Agent-to-agent message envelope** (the named seam):

```elixir
%{
  trace_id:        uuid, from_agent_id: uuid, to_agent_id: uuid,
  organization_id: uuid, intent: atom,  payload: map,
  deadline:        DateTime.t | nil, reply_to: uuid | nil, parent_span_id: uuid
}
```

  A handoff = `Agents.enqueue/1` for `to_agent_id` built from this envelope.

- **Declarative protocols** (US-084 full): a future `agent_protocol` table (M4, migration
  ~`445`) storing the workflow graph — steps of `{agent, trigger_condition, timeout,
  fallback}`, versioned/clonable/A-B-testable. Dead-letter: a step whose agent is
  unavailable past `timeout` fires its `fallback` (escalate-to-human or reroute) and emits
  an `:escalated` audit event — never a silent drop. **Not built before M4**; listed so
  the `trace_id`/`parent_span_id`/deadline fields designed in M1 are protocol-ready.

---

## 7. MCP plane integration

Agents reach tools through the **existing per-domain MCP servers** (`items.`, `goals.`,
`notifications.` hosts; `Noizu.MCP.Server` macro; tool modules in `domains/<d>/tools/`).
The plane today resolves caller identity as a **user UUID** (`Mcp.Resolve.current_user_id`
← JWT `sub`); it has no notion of an agent principal.

### 7.1 `ToolInvoker` — WS-J wrapper, not a fork of the plane

To avoid forking the shared MCP plane (`mcp_servers.ex`, router host-scopes,
`mcp/resolve.ex` are WS-L-coordinated), WS-J calls tool modules **in-process** through a
wrapper:

```elixir
Therobotplans.Domains.Agents.ToolInvoker.call(agent, server_module, tool_module, args) ::
  {:ok, result} | {:error, :denied | :tool_not_allowed | term}
```

`call/4`:
1. Resolves the **effective tool set** (7.2); rejects disallowed tools *before* invocation
   (US-083 "physically cannot invoke, not just shouldn't").
2. Builds an MCP context that carries **both** `agent_id` and the agent's
   `owner_user_id` as `on_behalf_of` — so the tool's existing user-based authz still
   resolves, bounded by the operator ceiling (2.3).
3. Invokes the tool module directly (reusing `domains/<d>/tools/*`), emits a
   `:tool_called` audit event (Section 4) with outcome.

*Seam for WS-L (Open Q4):* the clean long-term home is an agent-aware
`Mcp.Resolve` that reads `:agent_id`/`:on_behalf_of_user_id` from `ctx.assigns`. Until
that's agreed, `ToolInvoker` injects context locally without editing the shared plane.

### 7.2 Tool-surface scoping by role

An agent's effective tool set =
`custom_agent_definition allow/deny matrix (US-083)` ∩
`role-permitted tool categories (US-077)` ∩
`operator's own tool permissions (2.3)`.

Per-tool mode is `allow | deny | require_human_approval` (US-083 AC). `require_human_approval`
enqueues an approval (routes through notifications, Section 9) and blocks the call until
resolved. **M1:** builtins get a fixed allowlist from `agent.config`; the intersection
machinery lands with US-077 (M2) / US-083 (M3).

---

## 8. Websocket channel naming

Channel-naming is a WS-L-owned cross-cutting convention (confirmed milestone-03); WS-J
**proposes** the names below and files a WS-L interface ticket to add the channel route to
`user_socket.ex`. Authorization follows the existing `OrgChannel` pattern
(`Organizations.authorize(user_id, org_id, "viewer")` in `join/3`).

| Topic | Purpose | Consumers | Join authz |
|---|---|---|---|
| `agents:<org_id>:activity` | Org-wide agent activity feed (status changes, task start/stop, errors) | US-076 dashboard, US-002 today feed | `authorize(user, org_id, "viewer")` |
| `agents:<agent_id>:trace` | Per-agent detailed action/trace stream (detail panel) | US-076 detail panel click-through | resolve agent→org, then `viewer` |
| `agents:<org_id>:queue` | Task-queue live updates (enqueue/reorder/complete) | US-079 queue view | `authorize(user, org_id, "viewer")` |

New channel module `TherobotplansWeb.AgentChannel` (WS-J authors; WS-L adds
`channel "agents:*", TherobotplansWeb.AgentChannel` to `user_socket.ex`). `Agents.Audit.emit/1`
(4.3) broadcasts to `agents:<org>:activity` and `agents:<agent>:trace`; `Agents.enqueue/1`
and queue mutations broadcast to `agents:<org>:queue`. Real-time budget (US-076 "<5s"): the
emit broadcast is synchronous with the write, so UI latency is a single PubSub hop.

Auth note: these channels are consumed by **human users** (dashboards), so the existing
Guardian-user socket auth suffices — no separate agent-authenticated socket in v1
(Open Q7).

---

## 9. v1 scope vs deferred — the milestone cut

**US-076 (M1) MUST build now** — the minimal cut:

1. Migration `145` `agents` + entity/repo/Ecto twin (Section 1.1).
2. Migration `146` `agent_activity_log` (Section 1.2).
3. `domains/agents` context: `register`, `transition/3` (enable/suspend/disable), status +
   health aggregation (idle/working/blocked/error, error-rate-24h, queue-depth),
   `list`/`get` scoped by org.
4. `Agents.Seeder` + `config/agents.exs` builtin seeding (Section 1.4).
5. Canonical `%Agents.Event{}` struct + **`Agents.Audit.emit/1`** in its M1 form
   (writes 146 + broadcasts) — the stable seam (Section 4.3).
6. `Agents.Authz.check_permission/5` **stub** returning `{:ok, :allowed}` at all action
   call sites (Section 2.5) — so M2 fills the body, not the call sites.
7. `TherobotplansWeb.AgentChannel` + the three topics (Section 8); WS-L wires the socket.
8. Assignee-reference (1.6) + today-view read model (1.7) — the M1 cross-lane contracts.
9. `Agents.Provider.invoke/2` interface (Section 1.5) — echo/no-op impl acceptable in M1
   if genai is still unwired, but the signature is fixed.
10. Frontend `app/app/[orgId]/agents/**` card grid + detail panel; `components/agents/**`
    (dark-mode, keyboard nav) — per US-076 AC.

**Deferred (specified here so M1 leaves the seam):**

| Story | Milestone | Migration | Adds |
|---|---|---|---|
| US-077 roles/permissions | M2 | `245` | `agent_roles`/`agent_permissions`; fills `Agents.Authz` body; enforcement middleware; operator ceiling |
| US-079 task queue | M2 | `246` | `agent_task_queue`; `Agents.enqueue/1` + `DispatchWorker`; Oban `agent` queue; reorder/bulk |
| US-081 pause/resume | M2 | `247` | `agent_paused_state` (serialized context); suspend/resume ≤3s |
| US-082 notification prefs | M2 | `248` | `agent_notification_prefs`; threshold evaluator; routes via WS-L notif service |
| US-078 audit log | M3 | `345` | append-only hash-chained `agent_audit_log`; DB-role no-UPDATE/DELETE; audit-emit becomes cross-lane spine; query/export |
| US-080 metrics | M3 | `346` | `agent_performance_metric` rollup job; ROI; threshold alerts |
| US-083 custom agents | M3 | `347` | `custom_agent_definition`/`custom_agent_template`; enforced tool-access matrix; dry-run |
| US-084 protocols | M4 | ~`445` | `agent_protocol` graph; handoff/escalation/dead-letter |
| US-085 cost tracking | M4 | (on `346`/config) | real-time cost counter; budget caps; per-client tagging/export |

Migration IDs follow the roadmap scheme (Mx = x00 + WS-J offset 45–49): M1 → 145/146,
M2 → 245–248, M3 → 345–347. A `db/changelog/lanes/ws-j.yaml` include is introduced (the
flat `db/changelog/` has no `lanes/` yet); WS-L owns the master include.

---

## 10. Public API surface (what other lanes call)

The complete WS-J boundary. Everything else in `domains/agents` is private.

| Function | Callers | Since |
|---|---|---|
| `Agents.assignee_reference(org_id)` | WS-C US-024, WS-K US-096 | M1 |
| `Agents.today_read_model(org_id)` | WS-L US-001/US-002 | M1 |
| `Agents.Audit.emit(attrs)` | **all agent-invoking lanes** (A/C/D/F/G/H/I), WS-K US-095 | M1 seam, M3 spine |
| `Agents.Audit.query/export(...)` | US-078 viewer | M3 |
| `Agents.enqueue(envelope)` | WS-C US-024 assign-to-agent, any dispatch | M2 |
| `:agent_task_completed` event | WS-K US-096/US-089 | M2 |
| `Agents.Authz.check_permission/5` | WS-E US-047, WS-K US-092 (via US-077) | M1 stub, M2 real |
| Channels `agents:<org>:activity` / `:<agent>:trace` / `<org>:queue` | WS-L US-002, US-076/079 UI | M1 |

Consumers **must not** read `agents`/`agent_*` tables directly, subscribe to raw PubSub
agent topics outside the named channels, or write to the audit log by any path other than
`Agents.Audit.emit/1`.

---

## 11. Open questions for lane-lead sign-off

1. **Parallel agent PBAC vs enum extension.** This contract builds `agent_roles`/
   `agent_permissions` + `Agents.Authz` over the existing `PolicyEvaluator`, leaving
   `entities/authz.ex` and `member_type_enum` untouched. Confirm we do **not** want agents
   as first-class `scoped_memberships` principals in v1 (which would require a shared-authz
   migration + touching the `'user'`-hardcoded query — a WS-L/platform change).
2. **Operator ceiling.** Should an agent's effective permission be capped by its
   `owner_user_id`'s permission (intersection — recommended for trust), or are agent grants
   fully independent? Affects Sections 2.3 and 7.1.
3. **Events allowlist.** WS-J needs ~6 agent event types added to the WS-L-owned fixed
   `Therobotplans.Events` allowlist. Confirm the interface-ticket path, and whether agent
   real-time should flow through `Events` at all vs channel-broadcast-only (this contract
   uses channels for UI real-time and `Events` only for `:agent_task_completed` cross-lane
   reactions).
4. **MCP agent identity.** OK for WS-J to inject agent + on-behalf context via a
   `ToolInvoker` wrapper (Section 7.1), or does WS-L want agent-aware identity built into
   the shared `mcp/resolve.ex` from the start?
5. **GenAI provider registry ownership.** The `genai` dep is unwired and there's no
   `llm_models` table. Every lane's M3 AI story needs provider/model invocation. Is the
   shared LLM provider/model/pricing registry a **WS-L/platform** deliverable (recommended)
   that WS-J's `Agent` binds to, or does WS-J own it? This is a scope decision beyond WS-J.
6. **System-prompt storage timing.** WS-K `prompt_versions` (US-086) also lands in M1. Do
   we store the agent charter inline (`system_prompt`) in M1 and migrate to
   `system_prompt_ref` later, or coordinate the shared table at M1 milestone start?
7. **Agent-authenticated socket.** v1 assumes agent channels are consumed only by human
   dashboards (existing Guardian-user auth suffices). Confirm no agent-authenticated
   websocket is needed before M4 orchestration.
8. **Migration `146` vs `345` overlap.** This contract keeps a lightweight M1
   `agent_activity_log` (146) *and* a hardened M3 `agent_audit_log` (345), unified behind
   `emit/1`. Confirm two tables (operational feed vs compliance spine) is acceptable vs
   collapsing to one append-only table from M1 (which front-loads the DB-role hardening
   work into M1).
