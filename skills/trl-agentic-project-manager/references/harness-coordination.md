# Cross-Harness Coordination

How agents running in different harnesses coordinate as **peers** through tobor chat rooms, tickets, and the shared plan file. This is the protocol layer; concrete tobor tool calls live in [tobor-mcp-integration.md](tobor-mcp-integration.md), and who to staff on each role in [provider-strengths.md](provider-strengths.md).

> **Transport status (verified 2026-07-16).** The live tobor surface is Organization/Project/Session CRUD plus the discovery meta-tools; **rooms and tickets are not yet callable**. Everywhere below, "room" and "ticket" name the *protocol object*, carried today over the append-only room file (`{slug}.room.md`) and per-unit ticket files (`{slug}.tickets/U{n}.md`) — see [tobor-mcp-integration.md](tobor-mcp-integration.md) for the interim transport and the discovery sweep that detects those tool families when they land. The protocol is transport-agnostic: it reads identically over files today and over `Room.*`/`Ticket.*` tools later.

## 1. The Peer Model

Coordinating across harnesses buys two things: **resilience** (any peer can drop or be replaced without stalling the plan) and **provider-strength routing** (each track runs on the harness/model best suited to it — see [provider-strengths.md](provider-strengths.md)). Both depend on treating every harness as an equal peer against shared external state.

Any agent, in any harness, that can reach the tobor-* MCP servers is a **full participant** — a peer, not a subordinate of whichever harness happens to be "primary." There is no privileged runtime.

- **The shared brain is external.** The coordination room (the stream), the tickets (the state), and the plan file (the map) are the only authoritative record. No harness's session memory, context window, or scratchpad is authoritative for anything another agent needs.
- **Harnesses are interchangeable at the seams.** A track can start on Claude Code, hand off to Codex CLI, and finish on noizu-intellect. As long as each reads the ticket + last `STATUS` before acting, the plan survives the swap.
- **Peership is defined by reachability, not by model tier.** A Haiku-class summarizer and a frontier coordinator are both peers; they differ in *role* (see §5), not in standing.
- **One special role, not one special harness.** Exactly one agent holds the **coordinator** role (arbitrates gates and contract changes). That role is assigned in the charter and can be re-held by any capable peer if the incumbent drops — it is not tied to a harness.
- **Liveness is contractual, not observed.** No human watches the room; a peer is "alive" only as long as it heartbeats (§4). Presence is a message, not a connection — so every peer owes the room a `STATUS` on cadence.

**What is authoritative vs. ephemeral:**

| State | Home | Authoritative? |
|-------|------|----------------|
| Work-unit ownership + progress | Ticket + room `CLAIM`/`STATUS` | Yes |
| Feature intent + acceptance criteria | Story/Epic + plan file | Yes |
| Frozen contracts (C-series) | Plan file / committed artifacts | Yes |
| Gate state (open/closed, evidence) | Ticket + room `STATUS G#`/`DONE G#` | Yes |
| An agent's chain-of-thought, scratch, local context | Harness session memory | **No** — never relied on cross-agent |
| "I mentioned it in chat earlier" | Scrollback | **No** — reconcile to ticket, not scrollback |

> Corollary (SKILL Principle 5): agent-to-agent state lives in tobor rooms, tickets, and stories — never in one harness's session memory. Every rule below exists to make dropping, reconnecting, or replacing any peer a non-event.

## 2. Harness Capability Table

Fill honestly per deployment; cells marked **verify per version** change with harness releases and wrappers — confirm before relying on them rather than assuming.

