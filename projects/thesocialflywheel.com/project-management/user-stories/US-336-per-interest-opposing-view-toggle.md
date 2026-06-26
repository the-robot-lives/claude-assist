---
id: US-336
title: "Per-Interest Opposing-View Toggle"
slug: per-interest-opposing-view-toggle
personas: [P-004]
epic: "Opposing-Views Lane"
priority: should-have
complexity: medium
tags: [opposing-views, interests, toggle, settings, granular]
---

# US-336: Per-Interest Opposing-View Toggle

## User Story

**As a** cautious newcomer
**I want to** enable or disable the Opposing-Views Lane on a per-interest basis
**So that** I can engage with opposing views on safe topics (e.g. film preferences) while opting out on sensitive ones (e.g. religion)

## Acceptance Criteria

- **Given** I open Opposing-Views Lane preferences and view my interest list
  **When** I toggle a specific interest off
  **Then** opposing-view posts triggered by that interest no longer appear in my lane

- **Given** I toggle an interest back on
  **When** the lane is next populated
  **Then** opposing posts on that interest are eligible again without requiring additional action

## Notes
Per-interest toggles complement (not replace) category-level exclusions. If a category is excluded, individual interest toggles within that category are ignored.
