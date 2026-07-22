---
id: P-006
name: "Nadia Volkov"
slug: nadia-volkov
archetype: "Self-hosting platform admin / SRE"
segment: tertiary
tags: [admin, sre, self-hosted, cost-control, providers]
---

# P-006: Nadia Volkov

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 38 |
| Occupation | Site reliability engineer / platform admin |
| Location | Warsaw, Poland |
| Tech comfort | High |

## Bio
Nadia operates the self-hosted deployment for her company: Postgres/Timescale, Redis, vector store, and a stack of LLM provider keys with very real bills attached. She answers for uptime, spend, and who can do what.

## Goals
- Configure model providers, API keys, and per-model routing/fallbacks in one place
- Enforce org/project quotas and see token spend per agent, path run, and user
- Keep the system healthy: queues draining, agents responsive, storage bounded

## Frustrations
- A runaway parallel fan-out burning a month's budget in an afternoon
- No visibility into which subsystem (ingestion, path execution, memory) is backed up
- Secrets scattered across config files

## Behaviors
- Watches dashboards and alerts; automates everything repeatable
- Sets hard limits first, loosens later
- Tests upgrades on a staging org before production

## Job to Be Done
> "When teams run agent workloads on infrastructure I operate, I want centralized control over providers, budgets, and access, so costs and risk stay bounded while users stay unblocked."

## Relationship to Product
Owns org administration: member roles, provider/model config, quotas and spend reporting, queue/agent health monitoring, and data retention settings.

## Scenarios
- **Scenario 1:** Budget guardrail — Nadia caps parallel paths at 5 per request org-wide and sets a monthly token budget per project with alerts at 80%.
- **Scenario 2:** Provider outage — the primary LLM provider degrades; Nadia flips routing to the fallback model tier and watches queued turns drain.
