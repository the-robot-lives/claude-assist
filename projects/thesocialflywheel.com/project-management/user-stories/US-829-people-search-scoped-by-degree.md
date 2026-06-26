---
id: US-829
title: "Scope People Search to Specific Degrees"
slug: people-search-scoped-by-degree
personas: [P-003]
epic: "Search & Find"
priority: must-have
complexity: medium
tags: [search, people, degree, scope]
---

# US-829: Scope People Search to Specific Degrees

## User Story

**As a** social connector
**I want to** set a maximum degree when searching people
**So that** I can discover new connections within a comfortable social distance

## Acceptance Criteria

- **Given** I open the People search filter panel
  **When** I select "Up to 3rd degree"
  **Then** results exclude people beyond 3rd degree and those with no path in my network

- **Given** I select "1st degree (Moots only)"
  **When** results load
  **Then** only confirmed mutual followers appear

## Notes
Degree scope filter defaults to "All degrees" with Out-of-Web results deprioritized.
