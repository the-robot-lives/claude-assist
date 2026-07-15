---
id: US-016
title: "Inspect an agent's memories, observations, opinions, and mind-readings"
slug: inspect-an-agents-cognition-records
personas: [P-002, P-007]
epic: "Agents & Cognition"
priority: must-have
complexity: medium
tags: [cognition, memory, observability]
---

# US-016: Inspect an Agent's Memories, Observations, Opinions, and Mind-Readings

## User Story

**As a** agent designer/prompt engineer
**I want to** browse an agent's long-term memories, observations, opinions, and mind-readings as separate, filterable lists
**So that** I can understand why the agent is behaving the way it is and diagnose drift in its cognition

## Acceptance Criteria

- **Given** an agent has accumulated cognition records over multiple turns
  **When** I open its cognition inspector
  **Then** memories, observations, opinions, and mind-readings each display in their own labeled section with timestamp and originating turn/channel reference

- **Given** the cognition inspector is open
  **When** I filter by project, channel, or date range
  **Then** only records matching the filter are shown, so I can isolate cognition formed during a specific incident or path

- **Given** an agent has both short-term (per-path sandboxed) and long-term memory
  **When** I view the inspector during an active parallel-path run
  **Then** short-term sandboxed memories for in-flight paths are visually distinguished from committed long-term memory, since losing paths' memories are discarded

- **Given** a compliance investigator needs to trace a specific behavior
  **When** they search cognition records by keyword
  **Then** results return across all four cognition categories with links back to the source turn's Reflect pass

## Notes
Feeds directly from the Reflect pass's structured patch mechanic. This is the primary diagnostic surface for P-002; P-007 uses the same view for behavior investigation and redaction targeting (see US-017).
