# Coordination Room Charter — {feature-slug}

> Post this (filled) as the room's first/pinned message. Every participating agent
> reads it before claiming work. It is the cross-harness protocol: agents on any
> provider follow it identically. The room transport may be a tobor chat room or an
> append-only room file (`project-management/work-plans/{slug}.room.md`) — the
> protocol is identical either way.

## Scope

- **Session**: {tobor session uuid}
- **Story**: {story id} — {one-line intent}
- **Plan**: `project-management/work-plans/{slug}.md` (IDs referenced below come from it)
- **Coordinator**: {agent handle} — arbitrates gates and contract changes

## Message protocol

Prefix every message with exactly one type token:

| Type | When | Format |
|------|------|--------|
| `CLAIM` | Taking a work unit | `CLAIM U3 — {handle} — starting {what}` |
| `STATUS` | Meaningful progress or every {cadence} | `STATUS U3 — {done %/state} — {next}` |
| `BLOCKED` | Cannot proceed | `BLOCKED U3 on {what} — need {who/decision}` |
| `HANDOFF` | Passing work between agents | `HANDOFF U3 → {handle}: {state, remaining work, gotchas}` |
| `CONTRACT-RFC` | Requesting a frozen-contract change | `CONTRACT-RFC C1 — {change} — impact: {tracks}` |
| `DONE` | Work unit complete, criteria met | `DONE U3 — {evidence: tests/paths}` |

## Rules

1. **Claim before touching.** No edits to any path without a `CLAIM` on its work unit.
2. **Stay in your ownership set.** Your track's globs are in the plan. Need a file outside them? `BLOCKED`, not a quiet edit.
3. **Contracts are frozen.** Deviating from C-series artifacts without an approved `CONTRACT-RFC` invalidates parallel tracks. Never "just fix" a contract.
4. **DONE requires evidence.** Passing tests, artifact paths, or contract-conformance output — not assertions.
5. **Durable state only.** Anything another agent needs must land in this room, a ticket, or the plan file — never only in your session memory.
6. **Drop-safe.** Assume you may be replaced mid-task: keep `STATUS` current enough that a successor can `HANDOFF`-resume from your last message.

## Escalation

- Blocked > {threshold}: coordinator reassigns or resequences
- Two rejected CONTRACT-RFCs on the same contract: coordinator convenes redesign, tracks pause at next safe point
- Gate entry criteria fail twice: gate demoted to investigation work unit, DAG amended

## Gate announcements

Coordinator posts `STATUS G{n} — OPEN` when entry criteria are met; owning tracks integrate in the plan's merge order and reply `DONE G{n}` with evidence.
