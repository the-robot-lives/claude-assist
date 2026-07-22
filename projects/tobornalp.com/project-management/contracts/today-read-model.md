---
title: Today Read-Model Contract
lane: WS-L (Platform Shell & Cross-Domain)
milestone: M0 (Baseline Audit & Platform Contracts)
consumers: US-001 (M2 unified today dashboard) · US-002/003/004/005 (M3 today expansion) · agent read-path (Agent Runtime Contract §Today)
providers: WS-A (personal), WS-C (projects/items), WS-F (monitoring/incidents), WS-I (goals/OKRs), WS-J (agent tasks)
grounded_against: app/backend commit on branch feat/ex-litellm; changelogs 001–034
status: draft — pending WS-L lane-lead sign-off
---

# Today Read-Model Contract

The single shape and seam for the unified **Today** surface — the "what do I do now"
view that merges everything competing for a user's attention (assigned work, due items,
personal todos, goals off track, incidents on their plate, agent tasks awaiting them)
into one ranked list.

WS-L owns the aggregator (`Therobotplans.Today`), the envelope, the merge/rank/dedup, the
REST surface, and the live channel. **Every other lane contributes to Today only by
implementing a `Today.Provider` and registering it** — never by editing `today.ex` or the
today controller/channel. This is the read-side mirror of the Agent Runtime Contract:
lanes publish *into* Today through the behaviour named here.

This contract is implementation-ready. WS-L can build the aggregator refactor (§4) and the
US-001 dashboard read-path from §2–§6 without re-reading the story; the chunk-B substrate
lanes (WS-A US-011, WS-C US-021, WS-I US-069) can implement their provider from §2 + §3 +
§7 in parallel, before the aggregator refactor lands.

---

## 0. Substrate reality — what exists today

Grounded in a full read of `app/backend/lib/therobotplans/today.ex` + the items/goals/
notifications domains (recon 2026-07-22).

| Capability | State | Anchor |
|---|---|---|
| `Today.plan/2` aggregation | **build-on, refactor** | `Therobotplans.Today` — returns a **structured map** (`:assigned`, `:due_soon`, `:objectives`, `:key_results`, `:unread_notifications`), NOT a flat ranked list; owns no table |
| REST surface | **build-on** | `GET /api/v1/today?org_id=&due_window_days=` → `TodayController.show` (Guardian JWT, viewer-authz when org-scoped) |
| Item substrate | **build-on** | `Schema.Item` — `assignee` (string user id), `status`, `priority`, `due_date`, `custom_fields.due_date`, `key` (PREFIX-NNN), `rank` |
| Priority ranking | **build-on** | `today.ex` SQL `CASE`: `critical=0 · high=1 · medium=2 · low=3 · else 4` |
| Goals/OKR progress | **build-on** | `Domains.Goals.objective_progress/1` → `Decimal` 0..1; item-backed KRs via `kr_item_links` |
| Notification count | **build-on** | `Domains.Notifications.count(org, recipient)`; live topic `notifications:<org>` (PubSub, **not** a Phoenix channel yet) |
| Phoenix channels | **build-on, extend** | `user_socket.ex` → only `org:<id>` → `OrgChannel` (Guardian JWT, viewer-authz). **No `today:*` channel exists.** |
| Event bus | **build-on, extend allowlist** | `Therobotplans.Events` topic `"events"`, **fixed** `@type_list` (6 user/org events only — no item/goal/incident/agent events) |
| Provider behaviour | **BUILD — absent** | no `Today.Provider`, no registration; `plan/2` hard-codes its four internal queries |

**Two facts drive this contract:**
- `Today.plan/2` today is a **monolith of four inlined queries over items+goals+
  notifications**. It is the *seed*, not the shape. WS-L refactors it into a
  provider-merging aggregator (§4) that emits a **flat, ranked `[entry]` list** — the
  envelope in §2 — while keeping the current grouped map available as a derived view for
  back-compat during M1→M2.
- Lanes must be able to contribute *before* the refactor lands. So the behaviour (§3) and
  envelope (§2) are frozen now; a lane writes its provider module against them and it slots
  in when WS-L flips the aggregator.

---

## 1. Design goals

1. **One envelope, many sources.** Personal todos, project items, incidents, off-track
   goals, and agent tasks all render as the same `entry` map so the frontend has one card
   component and one sort.
