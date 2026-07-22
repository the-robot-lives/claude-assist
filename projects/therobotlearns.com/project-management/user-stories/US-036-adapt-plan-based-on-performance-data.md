---
id: US-036
title: "Adapt My Plan Based on Performance Data"
slug: adapt-plan-based-on-performance-data
personas: [P-002, P-003]
epic: "Learning Plans"
priority: should-have
complexity: high
tags: [learning-plan, adaptive, performance-data]
---

# US-036: Adapt My Plan Based on Performance Data

## User Story

**As a** learner following a plan
**I want to** have the plan adapt based on my quiz and flashcard performance data
**So that** it automatically slows down on topics I'm struggling with and speeds past ones I've already mastered

## Acceptance Criteria

- **Given** performance data shows consistently low quiz accuracy on a plan topic
  **When** the plan is re-evaluated
  **Then** extra review milestones for that topic are inserted automatically

- **Given** flashcard SM-2 intervals show a topic is well-retained
  **When** the plan is re-evaluated
  **Then** remaining milestones for that topic are shortened or marked as already satisfied

- **Given** the plan adapts automatically
  **When** changes are made
  **Then** the learner is shown a summary of what changed and why before the updated plan is finalized

## Notes
