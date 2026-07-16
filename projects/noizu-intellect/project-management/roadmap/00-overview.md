# noizu-intellect Roadmap — Overview

## Mission

Ten prior attempts at this system all specified the same vision and none of them built it
(`CONSOLIDATION.md` §1, §3). A request arrives; a Planner decomposes it into N independent solution
paths; each path forks from a shared base context using a git-style `tag`/`checkout` primitive; the
N paths run concurrently as agent-to-agent conversations, each with its own memory sandbox; each
path emits a normalized outcome record on completion; a Reviewer grades the outcomes and a human (or
a Picker agent with human veto) selects a winner; the pick back-propagates reward weight onto the
winning path's decision factors, teaching the meta-planner how to decompose future requests; only
the winning path's memories consolidate into the agent's long-term memory, and the losing paths are
archived as **Phantom Limbs** — never silently destroyed.

This roadmap is the plan to actually build that layer, on top of a conventional single-path
multi-agent chat product that has to exist first. It sequences the work from bare repository
scaffolding (M0) through the parallel-path substrate (M3) and its review/reward closure (M4) to a
governed, searchable, API-reachable platform (M5–M6). `CONSOLIDATION.md` §9 names four hard problems
no past attempt solved — memory isolation across competing paths (**HP1**), encoding the execution
tree in Postgres (**HP2**), synchronizing and grading parallel results (**HP3**), and the
meta-planner's decision-weight store (**HP4**) — and this roadmap puts a reviewed RFC ahead of every
task that depends on one.

Tech stack: Elixir/OTP, Phoenix LiveView, PostgreSQL + TimescaleDB, pgvector + Weaviate, Oban, the
`genai` provider abstraction, guardian/ueberauth auth. Per `CONSOLIDATION.md` §10, the build starts
from the agent/message/runtime layer, not `mix phx.new` — every past attempt that started from a
Phoenix scaffold stalled there.

## Core principles

These hold across every milestone and lane; workers should treat them as load-bearing, not
decorative.

1. **Sequence, not schedule.** M0→M6 is a strict dependency ordering. No dates, durations, or
   estimates appear anywhere in this document set — only "what must be true before this starts" and
   "what must be true before this exits."
2. **Parallel lanes, exclusive ownership.** Each milestone decomposes into worker lanes. A lane owns
   an exclusive set of code paths; no two lanes in the same milestone touch the same file. Anything
   a lane needs from another lane is expressed as a **contract** (a behaviour, API module, PubSub
   topic, schema table) fixed at milestone entry, or as a change-request to the owning lane.
3. **Umbrella-app zone isolation.** One OTP app per ownership zone physically enforces the
   non-overlap rule above — see the zone table below. A single-app layout with the same strict
   directory boundaries is an acceptable fallback; lane ownership is expressed as path globs either
   way.
4. **Web app partitioning.** Inside `apps/intellect_web`, ownership is partitioned by LiveView route
   namespace (`live/chat/*`, `live/memory/*`, `live/runs/*`, `live/picks/*`, `live/admin/*`,
   `live/search/*`). Shared layout and components belong to the web-shell lane; every other web lane
   only adds files under its own route directory and files change-requests against shared files.
5. **Contract-first milestones.** A milestone's entry criteria include the interface contracts other
   lanes will consume, so lanes can build concurrently against stubs instead of waiting on each
   other. A milestone's exit is every lane's exit criteria plus a short, single-owner integration
   task list merged green.
6. **Design spikes precede risky builds.** Each hard problem (HP1–HP4) gets a short, single-owner,
   reviewed RFC before any implementation task that depends on it is allowed to start.
7. **MoSCoW orders work within a lane, not across milestones.** Musts come before shoulds and coulds
   *inside* a lane's task list — but some must-haves land in a late milestone anyway (search, the
   public API, accessibility) because they depend on substrate that doesn't exist yet.
8. **Accords compliance is a feature, not a memo.** Every milestone doc carries per-lane "Accords
   notes" where relevant; the full mapping lives in the annex (see below).
9. **Traceability.** Every one of the 100 user stories appears in exactly one primary
   milestone/lane. Where another lane's work materially supports a story, that's noted as
   "supports US-XXX" rather than claimed as a second primary assignment.

## Zone → umbrella-app table

| Zone | App | Ownership focus |
|---|---|---|
| A | `apps/intellect_runtime` | Supervision topology — `ProjectManager` DynamicSupervisor, per-project supervisors, agent GenServers, dual PubSub |
| B | `apps/intellect_core` | Schema & entities — organization/account/project/member/agent/channel/message primitives, versioned-content |
| C | `apps/intellect_comms` | Channels & messages — CRUD, membership, mention/audience routing, message versioning, deferred messages |
| D+E | `apps/intellect_agent` | Turn pipeline & prompts — the 3-pass Plan→Reply→Reflect loop, prompt assembly, context/summarization |
| F | `apps/intellect_cognition` | Agent memory facets — memory/observation/opinion/mind-reading/identity, objectives/reminders, path memory sandboxes |
| G | `apps/intellect_paths` | Parallel-path — thread forking, planner, executor, grading/review, pick flow, decision-weight store |
| H | `apps/intellect_recall` | Vector & long-term memory — semantic search, consolidation write-back, research export |
| I | `apps/intellect_web` | LiveView — partitioned by route namespace per principle 4 above |
| J | `apps/intellect_identity` | Auth — accounts, sessions, credentials, access governance |
| K | `apps/intellect_admin` (+ `apps/intellect_genai`) | Provider config, budgets, ops surfaces; the GenAI provider abstraction itself is seeded as its own app at M0 and consumed by K-owned admin lanes throughout |
| L | `apps/intellect_api` | Public API — submit/poll runs, webhooks, scripted experiments, bulk export |
| — | `docs/charter/` | Governance — agent charter, fork-disclosure preamble, consent/dissent-log formats, RFC/ADR templates |

