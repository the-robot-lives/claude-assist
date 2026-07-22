---
name: trl-agentic-project-manager
description: >-
  Plan multi-agent delivery as interface-first DAGs. Use for parallel decomposition,
  fleet assignment, conflict-safe tracks, cross-harness coordination, or integration
  gates—not timelines, agent design, or solo implementation.
extended_description: >
  Plan and coordinate multi-agent software delivery as parallelized work DAGs —
  sequence and fan-out, never timelines — across heterogeneous providers (Claude,
  OpenAI/Codex, DeepSeek, Grok, Groq-hosted fast models, local models) and
  harnesses (Claude Code, Codex CLI, OpenCode, noizu-intellect), using tobor-*
  MCP sessions, tickets, stories, and chat rooms for cross-harness coordination.
  Use this skill when the user wants to plan work parallelization, decompose a
  feature into interface-first parallel tracks, assign tasks to agents or
  personas by provider strength, coordinate a fleet of coding agents, partition
  work to avoid merge conflicts, or set up cross-harness agent communication —
  even if they don't say "project management." Also trigger on: work DAG,
  fan-out plan, contract-first development, fleet roster, task claiming,
  coordination room, parallel implementation tracks, integration gates.
  NOT for timeline/Gantt/sprint-ceremony planning, designing agents themselves
  (trl-agent-architect), harness internals (trl-agentic-harness-engineer), or
  implementing a single story solo (trl-story-to-release).
ch-description: >-
  以介面優先的工作 DAG 規劃多代理軟體交付。適用於平行拆解、代理團隊分派、避免衝突的工作軌、跨執行框架協作與整合關卡；不適用於時程甘特圖、代理設計或單人實作。
---

# Agentic Project Manager

Turn a feature request into a maximally parallel work DAG, staff it with the right agents on the right providers, and coordinate execution across harnesses through tobor chat rooms — without merge conflicts and without wasted serial time.

## Overview

Traditional project management plans **when** work happens (timelines, sprints). This skill plans **what can happen simultaneously** — it treats a fleet of AI agents as a parallel machine and the work plan as a dependency DAG to schedule onto it. It provides:

- **Parallelization planning** — Decompose features into a dependency DAG, find the interface-first cut points that unlock parallel tracks, and identify the true critical path
- **Interface-first fan-out** — The flagship pattern: freeze contracts (API interface, UX spec, selector schema, data model) first, then write frontend, backend, and test coverage simultaneously instead of sequentially
- **Fleet assignment** — Match tasks to providers by strength (Groq-hosted models for fast/cheap iteration, local models for private/bulk work, frontier models for architecture and integration) and assign personas to tasks
- **Cross-harness coordination** — Agents running in Claude Code, Codex CLI, OpenCode, Grok, and noizu-intellect communicate through tobor-* MCP chat rooms, tickets, and stories using a shared coordination protocol
- **Merge-conflict avoidance** — Exclusive file-ownership maps per track, contract freezes, and staged integration gates so parallel work lands cleanly

## Core Philosophy

**Five Principles:**

1. **Plan dependencies, not dates** — The output of planning is a DAG of work units with explicit blocking edges. Wall-clock time is an emergent property of fleet size; it is never an input to the plan.
2. **Contracts are the cut points** — Every edge you can replace with a frozen contract (API spec, selector schema, type definition, fixture) converts sequential work into parallel work. Spend serial time only on contracts; spend parallel time on everything else.
3. **One owner per file** — Two agents editing one file is a merge conflict scheduled in advance. Partition the file tree into exclusive ownership sets per track; contested files become contract work or integration work.
4. **Match the model to the task** — A Groq-hosted model formats and lints in milliseconds; a local model grinds through bulk transforms for free; a frontier model designs interfaces and untangles integration. Paying frontier prices for mechanical work — or trusting fast models with architecture — are both assignment failures.
5. **Coordinate through durable channels** — Agent-to-agent state lives in tobor rooms, tickets, and stories — never in one harness's session memory. Any agent on any provider can drop, reconnect, or be replaced without losing the plan.

## When to Use This Skill

