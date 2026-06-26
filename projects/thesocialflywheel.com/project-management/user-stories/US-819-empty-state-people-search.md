---
id: US-819
title: "Empty State for People Search"
slug: empty-state-people-search
personas: [P-008]
epic: "Search & Find"
priority: should-have
complexity: low
tags: [search, empty-state, people, accessibility]
---

# US-819: Empty State for People Search

## User Story

**As a** accessibility-first user
**I want to** see a clear, accessible empty state when people search yields no results
**So that** I know the search ran and understand why nothing was returned

## Acceptance Criteria

- **Given** I search people and a degree filter eliminates all results
  **When** the page renders
  **Then** an ARIA live region says "No people found at 2nd degree — try widening your degree filter" with a clickable control to do so

- **Given** no degree filter is active and results are empty
  **When** the empty state appears
  **Then** it links to the Swipe-to-Match lane as an alternative path to find new connections

## Notes
Distinguish between "zero results globally" and "zero results due to active filters."
