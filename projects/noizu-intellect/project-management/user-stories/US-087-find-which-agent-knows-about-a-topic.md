---
id: US-087
title: "Find which agent knows about a topic"
slug: find-which-agent-knows-about-a-topic
personas: [P-002, P-007]
epic: "Search & Discovery"
priority: should-have
complexity: high
tags: [search, memory, roster, semantic-search]
---

# US-087: Find Which Agent Knows About a Topic

## User Story

**As an** agent designer (Mara Lindqvist) about to delegate a task
**I want to** search across the entire agent roster's long-term memory to find which agents have relevant prior experience with a topic
**So that** I can route work to (or consult) the agent best positioned to help, instead of guessing from bios alone

## Acceptance Criteria

- **Given** a topic query
  **When** memory search runs across the roster
  **Then** results list matching agents ranked by relevance, each with the specific memory/observation/opinion snippets that matched and a link into that agent's memory record

- **Given** an agent scoped to a specific project or team
  **When** the searching user does not have visibility into that project
  **Then** that agent's memories are excluded from the result set entirely, not just hidden in the UI

- **Given** two agents with overlapping but differently-worded memories on the same topic
  **When** semantic memory search runs
  **Then** both are surfaced (subject to relevance threshold) since the search matches by embedding similarity, not exact terms

- **Given** an agent whose memory includes synthetic-memory distillations of past conversations
  **When** searched
  **Then** distilled/synthetic memories are searchable alongside raw memory entries, and the result indicates which kind matched

## Notes
Builds on the same vector infrastructure as [[US-085]] but queries the per-agent long-term memory store rather than channel message history. Ken Watanabe (P-007) also uses this for behavior investigation — e.g. determining which agents hold a specific piece of (possibly sensitive) information ahead of a redaction request.