- **Planning a multi-agent build** — A feature or project needs to be decomposed for a fleet of agents rather than one sequential worker
- **Maximizing parallelization** — Work is flowing sequentially (frontend → backend → tests) and you want the interface-first restructuring that lets those tracks run simultaneously
- **Staffing decisions** — Choosing which provider/model/harness/persona gets each work unit
- **Cross-harness coordination setup** — Standing up tobor chat rooms, tickets, and protocols so agents in different harnesses can claim tasks, report status, and hand off work
- **Merge-conflict triage** — Parallel work keeps colliding; you need ownership maps and integration gates
- **Auditing an existing plan** — Reviewing a work breakdown for hidden serialization, contested files, or misassigned tasks

> For designing the agents themselves (personas, prompts, memory), see **trl-agent-architect**.
> For the runtime harness an agent executes inside (loops, sandboxing, guardrails), see **trl-agentic-harness-engineer**.
> For implementing one story end-to-end as a single worker, see **trl-story-to-release**.
> For the data-cy selector schema that test tracks key against, see **trl-ui-test-engineer**.
> For designing the API contracts frozen in Phase 0, see **trl-api-designer**.

## The Planning Model

### Work DAG, not Gantt chart

A plan is a set of **work units** connected by **blocking edges**, grouped into **tracks** (chains of units with a single owner), separated by **gates** (synchronization barriers where tracks integrate).

| Concept | Definition | Rule |
|---------|-----------|------|
| Work unit | Smallest independently assignable piece | One owner, one deliverable, testable in isolation |
| Blocking edge | "B cannot start until A's output exists" | Only real data/contract dependencies — no habit edges |
| Track | Chain of work units with one owner | Owns an exclusive file set for its lifetime |
| Gate | Barrier where tracks synchronize | Entry criteria are verifiable (tests pass, contract met) |
| Contract | Frozen artifact that replaces a blocking edge | Versioned; changes after freeze go through the coordinator |

**Planning procedure:** enumerate deliverables → draw only true dependencies → attack every edge ("could a contract, stub, or fixture remove this?") → group into tracks → partition file ownership → place gates → assign.

> Full method, dependency-classification table, and plan format: [references/parallelization-planning.md](references/parallelization-planning.md).

### Interface-First Fan-Out (flagship pattern)

The usual sequential flow — UX → frontend → backend → tests — hides massive parallelism. Restructure it:

**Phase 0 — Contracts (serial, small, frontier-model work):**
API interface spec · UX spec + screen inventory · Cypress selector schema (`data-cy` extended attributes) · data-model deltas · fixture/stub definitions

**Phase 1 — Parallel tracks (each owns disjoint files, all run simultaneously):**

| Track | Builds | Keyed to |
|-------|--------|----------|
| Frontend | React components, pages, state | API contract + UX spec + selector schema |
| Backend | Endpoints, services, migrations | API contract + data model |
| E2E tests | Cypress specs | Selector schema (runs against stub) |
| Backend tests | Unit/integration tests | API contract (runs against mocks) |
| Fixtures | Mock server, seed data | API contract |

**Phase 2 — Pairwise integration (partially parallel):**
front ↔ back · e2e tests ↔ real frontend (mocked API) · API tests ↔ real backend

**Phase 3 — Full integration:** integrated test suite against the integrated system → review → done.

The e2e tests are written **before the frontend exists** because both are keyed to the same frozen selector schema — that is the entire trick, generalized in [references/interface-first-patterns.md](references/interface-first-patterns.md).

## Fleet Assignment

Provider strengths drive assignment (full matrix and heuristics in [references/provider-strengths.md](references/provider-strengths.md)):

| Class | Examples | Assign |
|-------|----------|--------|
| Frontier reasoning | Claude Opus/Fable, GPT-5-class, Grok heavy | Contract design, decomposition, integration debugging, review |
| Fast inference | Groq-hosted (Llama/Qwen), Haiku-class | Status summarization, lint/format passes, quick lookups, triage |
| Cheap bulk reasoning | DeepSeek, mid-tier OSS | Well-specified implementation tracks, test authoring against contracts |
| Local models | Ollama/llama.cpp, custom fine-tunes | Private-data work, unlimited-volume transforms, offline CI loops |
| Specialized harnesses | Codex CLI, OpenCode, noizu-intellect | Whatever their tooling does best (repo-scale edits, Elixir-native flows) |