2. **Provider isolation = merge safety.** A lane owns its provider module in its own path
   (`domains/<lane>/today_provider.ex`). Adding a source is one new file + one registration
   line in WS-L config — zero edits to other lanes.
3. **Deterministic rank.** The aggregator, not the provider, decides final order, so a
   noisy lane can't dominate the list. Providers supply *hints*; WS-L supplies *policy*.
4. **Cheap and bounded.** Each provider is read-only, org-scoped, per-user, and returns a
   capped slice. The aggregator fans out concurrently with a per-provider timeout and a
   failed provider degrades to "omitted", never a 500.
5. **Live without coupling.** Live updates ride one `today:<user>` channel; providers
   signal freshness by emitting an already-allowlisted event, not by knowing about the
   channel.

---

## 2. The canonical `entry` envelope

The atomic unit of Today. Every provider yields a list of these; the frontend renders each
as one card. Represented as a plain map (not a struct) so MCP/JSON serialization is
identity — the agent read-path consumes the same shape.

```elixir
%{
  # ── identity ───────────────────────────────────────────────
  id:          binary(),        # stable, globally-unique within a plan; "<source>:<source_ref.id>"
  source:      atom(),          # :personal | :item | :incident | :goal | :agent_task  (the lane)
  source_ref:  %{               # lane-native handle, opaque to WS-L, used for dedup + deep actions
    type: atom(),               #   e.g. :item | :objective | :incident | :habit | :agent_task
    id:   binary()              #   the lane's primary id (item UUID, objective UUID, ...)
  },
  kind:        atom(),          # :task | :alert | :reminder | :goal  (drives icon/section/affordance)

  # ── display ────────────────────────────────────────────────
  title:       binary(),        # required, one line
  subtitle:    binary() | nil,  # optional secondary line (e.g. "PROJ-123 · in progress")
  link:        binary(),        # required deep link, app-relative: "/app/#{org}/items/#{key}"

  # ── scheduling / status ────────────────────────────────────
  due_at:      DateTime.t() | Date.t() | nil,   # nil = unscheduled
  status:      atom() | binary() | nil,         # lane-native status token, for the badge
  priority:    :low | :medium | :high | :critical | nil,

  # ── ranking (hints; aggregator owns final order) ───────────
  weight:      number() | nil,  # provider's own 0.0..1.0 salience within its source; nil = default
  sort_hint:   integer() | nil, # optional intra-source tiebreak (e.g. board rank), lower = earlier

  # ── passthrough ────────────────────────────────────────────
  meta:        map()            # lane-specific extras (e.g. %{project_key: "PROJ", stage: "review"})
}
```

### Field rules
- **`id`** MUST be `"#{source}:#{source_ref.id}"`. This makes it stable across polls and
  gives the dedup layer (§4.3) a natural key.
- **`link`** is app-relative and MUST resolve under the org shell (`/app/:orgId/...`). The
  frontend prefixes host; providers never emit absolute URLs.
- **`due_at`** accepts `Date` (all-day, e.g. an item `due_date`) or `DateTime` (a timed
  reminder/incident SLA). The aggregator normalizes to `DateTime` at end-of-day UTC for
  ranking; the frontend re-derives all-day vs timed from the original type in `meta` if it
  cares.
- **`priority`** is the shared four-level enum (matches `Item.priorities/0`). A source with
  no native priority passes `nil`; the aggregator treats `nil` as below `:low`.
- **`weight`/`sort_hint`** are *advisory*. A provider that has nothing meaningful sends
  `nil` for both and accepts default policy. See §4.2 for how they feed the score.
- **`meta`** is never interpreted by WS-L ranking; it's a display/telemetry passthrough.

### Reference mapping (grounds the envelope in real columns)

