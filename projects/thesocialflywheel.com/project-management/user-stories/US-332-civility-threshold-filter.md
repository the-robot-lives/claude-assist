---
id: US-332
title: "Civility Threshold Filters Opposing Posts"
slug: civility-threshold-filter
personas: [P-007]
epic: "Opposing-Views Lane"
priority: must-have
complexity: high
tags: [opposing-views, civility, moderation, filter, safety]
---

# US-332: Civility Threshold Filters Opposing Posts

## User Story

**As a** channel moderator
**I want to** know that only posts meeting a minimum civility score are eligible for the Opposing-Views Lane
**So that** the lane consistently presents respectful disagreement rather than hostility

## Acceptance Criteria

- **Given** a post is being evaluated for inclusion in the Opposing-Views Lane
  **When** its civility score is below the platform threshold
  **Then** it is excluded from the lane regardless of topic relevance or user settings

- **Given** a post is excluded by civility threshold
  **When** the author's post is later edited and re-scored above the threshold
  **Then** it becomes eligible for the lane on the next evaluation cycle

## Notes
Civility scoring methodology (rule-based, ML, or hybrid) is a platform implementation detail outside this story's scope.
