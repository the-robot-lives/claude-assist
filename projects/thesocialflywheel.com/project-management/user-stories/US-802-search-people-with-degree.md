---
id: US-802
title: "Search People with Degree Badge"
slug: search-people-with-degree
personas: [P-003]
epic: "Search & Find"
priority: must-have
complexity: medium
tags: [search, people, degree, social-graph]
---

# US-802: Search People with Degree Badge

## User Story

**As a** social connector
**I want to** see each person's degree in search results
**So that** I know how closely connected they are before I reach out

## Acceptance Criteria

- **Given** I search for a name
  **When** results appear
  **Then** each person card shows a degree badge (1st, 2nd, 3rd, 4th, or Out-of-Web)

- **Given** a person is a 1st-degree mutual
  **When** I view their card
  **Then** the badge reads "Moot" instead of a numeric degree

## Notes
Degree is calculated relative to the searching user's graph in real time.