| source | source_ref.type | title | subtitle | link | due_at | status | priority | provider lane |
|---|---|---|---|---|---|---|---|---|
| `:item` | `:item` | `item.title` | `"#{item.key} · #{stage}"` | `/app/:org/items/:key` | `item.due_date` | `item.status` | `item.priority` | WS-C |
| `:personal` | `:item` (personal todo) or `:habit` | todo/habit title | streak / list name | `/app/:org/personal/...` | `due_date` | `status` | `priority` | WS-A |
| `:goal` | `:objective` | `objective.title` | `"#{round(progress*100)}% · #{status}"` | `/app/:org/goals/:id` | `objective.due_date` | `objective.status` | derived from at_risk/off_track | WS-I |
| `:incident` | `:incident` | incident title | severity / service | `/app/:org/monitoring/incidents/:id` | SLA/ack-by | incident state | severity→priority | WS-F |
| `:agent_task` | `:agent_task` | task title | agent handle | `/app/:org/agents/:handle/queue/:id` | task due | task state | task priority | WS-J |

> The current `Today.plan/2` already produces item- and goal-shaped rows internally; §4.4
> shows how its four query blocks map onto the first three providers so the refactor is a
> lift, not a rewrite.

---

## 3. The `Today.Provider` behaviour

Every contributing lane implements this in a module it owns:
`Therobotplans.Domains.<Lane>.TodayProvider`.

```elixir
defmodule Therobotplans.Today.Provider do
  @moduledoc """
  A source of Today entries. One per contributing lane. The aggregator
  (`Therobotplans.Today`) fans out to every registered provider concurrently,
  merges, ranks, dedups, and caps. A provider is read-only, org-scoped, and MUST
  be side-effect free.
  """

  @typedoc "A single Today card — see the Today Read-Model Contract §2."
  @type entry :: %{
          required(:id) => binary(),
          required(:source) => atom(),
          required(:source_ref) => %{type: atom(), id: binary()},
          required(:kind) => atom(),
          required(:title) => binary(),
          required(:link) => binary(),
          optional(:subtitle) => binary() | nil,
          optional(:due_at) => DateTime.t() | Date.t() | nil,
          optional(:status) => atom() | binary() | nil,
          optional(:priority) => atom() | nil,
          optional(:weight) => number() | nil,
          optional(:sort_hint) => integer() | nil,
          optional(:meta) => map()
        }

  @doc "Stable atom identifying this source; becomes the entries' `:source`."
  @callback source() :: atom()

  @doc """
  Read this source's entries for `user_id`, optionally org-scoped.

  `opts`:
    * `:org_id`           — nil spans all the user's orgs; a binary scopes to one.
    * `:due_window_days`  — horizon for due/scheduled entries (default 7).
    * `:limit`            — max entries the aggregator wants from THIS source (default 25).
    * `:now`              — injected clock (DateTime) for testability.

  MUST return a list (possibly empty). MUST NOT raise for ordinary "no data" or
  "not authorized in that org" — return `[]`. The aggregator guards anyway (§4.1),
  but providers own their empty/authz cases.
  """
  @callback read(user_id :: binary(), opts :: keyword()) :: [entry()]

  @doc "Optional: providers whose freshness is event-driven declare the event types that dirty their slice."
  @callback dirty_on() :: [atom()]
  @optional_callbacks dirty_on: 0
end
```

### Provider obligations
- **Org scoping.** When `opts[:org_id]` is set, filter to it; when nil, span the user's
  orgs (the provider decides its own membership join). Never leak cross-tenant rows.
- **User scoping.** Entries must be things *this user* should act on — assigned to them,
  owned by them, or explicitly routed to them. "Everything in the org" is not a Today
  source.
- **Caps.** Respect `opts[:limit]`. The aggregator caps the *merged* list too (§4.5), but a
  provider returning 10k rows wastes the fan-out budget.
- **Purity.** No writes, no notification sends, no KR recompute. Reads only.
- **Latency.** Target < 50ms; the aggregator's per-provider timeout is 250ms (§4.1).

---

## 4. The aggregator (`Therobotplans.Today`)

WS-L refactors `plan/2` into: **resolve registered providers → concurrent fan-out with
timeout → merge → dedup → rank → cap → shape**.

### 4.1 Fan-out + fault isolation
```elixir
def plan(user_id, opts \\ []) do
  providers = registered_providers()        # §4.6
  limit_each = opts[:limit_per_source] || 25

  entries =
    providers
    |> Task.async_stream(
      fn p -> safe_read(p, user_id, Keyword.put(opts, :limit, limit_each)) end,
      max_concurrency: length(providers),
      timeout: 250,
      on_timeout: :kill_task
    )
    |> Enum.flat_map(fn
      {:ok, list} -> list
      {:exit, _}  -> []          # timed-out/crashed provider → omitted, never fatal
    end)

  entries
  |> dedup()                     # §4.3
  |> rank(opts)                  # §4.2
  |> cap(opts[:limit] || 100)    # §4.5
end
```
`safe_read/3` wraps the callback in try/rescue/catch (mirrors the `Notifications.Dispatch`
`safe/1` guard already in the codebase) so a provider bug degrades that one source only.