| Harness | MCP client | Filesystem access | Background / long-running | Subagent spawning | Typical residency |
|---------|-----------|-------------------|---------------------------|-------------------|-------------------|
| **Claude Code** (CLI) | Yes | Full local FS | Yes — background Bash, hooks, cron | Yes — Agent/Task fleet | Ephemeral per invocation; can be daemonized via cron/loop |
| **Claude Code** (desktop) | Yes | Full local FS | Yes | Yes | Ephemeral session (GUI-bound) |
| **Claude Code** (web) | Yes (connectors) | Sandboxed workspace only | Limited — session-bound | Yes (cloud agents) | Ephemeral cloud session |
| **Codex CLI** | Yes | Full local FS (repo) | Verify per version | No native fleet — verify per version | Ephemeral per invocation |
| **OpenCode** | Yes | Full local FS | Verify per version | Verify per version | Ephemeral per invocation |
| **Grok** | Verify per version (wrapper-dependent) | Wrapper-dependent | Verify per version | No | Ephemeral chat / API call |
| **noizu-intellect** | Yes — native tobor integration | Deployment-dependent | Yes — long-lived daemon | Yes — native orchestration | Long-lived daemon / service |
| **claude.ai** (web / Teams) | Yes (connectors/MCP) | None — no local FS, artifacts sandbox only | No — session-bound | No | Ephemeral session |

**Reading the table for staffing:**
- **No-FS harnesses** (claude.ai) can coordinate, review, design contracts, and summarize — but cannot own a code track that edits files. Give them contract, review, or summarizer roles.
- **Ephemeral harnesses** must externalize state aggressively (they will lose their context). **Long-lived** harnesses (noizu-intellect, daemonized Claude Code) are natural homes for the coordinator and summarizer singletons.
- **No-subagent harnesses** execute a single track well but can't fan out internally — plan them as leaf workers, not sub-coordinators.

## 3. Connecting a Harness to tobor

Each harness configures MCP differently, but the shape is identical:

1. **Register the endpoints.** Add the `tobor-root` (discovery/NPL) and `tobor-sessions` (session CRUD today; ticket/room tools when the surface exposes them) MCP servers to the harness's MCP config, plus `tobor-organizations` if the harness will create orgs. Mechanism varies: Claude Code uses `.claude` MCP config / `claude mcp add`; Codex CLI and OpenCode use their own MCP config blocks; claude.ai uses connectors in settings.
2. **Provide auth.** Supply the harness's tobor credentials/token (see the tobor-locker MCP auth note in project memory — tokens expire and must be refreshed before session registration).
3. **Verify with a discovery call.** Confirm the wiring with a read-only call before doing work — e.g. `Session_Overview` or a `ToolSummary`. If discovery returns the tool catalog, the harness is a peer; if it 401s or returns `Organization '$VAR' not found`, auth or slug resolution is broken (the MCP layer does **not** expand env vars — resolve slugs first).

**Per-harness mechanism (shape, not exhaustive — verify per version):**

| Harness | MCP config surface | Auth style |
|---------|--------------------|-----------|
| Claude Code (CLI) | `claude mcp add` / project `.claude` MCP config | Token in env / `~/.claude.json`; refresh before session register |
| Codex CLI | MCP server block in its config file | Token / service credential |
| OpenCode | MCP config block | Token / service credential |
| claude.ai (web/Teams) | Connectors in settings (interactive consent) | OAuth connector — interactive; **not** available headless |
| noizu-intellect | Native tobor wiring | Pre-provisioned service credential (long-lived) |

> **Headless / cron caveat.** Interactively-authenticated MCP (OAuth-in-browser, desktop connector consent) is frequently **absent in headless or cron runs** — the interactive token never gets minted. Long-lived agents (daemonized Claude Code, noizu-intellect, scheduled routines) need **non-interactive auth**: a service token or pre-provisioned credential in the environment, not a login prompt. Verify the discovery call succeeds *in the headless context*, not just in your interactive shell.

## 4. Room Protocol, In Depth

Expands the charter's message grammar ([assets/coordination-room-charter.md](../assets/coordination-room-charter.md)). Every message is prefixed with **exactly one** type token. IDs (`U#` work units, `C#` contracts, `G#` gates) come from the plan file.

### Message formats