Personas ride on top of assignments: a persona (reviewer temperament, domain voice, house style) is attached to a task so any capable model can execute it in character. See [references/persona-assignment.md](references/persona-assignment.md).

## Cross-Harness Coordination

All coordination state is modeled as tobor-* MCP objects:

| Object | Used for |
|--------|----------|
| Session | Umbrella for the initiative; everything hangs off it |
| Story/Epic | Feature-level intent and acceptance criteria |
| Ticket/Task | One work unit: owner, track, ownership set, gate |
| Chat room | The coordination bus: claiming, status, blocking questions, handoffs, contract-change requests |
| Instruction prompts | Reusable templated briefs so delegating the Nth task costs one line |

Agents in any harness that can reach the tobor MCP participate as peers. The room protocol (message types: `CLAIM`, `STATUS`, `BLOCKED`, `HANDOFF`, `CONTRACT-RFC`, `DONE`) is defined in [references/harness-coordination.md](references/harness-coordination.md); concrete tool calls in [references/tobor-mcp-integration.md](references/tobor-mcp-integration.md).

**Surface status (verified 2026-07-16):** the live tobor tool surface is Organization/Project/Session CRUD plus the discovery meta-tools. Rooms, tickets, stories, artifacts, and instruction prompts are referenced by the platform but **not yet callable**. The protocol above is transport-agnostic: until those land, run it over an append-only room file plus repo-committed plan/ticket files, and re-check the surface with a discovery sweep at session start (both covered in tobor-mcp-integration.md).

## Merge-Conflict Avoidance

Conflicts are prevented at plan time, not resolved at merge time:

1. **Ownership map** — every file/glob is assigned to exactly one track (or marked `contract` / `integration`)
2. **Contract freeze** — shared surfaces (types, schemas, selector attributes) are written once in Phase 0 and change only via `CONTRACT-RFC` through the coordinator
3. **Workspace isolation** — per-track worktrees or staged copies (this monorepo's `staging/` git-init pattern), integrated in gate order
4. **Integration order** — gates land pairwise (front↔back before full integration) so each merge has one moving side

> Full playbook including monorepo/subtree specifics: [references/merge-conflict-avoidance.md](references/merge-conflict-avoidance.md).

## Execution Workflow

| Phase | Activity | Output |
|-------|----------|--------|
| 1. Intake | Read story/PRD, clarify scope and acceptance criteria | Scoped deliverable list |
| 2. Decompose | Build the work DAG, attack edges, define contracts | Work plan (DAG + tracks + gates) |
| 3. Partition | File-ownership map per track | Ownership map |
| 4. Staff | Match tracks to providers/harnesses/personas | Fleet roster |
| 5. Provision | Create tobor session/story/tickets/room; post charter | Live coordination bus |
| 6. Coordinate | Monitor room, unblock, arbitrate contract RFCs | Status updates, decisions |
| 7. Integrate | Run gates in order, verify entry criteria | Integrated system |
| 8. Close | Verify acceptance criteria, close tickets, retro the plan | Closed session + plan-quality notes |

Agent-executable versions of these phases: [references/agent-playbook.claude-code.md](references/agent-playbook.claude-code.md).

## Quick Start Guides

### Plan a feature for parallel execution
1. Fill the intake section of [assets/work-plan-template.md](assets/work-plan-template.md)
2. Decompose per [references/parallelization-planning.md](references/parallelization-planning.md); apply the fan-out from [references/interface-first-patterns.md](references/interface-first-patterns.md)
3. Partition ownership per [references/merge-conflict-avoidance.md](references/merge-conflict-avoidance.md)
4. Staff with [assets/fleet-roster-template.md](assets/fleet-roster-template.md) using [references/provider-strengths.md](references/provider-strengths.md)

### Stand up cross-harness coordination
1. Create session, story, and tickets per [references/tobor-mcp-integration.md](references/tobor-mcp-integration.md)
2. Create the coordination room; post [assets/coordination-room-charter.md](assets/coordination-room-charter.md) as the pinned charter
3. Brief each agent with its ticket + charter; agents `CLAIM` and begin
4. Coordinate per the protocol in [references/harness-coordination.md](references/harness-coordination.md)

### Audit an existing plan
1. Check every blocking edge: is it a true data dependency or habit? (parallelization-planning.md §Dependency Classes)
2. Check ownership: any file claimed by two tracks? Any unowned shared surface?
3. Check assignments: frontier models on mechanical work? Fast models on contract design?
4. Check gates: are entry criteria verifiable, or vibes?

## Reference Guide

| Task | Read These |
|------|-----------|
| **Decomposing work into a DAG** | `parallelization-planning.md` |
| **Applying the fullstack fan-out** | `interface-first-patterns.md` |
| **Choosing providers/models per task** | `provider-strengths.md` |
| **Setting up agent communication** | `harness-coordination.md`, `tobor-mcp-integration.md` |
| **Calling tobor tools correctly** | `tobor-mcp-integration.md` |
| **Preventing merge conflicts** | `merge-conflict-avoidance.md` |
| **Attaching personas to tasks** | `persona-assignment.md` |
| **Running the coordinator role** | `agent-playbook.claude-code.md` |
| **Seeing it all end-to-end** | `worked-example-notification-preferences.md` |

All reference paths are relative to `references/`.

## Related Skills

- **trl-agent-architect** — Designs the agents and personas this skill assigns; hand off when a needed specialist doesn't exist yet
- **trl-agentic-harness-engineer** — Builds/hardens the harnesses agents run in; this skill only selects among existing harnesses
- **trl-story-to-release** — Executes one story as a single worker; this skill is the layer above, splitting stories across many workers
- **trl-ui-test-engineer** — Owns the Cypress selector-schema discipline (`data-cy` extended attributes) that the e2e test track keys against
- **trl-api-designer** — Designs the API contracts frozen in Phase 0
- **trl-user-experience-engineer** — Produces the UX specs, screen inventories, and personas consumed at intake

## Bundled Resources

### Root
- [INTRODUCTION.md](INTRODUCTION.md) — Consumer I/O contract (read first)

### References
- [agent-playbook.claude-code.md](references/agent-playbook.claude-code.md) — Coordinator role definition + executable workflows
- [parallelization-planning.md](references/parallelization-planning.md) — Work-DAG method: dependency classes, edge attack, tracks, gates, plan format
- [interface-first-patterns.md](references/interface-first-patterns.md) — Contract-first fan-out patterns: fullstack flagship + variants
- [provider-strengths.md](references/provider-strengths.md) — Provider/model strength matrix and assignment heuristics
- [harness-coordination.md](references/harness-coordination.md) — Cross-harness room protocol, message types, harness capability table
- [tobor-mcp-integration.md](references/tobor-mcp-integration.md) — Concrete tobor-* usage: live Session ToolCalls today, plus the interim file transport carrying tickets/stories/rooms until those tool families land
- [merge-conflict-avoidance.md](references/merge-conflict-avoidance.md) — Ownership maps, contract freeze, workspace isolation, integration order
- [persona-assignment.md](references/persona-assignment.md) — Persona-task matching and the npl-persona ecosystem
- [worked-example-notification-preferences.md](references/worked-example-notification-preferences.md) — End-to-end: one feature planned, staffed, coordinated, integrated

### Assets
- [work-plan-template.md](assets/work-plan-template.md) — Fillable work plan: DAG, tracks, ownership map, gates
- [fleet-roster-template.md](assets/fleet-roster-template.md) — Agent/provider/harness/persona roster with assignments
- [coordination-room-charter.md](assets/coordination-room-charter.md) — Pinned room charter: protocol, message types, escalation rules
- [project-tracker.md](assets/project-tracker.md) — Progress tracker for a coordinated initiative
