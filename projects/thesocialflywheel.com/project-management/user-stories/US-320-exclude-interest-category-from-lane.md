---
id: US-320
title: "Exclude an Interest Category from the Lane"
slug: exclude-interest-category-from-lane
personas: [P-004]
epic: "Opposing-Views Lane"
priority: must-have
complexity: medium
tags: [opposing-views, exclusion, interests, settings]
---

# US-320: Exclude an Interest Category from the Lane

## User Story

**As a** cautious newcomer
**I want to** exclude an entire interest category (e.g. Politics, Religion) from the Opposing-Views Lane
**So that** I am not shown opposing views on topics I find too sensitive regardless of which specific belief is involved

## Acceptance Criteria

- **Given** I open Opposing-Views Lane preferences
  **When** I add an interest category to the exclusion list
  **Then** all interests within that category are excluded from triggering opposing-view posts

- **Given** an interest category is excluded
  **When** I add a new interest within that category
  **Then** the new interest is also automatically excluded from the lane without additional action

## Notes
Category-level exclusion should be visually distinct from individual belief exclusion in the settings UI.