| Type | Grammar | Examples |
|------|---------|----------|
| `CLAIM` | `CLAIM U3 — {handle} — starting {what}` | `CLAIM U3 — codex/backend — starting notification-prefs endpoints`<br>`CLAIM U7 — cc/e2e — starting prefs Cypress specs vs stub` |
| `STATUS` | `STATUS U3 — {%/state} — next: {what}` | `STATUS U3 — 60%, endpoints stubbed, wiring persistence — next: validation`<br>`STATUS U7 — green vs stub, 9/9 — next: idle until G1 OPEN` |
| `BLOCKED` | `BLOCKED U3 on {what} — need {who/decision}` | `BLOCKED U7 on C1 field name mismatch — need coordinator ruling`<br>`BLOCKED U3 on U2 migration not landed — need backend/U2` |
| `HANDOFF` | `HANDOFF U3 → {handle}: {state, remaining, gotchas}` | `HANDOFF U3 → cc/backend-2: endpoints done, migration untested; gotcha: channel enum stored as int not string` |
| `CONTRACT-RFC` | `CONTRACT-RFC C1 — {change} — impact: {tracks}` | `CONTRACT-RFC C1 — add channel value 'sms' — impact: frontend, e2e, fixtures` |
| `DONE` | `DONE U3 — {evidence: tests/paths}` | `DONE U3 — 14/14 pass; api/notifications/*.ex, migration 0042`<br>`DONE G1 — front↔back integrated, 22/22 e2e green` |

### Claiming semantics