### 4.2 Ranking policy (aggregator-owned)
Final order is a computed score, descending. Providers supply inputs; WS-L owns the
formula so no single lane can dominate:

```
score(entry) =
    priority_weight(entry.priority)     # critical 4.0 · high 3.0 · medium 2.0 · low 1.0 · nil 0.5
  + urgency(entry.due_at, now)          # overdue +3.0 · today +2.0 · ≤window +1.0 · none 0.0
  + kind_bias(entry.kind)               # :alert +2.0 · :task +1.0 · :reminder +0.5 · :goal +0.5
  + (entry.weight || 0.0)               # provider salience, 0.0..1.0
```
Ties broken by (a) `due_at` ascending, then (b) `sort_hint` ascending, then (c) `id` for
stability. `priority_weight` reuses the exact `critical>high>medium>low` order already in
`today.ex`. The formula lives in one private function so US-003 (drag-reorder) and later
tuning touch one place.

### 4.3 Dedup
The same underlying thing can surface from two sources (e.g. an item that is *also* a KR's
backing item, or a bug that is *also* an incident). Dedup key = `source_ref` tuple
(`{type, id}`), NOT `id` (which is source-prefixed). Policy: **keep the highest-scoring
entry, merge the loser's `meta`** under `meta.also[]` so the card can show "also: KR
backing". Cross-source collisions are expected and intentional — this is where they're
resolved.

### 4.4 Mapping the current `plan/2` onto providers (the lift)
| current `plan/2` block | becomes | new source | notes |
|---|---|---|---|
| `assigned_items/2` | WS-C `ProjectsTodayProvider.read` (items with a project) + WS-A personal (project-less) | `:item` / `:personal` | same `assignee`+status filter, same priority CASE |
| `due_soon_items/3` | folded into the above — `due_at` populated, urgency handled by ranking | — | the separate "due soon" bucket disappears; due-ness becomes a score input |
| `active_objectives/2` + `objective_progress` | WS-I `GoalsTodayProvider.read` | `:goal` | only surfaces `at_risk`/`off_track` (needs attention), not every active objective |
| `item_backed_krs/1` | dropped from Today entries; KR progress rides the goal entry's `meta` | — | avoids the KR/objective/item triple-surfacing |
| `unread_count/2` | NOT an entry — stays a top-level plan field (`:unread_notifications`) | — | a count, not a card; see §5 response shape |

### 4.5 Cap
After ranking, take the top `opts[:limit]` (default 100). The frontend paginates/sections
client-side; the aggregator guarantees the highest-scoring slice is present.

### 4.6 Registration
Providers are resolved from application config (WS-L-owned), so adding a source is a
one-line config edit, not a code change in `today.ex`:

