---
id: US-094
title: "Token-frugal agent operations"
slug: token-frugal-agent-operations
personas: [P-003, P-008]
epic: "Performance & Scale"
priority: should-have
complexity: high
tags: [performance, agent, cost, tokens]
---

# US-094: Token-Frugal Agent Operations

## User Story

**As an** SRE/DevOps polymath who wants to minimize agent costs and context usage
**I want to** have KB reads and agent operations stay context-efficient with visible cost/token usage
**So that** I can work with a large KB without runaway token costs

## Acceptance Criteria

- **Given** the agent needs to read KB content
  **When** performing routine operations (quiz, review, search)
  **Then** it reads only the minimal necessary slice of the KB rather than loading the full index or content into context

- **Given** a session completes
  **When** the user checks cost transparency
  **Then** approximate token usage or cost for that session is reported

- **Given** a cost-conscious user
  **When** configuring token budgets
  **Then** the agent respects a configurable context/token ceiling for KB operations

## Notes
Cost transparency also matters to privacy-first, budget-conscious consultants (P-008) who track engagement costs closely.