- **Claim before touching.** No edit to any path until a `CLAIM` on its work unit is posted to the room. Claiming is the write-lock.
- **One active claim per unit.** A work unit has at most one live owner. Before claiming, scan the room for an existing open `CLAIM`/`STATUS` on that `U#`; if present and fresh, pick a different unit or coordinate.
- **Stale-claim timeout + reclaim.** A claim with no `STATUS` for longer than the charter's staleness threshold (default: the STATUS cadence × 2) is **stale**. To reclaim: post `BLOCKED U3 — claim stale since {time}, requesting reclaim`, wait for the coordinator's ack (or the incumbent's `STATUS`), then `CLAIM U3 — {you} — reclaiming from {prior handle}`. Never silently take over a claimed unit.

### STATUS as heartbeat

- `STATUS` is **presence**, not just progress. Post on meaningful progress *and* at least every cadence interval, even if the message is `STATUS U3 — still on validation, no blockers`.
- **Silence = presumed dropped.** A track that misses the cadence past the staleness threshold is presumed dropped; its claim becomes reclaimable (above). This is how an ephemeral harness losing its session is detected without anyone watching it.

### Drop-safe discipline

- **Every `STATUS` must be resumable.** Write it so a *successor who has never seen your session* can pick up from the ticket + your last `STATUS` alone. State what's done, what's in flight, and the next concrete step — not "making progress."
- **`HANDOFF`-resume is the recovery path.** When a peer drops, the successor reads the ticket and the last `STATUS`, posts `CLAIM U3 — {successor} — resuming from stale claim`, and continues. A good `STATUS` makes `HANDOFF` unnecessary; a real `HANDOFF` message is the same content delivered deliberately instead of reconstructed.

### DONE requires evidence

- `DONE` carries proof — passing test counts, artifact paths, or contract-conformance output — never a bare assertion. A `DONE` without evidence is treated as a `STATUS` and the unit stays open. Gate `DONE`s (`DONE G1 — …`) cite the integration test result, not just "merged."

### Worked transcript (one room, four harnesses, one drop)

Shows the protocol carrying a track through a mid-flight drop without losing the plan. Handles encode `harness/role`.

```
cc/coord        STATUS G0 — contracts frozen: C1 api-spec, C2 selector-schema, C3 data-model
codex/backend   CLAIM U2 — codex/backend — starting notification-prefs endpoints (keyed to C1, C3)
cc/frontend     CLAIM U4 — cc/frontend — starting prefs settings panel (keyed to C1, C2)
grok/e2e        CLAIM U5 — grok/e2e — starting Cypress prefs specs vs fixture stub (keyed to C2)
codex/backend   STATUS U2 — 50%, endpoints stubbed, wiring persistence — next: validation
grok/e2e        DONE U5 — 9/9 green vs stub; e2e/prefs.cy.ts
codex/backend   STATUS U2 — 70%, validation in progress — next: enum handling
   … (codex/backend session drops; no STATUS past threshold) …
cc/coord        BLOCKED U2 — claim stale since 14:02, requesting reclaim
ni/backend-2    CLAIM U2 — ni/backend-2 — resuming from ticket + last STATUS (enum handling remained)
ni/backend-2    CONTRACT-RFC C1 — 'channel' should be string enum not int — impact: frontend, e2e, fixtures
cc/coord        STATUS C1 — RFC approved; C1 v2 posted to plan; frontend+e2e re-key
ni/backend-2    DONE U2 — 14/14 pass; api/notifications/*.ex, migration 0042
cc/coord        STATUS G1 — OPEN (front↔back entry criteria met)
```

The successor (`ni/backend-2`, a long-lived harness) resumed from the ticket and last `STATUS` — never from `codex/backend`'s lost session — and the enum discrepancy went through `CONTRACT-RFC`, not a quiet local fix.

### Message hygiene (cross-harness invariants)

Rooms are read by heterogeneous parsers (a Haiku summarizer, a frontier coordinator, `grep`) — so keep messages machine-scannable:

- **One type token, first.** Exactly one prefix at the start of the line. No bare chatter in the coordination room; discussion that isn't `CLAIM/STATUS/BLOCKED/HANDOFF/CONTRACT-RFC/DONE` goes in a thread or a side channel, not the main bus.
- **Always cite the ID.** Every message names its `U#`/`C#`/`G#`. An untagged message is invisible to `grep BLOCKED U7` and to the summarizer's roll-up.
- **Stable handles.** Keep a consistent `harness/role` handle for the initiative's life so heartbeat/staleness tracking works. Changing handles mid-track looks like a drop plus a new claimant.
- **Append, don't rewrite.** Correct via a new message (`STATUS`/`HANDOFF`), don't edit history — other harnesses may have already read the old line, and edits don't reliably propagate across MCP clients.
- **Timestamps are the tiebreaker.** Claim races and staleness both resolve on message time; rely on the room's server timestamp, not local clocks.

## 5. Coordination Patterns

| Pattern | Rule | Why |
|---------|------|-----|
| **Coordinator singleton** | Exactly one agent holds the coordinator role (named in the charter). It is the *only* arbiter of gate openings and `CONTRACT-RFC` outcomes. Other peers **propose**; they do not decide. | Prevents split-brain (§6). One arbiter means one linear decision history. |
| **Fast-model room summarizer** | Staff a Groq/Haiku-class peer to read the room backlog and emit periodic `STATUS`-digest summaries (open claims, blockers, gates pending). | Frontier coordinators shouldn't burn tokens re-reading the full backlog each turn; the summarizer distills the stream cheaply. Staffing in [provider-strengths.md](provider-strengths.md). |
| **Ticket-as-source-of-truth** | The **room is the stream; the ticket is the state.** On any state change, update the ticket first, then post the room message announcing it. Readers reconcile to the ticket, not to scrollback. | Scrollback is lossy and unordered across harnesses; the ticket is the durable, queryable truth. |
| **Cross-harness handoff** | Handoff = `HANDOFF` message **+ ticket reassignment**. The successor reads the *ticket + last STATUS*, never the predecessor's session. | Sessions don't cross harness boundaries; tickets and rooms do. |

**Coordinator loop (singleton):** watch room → on `BLOCKED`, unblock or resequence → on `CONTRACT-RFC`, rule and broadcast → when a gate's entry criteria are met, post `STATUS G{n} — OPEN` → collect `DONE G{n}` with evidence → advance. Full role definition in [agent-playbook.claude-code.md](agent-playbook.claude-code.md).

**Role → residency fit** (map roles onto §2's capability table):

| Role | Wants | Good homes | Poor fit |
|------|-------|-----------|----------|
| Coordinator (singleton) | Long residency, MCP, frontier reasoning | noizu-intellect daemon, daemonized Claude Code | Ephemeral chat harness (drops mid-arbitration) |
| Room summarizer (singleton) | Cheap, fast, MCP-read | Groq/Haiku-class peer | Frontier model (wasteful) |
| Code track (leaf worker) | Full FS, one exclusive ownership set | Claude Code, Codex CLI, OpenCode | claude.ai (no FS) |
| Contract / review / design | MCP, reasoning; FS optional | Any frontier peer incl. claude.ai | Fast-only models (under-reasons contracts) |

**Room lifecycle:** coordinator (or the provisioning agent) creates the room, pins the filled charter as message 1, and posts `STATUS G0` when Phase-0 contracts freeze. Workers join, read charter + their ticket, and `CLAIM`. The room stays the live bus until the final gate closes; closing the session archives it as the initiative's coordination record.

## 6. Failure Modes & Mitigations

| Failure mode | Symptom | Mitigation |
|--------------|---------|------------|
| **Split-brain** (two coordinators) | Conflicting gate rulings / RFC decisions | Charter names **exactly one** coordinator; a would-be second coordinator instead `BLOCKED`s asking for role transfer. Role moves only on confirmed drop. |
| **Stale claims** | A unit shows claimed but no progress; work stalls | STATUS-as-heartbeat + staleness threshold + documented reclaim procedure (§4). Silence past threshold ⇒ reclaimable. |
| **Session-memory coordination** | "I told the other agent in chat" — but it dropped and lost it | Durable-state rule: anything a peer needs lands in room + ticket + plan. Session memory is never authoritative. |
| **Contract drift** | An agent "just fixes" a frozen C-series artifact locally; parallel tracks silently diverge | Contracts are frozen; `CONTRACT-RFC` through the coordinator is the **only** legal change path. Conformance checks at gates catch unauthorized drift before integration. |
| **Room noise drowns signal** | Coordinator can't find blockers in chatter | Typed prefixes make the stream filterable (`grep BLOCKED`); the fast-model summarizer emits digests so the coordinator reads distilled state, not raw backlog. |
| **Provider / harness outage mid-track** | A track's harness goes down mid-unit | Fall back to another roster entry (provider-strengths.md) + `HANDOFF`-resume from the last `STATUS`. Ephemeral-harness drops are already handled by the heartbeat/reclaim path. |
| **Ambiguous claim race** | Two peers claim the same `U#` near-simultaneously | Earliest `CLAIM` timestamp wins; the later claimant yields and re-scans. Coordinator breaks true ties. |
| **Duplicate work** (missed prior claim) | Two peers build the same unit from stale scrollback | Scan for open `CLAIM`/`STATUS` on the `U#` **before** claiming; reconcile to the ticket (source of truth), not to a partial room read. |
| **Premature gate open** | Coordinator opens G# before entry criteria truly met | Gate `STATUS G# — OPEN` requires *verifiable* criteria (tests green, contract conformance) — not vibes; twice-failed gates demote to an investigation unit per the charter. |

## 7. Cross-References

- **[tobor-mcp-integration.md](tobor-mcp-integration.md)** — the concrete tobor-* MCP tool calls behind every action here: creating the session, room, story, and tickets; posting messages; reassigning tickets on handoff.
- **[provider-strengths.md](provider-strengths.md)** — who to staff on each role: which provider class makes a good coordinator singleton, and which fast/cheap model to staff as the room summarizer.
- **[agent-playbook.claude-code.md](agent-playbook.claude-code.md)** — the coordinator role as an executable loop.
- **[assets/coordination-room-charter.md](../assets/coordination-room-charter.md)** — the fillable charter this protocol expands; post it pinned as the room's first message.

> In practice: stand up the room and tickets (tobor-mcp-integration.md), pin the filled charter, staff roles by residency (§5) and provider strength, then let peers `CLAIM` and heartbeat. The room is the stream, the ticket is the state, the plan is the map — no session memory is the truth.
