---
id: P-003
name: "Priya Shah"
slug: ai-integrator
archetype: "AI Integrator"
segment: secondary
tags: [integration, developer, APIs]
---

# P-003: Priya Shah

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 29 |
| Occupation | Senior Software Engineer, integration lead |
| Location | Seattle, WA |
| Tech comfort | very high |

## Bio
Priya builds internal automations and toolchains. She is the person who ensures AI systems can connect to existing CRMs, ticketing, and data stores.

## Goals
- Make robot workflows reliable and testable.
- Manage model/provider switching without breaking existing behavior.
- Add observability for message, tool calls, and failures.

## Behaviors
- Uses environment-specific configs and versioning.
- Values deterministic runbooks and test fixtures.
- Wants API-centric interfaces and role boundaries.

## Job to Be Done
> When production AI work shifts, I want predictable integration points and versioned robot behavior, so I can ship quickly without regressions.

## Relationship to Product
Critical for early adopters who evaluate the system against internal developer standards.

## Scenarios
- **Provider swap:** She runs the same robot job across two LLM providers and compares outcomes in audit mode.
- **Tool outage:** She routes retries and fallback tool choices automatically without changing robot role definitions.

