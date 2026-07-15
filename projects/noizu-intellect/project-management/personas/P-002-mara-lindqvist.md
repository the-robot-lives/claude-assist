---
id: P-002
name: "Mara Lindqvist"
slug: mara-lindqvist
archetype: "Agent designer / prompt engineer"
segment: primary
tags: [agent-design, prompts, cognition, tuning]
---

# P-002: Mara Lindqvist

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 29 |
| Occupation | Prompt engineer / AI experience designer at a mid-size SaaS |
| Location | Stockholm, Sweden |
| Tech comfort | High |

## Bio
Mara designs the "cast" — she authors agent identities, purposes, and self-images, and tunes how agents remember, form opinions, and reflect. She treats agent definitions like living documents that need versioning, diffing, and A/B comparison.

## Goals
- Author agents with distinct purpose, identity, specification, and self-image that stay in character over long horizons
- Inspect and edit what an agent has memorized, observed, and concluded about others
- Compare two versions of an agent prompt against the same scenario before promoting one

## Frustrations
- Prompt changes that silently regress behavior with no diff trail
- Black-box memory: not being able to see *why* an agent responded the way it did
- Reflection loops that pollute agent memory with junk

## Behaviors
- Iterates in small steps, keeps meticulous change logs
- Reads raw model output (plan/reflect passes) when debugging persona drift
- Maintains a personal library of proven agent templates

## Job to Be Done
> "When an agent's behavior drifts or a new role is needed, I want to author and version its identity and cognition precisely, so the team's agents remain reliable, in-character specialists."

## Relationship to Product
Heavy user of agent creation, versioned prompt editing, cognition-table inspection (memories, observations, opinions, mind-readings), and side-by-side fork comparison for prompt changes.

## Scenarios
- **Scenario 1:** Persona surgery — Mara notices the reviewer agent has become sycophantic, inspects its recent reflection patches, prunes two bad memories, and tightens its purpose prompt with a versioned edit.
- **Scenario 2:** Template promotion — Mara forks a channel at a tag, runs old vs. new agent prompt down both forks, and promotes the better one to the org template library.