```elixir
# config/config.exs  (WS-L owns this key)
config :therobotplans, Therobotplans.Today,
  providers: [
    Therobotplans.Domains.Items.ProjectsTodayProvider,     # WS-C
    Therobotplans.Domains.Personal.TodayProvider,          # WS-A
    Therobotplans.Domains.Goals.TodayProvider,             # WS-I
    Therobotplans.Domains.Monitoring.TodayProvider,        # WS-F  (M2)
    Therobotplans.Domains.Agents.TodayProvider             # WS-J  (M2)
  ]
```
`registered_providers/0` reads this list, filters to modules that `Code.ensure_loaded?` +
export `read/2` (so a not-yet-deployed lane's entry is a safe no-op). A lane adds its
module to this list via an **interface ticket to WS-L** (per roadmap principle 4), never by
editing the config from its own PR.

---

## 5. REST response shape

`GET /api/v1/today?org_id=&due_window_days=&limit=` (existing route, existing authz —
viewer on the org when scoped). The controller wraps the aggregator output:

```json
{
  "plan": {
    "user_id": "…",
    "org_id": "…",
    "generated_at": "2026-07-22T…Z",
    "entries": [ { /* §2 envelope */ }, … ],
    "unread_notifications": 3,
    "sources": ["item", "personal", "goal"]
  }
}
```
- `entries` is the flat, ranked list — the frontend's single source of truth for cards.
- `unread_notifications` stays a scalar (it's a badge, not a card) — preserves the current
  field.
- `sources` lists which providers actually contributed (a timed-out/absent provider is
  simply not listed), so the UI can show "monitoring unavailable" gracefully.
- **Back-compat window (M1→M2):** the controller MAY also emit the legacy grouped keys
  (`assigned`, `due_soon`, `objectives`) derived from `entries` by `source`, behind a
  `?shape=legacy` param, until the FE cuts over to `entries`. Removed at US-001 ship.

---

## 6. Live updates — the `today:<user>` channel

Today gains **one** new Phoenix channel, WS-L-owned, added to `user_socket.ex` alongside
the existing `org:*`:

```elixir
# user_socket.ex  (WS-L)
channel "today:*", TherobotplansWeb.TodayChannel
```

- **Join topic:** `today:#{user_id}`. Authz: the socket's Guardian-authenticated `user_id`
  must equal the topic's user id (a user subscribes only to their own Today). Mirrors
  `OrgChannel`'s join-time authz pattern.
- **Server → client event:** `"today:refresh"` with a small payload
  `%{reason: atom(), source: atom()}` — a nudge, not a diff. The client re-`GET`s
  `/api/v1/today` (or the affected source) on receipt. Keeps the channel dumb and the read
  path single-sourced.
- **How a source triggers a refresh (no coupling):** a lane emits one of its
  **allowlisted event-bus events** (e.g. `:item_updated`, `:objective_off_track`,
  `:incident_opened`) on the existing `Therobotplans.Events` bus. WS-L runs one subscriber
  that maps event → affected users → `TodayChannel` broadcast. **Providers never call the
  channel.** This requires extending `Events.@type_list` (currently 6 user/org events only)
  with the lane events — that allowlist extension is itself a WS-L interface-ticket item
  (see the event-bus contract) and is the *only* shared-file touch a provider lane needs
  for live Today.

---

## 7. Provider implementation checklist (chunk-B lanes)

A lane building its M1 substrate story (WS-A US-011, WS-C US-021, WS-I US-069) ships its
Today provider in the same PR, in its own path:

1. Create `domains/<lane>/today_provider.ex` implementing `@behaviour Today.Provider`.
2. `source/0` returns your source atom (§2 table).
3. `read/2`:
   - scope by `opts[:org_id]` (nil = span user's orgs) and by user (assigned/owned/routed);
   - map each row to the §2 envelope — set `link` app-relative, `id` as `"src:refid"`,
     `priority`/`due_at`/`status` from real columns;
   - populate `weight`/`sort_hint` only if you have a meaningful signal (else `nil`);
   - respect `opts[:limit]`; return `[]` on empty/unauthorized, never raise.
4. Unit-test `read/2` against a seeded user in two orgs (scoped + unscoped) and the empty
   case. Do **not** test ranking/dedup — those are WS-L's and tested against the aggregator.
5. File a WS-L interface ticket to add your module to the `providers` config list (§4.6)
   and, if you want live refresh, to add your event type(s) to `Events.@type_list` (§6).
6. Until WS-L lands the aggregator refactor, your provider is inert-but-correct: it
   compiles, unit-tests green, and activates the moment it's registered. No coordination
   needed on the refactor timing.

---

## 8. Non-goals / deferred

- **Client-side reorder persistence** (US-003) — the aggregator returns a canonical order;
  storing a user's manual override is US-003's problem (a WS-L feature over this contract),
  not part of the envelope.
- **Activity feed / unified stream** (US-002/005) — a *different* read model (event history,
  not actionable cards). It may reuse the envelope but is specified separately in M3.
- **Cross-project summary rollups** (US-004) — an aggregation *over* entries; consumes this
  contract, doesn't change it.
- **Snooze/dismiss of a Today entry** — deferred; when added it's a WS-L overlay keyed by
  `source_ref`, invisible to providers.
- **Write-back** (completing a todo from Today) — Today is read-only; the card's `link`/
  actions call the owning lane's existing write API. Today never mutates.
