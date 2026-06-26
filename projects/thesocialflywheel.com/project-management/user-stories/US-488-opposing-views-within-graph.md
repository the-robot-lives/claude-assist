---
id: US-488
title: "Ensure Opposing-Views content is curated within my graph"
slug: opposing-views-within-graph
personas: [P-001, P-005]
epic: "Feed & Ranking"
priority: must-have
complexity: high
tags: [opposing-views, curation, graph, safety]
---

# US-488: Ensure Opposing-Views Content Is Curated Within My Graph

## User Story

**As a** bridge-builder (P-001)
**I want to** know that Opposing-Views content comes from within my 4th-degree graph
**So that** I see authentic disagreement from real connections rather than random internet content

## Acceptance Criteria

- **Given** the Opposing-Views lane is populated
  **When** I check the degree badge on any Opposing-Views post
  **Then** it shows a degree between 2nd and 4th — never "outside graph"

- **Given** a blocked user's post would qualify for Opposing-Views
  **When** the Opposing-Views lane is ranked
  **Then** that post is excluded regardless of relevance score

- **Given** I have very few 2nd–4th degree connections
  **When** insufficient Opposing-Views content exists within my graph
  **Then** the Opposing-Views slots are left empty rather than filled with random external content

## Notes
Opposing-Views curation does not use sentiment analysis or political classification; it is purely based on channel non-overlap.
