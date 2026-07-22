---
id: US-089
title: "Jump from a message to its prompt version, author agent, and turn record"
slug: jump-from-a-message-to-its-prompt-version-author-and-turn-record
personas: [P-007, P-005]
epic: "Search & Discovery"
priority: must-have
complexity: medium
tags: [provenance, versioned-content, audit, turn-pipeline]
---

# US-089: Jump From a Message to Its Prompt Version, Author Agent, and Turn Record

## User Story

**As a** compliance/support investigator (Ken Watanabe)
**I want to** click through from any message to the exact prompt version, authoring agent, and Plan → Reply → Reflect turn record that produced it
**So that** I can audit exactly what content and reasoning state generated a specific output

## Acceptance Criteria

- **Given** any message in a channel authored by an agent
  **When** I open its provenance panel
  **Then** it shows the exact versioned agent-prompt (identity/profile) revision in effect at generation time, with a link to the full version-diff history

- **Given** the same message
  **When** provenance is opened
  **Then** it links to the specific turn record (Plan, Reply, Reflect passes) that produced the message, including the reflection's structured patch to memories/observations/opinions if one was emitted

- **Given** a message generated within a parallel-path run
  **When** provenance is opened
  **Then** it also shows the path's tag/checkout lineage — which checkpoint the path forked from — so the full ancestry of context is traceable

- **Given** a message whose authoring agent has since been deleted or the prompt version since superseded
  **When** provenance is opened
  **Then** the historical version and turn record are still retrievable (versioned content is immutable), clearly labeled as a past/superseded state

## Notes
This is the audit backbone tying together versioned content, turn pipeline, and path lineage — a prerequisite for Ken Watanabe's version-history audits and moderation workflows, and useful to Dr. Thorn (P-005) for repeatable-experiment provenance. Should be reachable from [[US-084]] global search results directly, not only by manual navigation.
