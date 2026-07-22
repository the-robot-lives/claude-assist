---
id: US-069
title: "Search agent memories with semantic vector search"
slug: search-agent-memories-with-semantic-vector-search
personas: [P-002, P-005]
epic: "Memory & Knowledge"
priority: must-have
complexity: medium
tags: [memory, vector-search, weaviate, pgvector]
---

# US-069: Search Agent Memories With Semantic Vector Search

## User Story

**As an** agent designer (Mara Lindqvist) debugging why an agent behaved a certain way
**I want to** run a semantic search over an agent's long-term memory store
**So that** I can find relevant memories by meaning rather than needing to know the exact wording or date they were recorded

## Acceptance Criteria

- **Given** an agent with long-term memories stored in the vector store (Weaviate/pgvector)
  **When** I enter a natural-language query
  **Then** I receive a ranked list of memory records by semantic similarity, each showing its content, source (direct observation vs. distilled), and originating run/conversation reference

- **Given** a search scoped to a single agent
  **When** I optionally broaden the scope to all agents in a project
  **Then** results are still grouped/labeled by owning agent so I don't mistake one agent's memory for another's

- **Given** a researcher (Dr. Elias Thorn) querying memories via the API rather than the UI
  **When** they call the semantic search endpoint
  **Then** it returns structured results (score, vector distance, memory record) suitable for programmatic analysis

## Notes
Must respect cross-project memory isolation ([[US-073]]) — a search must never surface another project's memories even by semantic accident. Underpins provenance inspection ([[US-070]]).
