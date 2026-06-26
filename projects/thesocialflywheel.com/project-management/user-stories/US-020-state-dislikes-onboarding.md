---
id: US-020
title: "State Dislikes During Onboarding"
slug: state-dislikes-onboarding
personas: [P-006, P-004, P-001]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: low
tags: [dislikes, preferences, onboarding, ranking]
---

# US-020: State Dislikes During Onboarding

## User Story

**As a** quiet consumer
**I want to** indicate topics or content styles I dislike during onboarding
**So that** the ranking algorithm deprioritizes them in my feed without fully excluding them

## Acceptance Criteria

- **Given** I am on the preferences screen
  **When** I mark a topic as "disliked"
  **Then** it is ranked lower but not removed — I can still encounter it in the Opposing Views lane.

- **Given** I mark a content style (e.g. "memes", "long-form essays") as disliked
  **When** my feed loads
  **Then** that style is significantly deprioritized in my Mutuals lane.

## Notes
Distinguish between "exclude" (hard filter) and "dislike" (soft ranking signal) clearly in the UI copy. Dislikes are revisable at any time.
