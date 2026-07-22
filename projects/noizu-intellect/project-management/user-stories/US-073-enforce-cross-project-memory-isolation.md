---
id: US-073
title: "Enforce cross-project memory isolation"
slug: enforce-cross-project-memory-isolation
personas: [P-006, P-007]
epic: "Memory & Knowledge"
priority: must-have
complexity: high
tags: [memory, isolation, security, multi-tenant]
---

# US-073: Enforce Cross-Project Memory Isolation

## User Story

**As a** self-hosting admin (Nadia Volkov) running multiple client projects on one Noizu Intellect instance
**I want to** guarantee that an agent's memory, semantic search results, and provenance records never leak across project boundaries
**So that** confidential context from one project's channels can never surface in another project's agent replies

## Acceptance Criteria

- **Given** an agent that exists in more than one project (or a differently-scoped instance of the same agent handle)
  **When** it retrieves memory for a turn's Plan pass
  **Then** only memories tagged with the current project's scope are eligible for retrieval, enforced at the query layer (not just filtered client-side)

- **Given** a semantic search request ([[US-069]]) issued from within a project
  **When** it executes against the vector store
  **Then** the project-scope filter is applied as part of the vector query itself, so no cross-project record can appear even at low similarity-threshold settings

- **Given** a compliance audit (Ken Watanabe) checking for isolation violations
  **When** they run an isolation check across all projects on the instance
  **Then** the system can produce a report confirming zero memory records are retrievable outside their owning project's scope

## Notes
This is a hard security boundary, not a UX nicety — it should be enforced in the storage/query layer (row-level scoping in Postgres, tenant-scoped Weaviate class or filter) rather than relying on application code to always remember to filter. Treat any violation as a security incident, not a bug ticket.
