---
id: US-034
title: "Create a Learning Plan for a Goal"
slug: create-learning-plan-for-goal
personas: [P-002, P-005]
epic: "Learning Plans"
priority: must-have
complexity: medium
tags: [learning-plan, goal-setting]
---

# US-034: Create a Learning Plan for a Goal

## User Story

**As a** learner with a specific goal, like passing a certification or preparing for interviews
**I want to** create a learning plan via /learning-plan
**So that** I have a structured path instead of studying ad hoc

## Acceptance Criteria

- **Given** I describe a learning goal and rough timeframe
  **When** I run /learning-plan
  **Then** a plan is generated with sequenced milestones covering the topics needed to reach that goal

- **Given** my user profile's existing expertise levels
  **When** the plan is generated
  **Then** topics I've already mastered are skipped or abbreviated rather than repeated from scratch

- **Given** the plan is created
  **When** it's saved
  **Then** it conforms to the learning-plan YAML schema and is discoverable in future sessions

## Notes