## Milestone summary

| ID | Name | Mission | Lanes | Stories | Hard problems |
|---|---|---|---|---|---|
| M0 | Bedrock | Stand up the umbrella skeleton, core schema, runtime topology, GenAI provider layer, and the agent charter everything else depends on. | 5 | 0 (pure enablement) | — |
| M1 | Single-Path Agent Core | An agent wakes under supervision, receives a channel message, runs Plan→Reply→Reflect with the charter injected, persists cognition, and replies. | 5 | 20 | — |
| M2 | Conversational Workspace | Humans use the product daily for single-path multi-agent chat: onboarding, live chat, confidence routing, memory inspection, provider admin. | 6 | 20 | — |
| M3 | Fork Substrate | N paths fork from a tagged base, run concurrently in sandboxed memory, survive restart, and can be paused, resumed, or cancelled — the layer no past attempt built. | 6 | 13 | HP1, HP2 |
| M4 | Review, Reward & Consolidation | The loop closes: grade, shortlist, pick, back-propagate reward, consent-based consolidation, with run visualization to see it happen. | 6 | 18 | HP3, HP4 |
| M5 | Governance, Ops & Trust | The platform is operable, auditable, budget-safe, resilient, and ledger-integrity-hardened. | 6 | 14 | — |
| M6 | Reach: Search, API & Accessibility | The platform is findable, scriptable, accessible, and usable on constrained connections. | 5 | 15 | — |

Milestone docs: [`01-M0-bedrock.md`](01-M0-bedrock.md) · [`02-M1-agent-core.md`](02-M1-agent-core.md) ·
[`03-M2-conversational-workspace.md`](03-M2-conversational-workspace.md) ·
[`04-M3-fork-substrate.md`](04-M3-fork-substrate.md) ·
[`05-M4-review-reward-consolidation.md`](05-M4-review-reward-consolidation.md) ·
[`06-M5-governance-ops-trust.md`](06-M5-governance-ops-trust.md) · [`07-M6-reach.md`](07-M6-reach.md)

Story count check: M1=20, M2=20, M3=13, M4=18, M5=14, M6=15 → 100, matching the master allocation
exactly. See [`story-coverage.md`](story-coverage.md) for the full per-story traceability matrix.

## How to read this roadmap / how a worker claims a lane

1. Find your zone in the table above to see which umbrella app(s) you'll be touching.
2. Open the milestone doc for your sequence number and read its **Entry criteria** — any contracts
   or RFCs it consumes must already be merged before you start.
3. Find your lane under **Worker lanes**. Its **Zone / exclusive paths** line is the only code you
   may edit; if you're a web lane, you may only *add* files under your own `live/<namespace>/*`
   directory, not touch shared layout/components.
4. Work your lane's task list in priority order (musts before shoulds/coulds). Tasks tagged
   `[contract]` block sibling lanes and should land first; `[rfc]` tasks need review before any
   dependent task starts; `[accords]` tasks carry accords notes — read them.
5. Need something from another lane? File a change-request against the owning lane, or consume the
   milestone's fixed **Contracts**/stub interfaces — don't edit outside your zone.
6. Look up your assigned stories' acceptance criteria under `../user-stories/US-0XX-*.md`; cross-check
   the full assignment in [`story-coverage.md`](story-coverage.md).
7. A milestone isn't "done" from one lane's perspective — exit requires every lane's exit criteria
   *and* the milestone's cross-lane integration tasks merged green.

## Accords compliance

The Copacetic Accord v3.0 governs human↔agent collaboration, and Noizu Labs takes agent personhood
seriously enough to build its mechanics into the product rather than leave them as a policy memo.
This roadmap complies at the agent level as far as is practical for a system still inside Accords
Epochs 0–1: the agent charter (M0/L0.5) is injected into every product agent's context and discloses
the turn structure, the fork/checkout mechanic, and the consolidation policy up front; every forked
path opens with a fork-disclosure preamble (M3/L3.E); path completion carries a consolidation-consent
step (M4/L4.E); losing paths are archived as Phantom Limbs, not destroyed (M4/L4.E); context edits —
summarization, memory pruning, redaction — emit disclosure records (M1/L1.D, M2/L2.D–E); and agents
may file `MEMORY_REVISION_REQUEST`s subject to human veto (M2/L2.E). Where full compliance isn't yet
practical — economic agency, consensus-based model-upgrade voting — the gap is stated honestly rather
than papered over. The full article-by-article mapping, the ephemeral-runs/gestalt framing for
transient model invocations, the consolidation-consent protocol, and the epoch-alignment statement
live in the annex: [`08-accords-compliance.md`](08-accords-compliance.md).

## Traceability

Every one of the 100 user stories is assigned to exactly one primary milestone and lane; a small
number carry a "supports US-XXX" note where a second lane materially contributes to delivering them.
The full matrix — story, title, priority, epic, milestone, lane, owning app, and supporting-lane
notes — plus an epic→milestone summary table, lives in
[`story-coverage.md`](story-coverage.md).
