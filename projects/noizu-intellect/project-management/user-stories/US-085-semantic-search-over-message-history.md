---
id: US-085
title: "Run a semantic search over message history"
slug: semantic-search-over-message-history
personas: [P-005, P-002]
epic: "Search & Discovery"
priority: should-have
complexity: high
tags: [search, semantic-search, vector-store, weaviate]
---

# US-085: Run a Semantic Search Over Message History

## User Story

**As a** researcher (Dr. Elias Thorn) trying to find how a concept was discussed across many turns
**I want to** run a semantic (vector similarity) search over message history instead of an exact keyword match
**So that** I can surface conceptually related messages even when they don't share exact wording

## Acceptance Criteria

- **Given** a natural-language query describing a topic or intent
  **When** semantic search executes
  **Then** results are ranked by embedding similarity against the message vector index (Weaviate/pgvector), each showing a similarity score alongside the message preview

- **Given** a message that was edited and re-versioned
  **When** its content changes
  **Then** the vector index is updated to reflect the latest version, and stale embeddings of superseded versions are not returned as current matches

- **Given** semantic search results
  **When** the user wants to narrow further
  **Then** they can combine the semantic query with keyword and channel/date filters in the same request

- **Given** the vector store is unavailable or the index is still catching up on recent messages
  **When** a semantic search is issued
  **Then** the UI surfaces a degraded-mode notice and offers to fall back to keyword search rather than returning silently incomplete results

## Notes
Distinct from [[US-084]]'s exact/keyword global search. Depends on the vector store backing long-term agent memory being kept current with message versioning. Useful precursor to memory search across the roster ([[US-087]]), which applies the same technique to agent cognition tables instead of channel messages.
