---
id: US-084
title: "Search across channels, messages, agents, and runs"
slug: search-across-channels-messages-agents-and-runs
personas: [P-001, P-005]
epic: "Search & Discovery"
priority: must-have
complexity: high
tags: [search, global-search, discoverability]
---

# US-084: Search Across Channels, Messages, Agents, and Runs

## User Story

**As a** solo staff engineer (Devon Reyes) juggling many concurrent projects, channels, and parallel-path runs
**I want to** run a single global search that returns matches across channels, messages, agent definitions, and path-execution runs
**So that** I can find what I'm looking for without knowing in advance which entity type it lives in

## Acceptance Criteria

- **Given** a search query typed into the global search box
  **When** results are returned
  **Then** they are grouped by entity type (channels, messages, agents, runs) with a relevance-ranked preview line for each hit, and each result links directly to the source record

- **Given** a query that matches text inside a message body, an agent's profile prompt, or a run's plan description
  **When** search executes
  **Then** matches are found regardless of which versioned-content field the text lives in, and the result shows which field matched

- **Given** the searching user is not a member of a channel or does not have visibility into a given project
  **When** search runs
  **Then** results are scoped to entities the user has access to — no cross-project or cross-membership leakage

- **Given** a query with zero matches
  **When** search executes
  **Then** the UI shows an explicit empty state per entity type rather than an ambiguous blank screen

## Notes
This is the umbrella "quick find" search; semantic/vector search over message history ([[US-085]]) is a distinct, deeper capability layered on top. Provenance lookup ([[US-089]]) is the natural next step once a message result is opened.
