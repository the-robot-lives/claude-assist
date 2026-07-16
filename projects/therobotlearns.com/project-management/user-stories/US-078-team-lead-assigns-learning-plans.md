---
id: US-078
title: "Team Lead Assigns Learning Plans to Team Members"
slug: team-lead-assigns-learning-plans
personas: [P-004, P-002]
epic: "Collaboration & Cloud"
priority: could-have
complexity: medium
tags: [cloud, team, learning-plans, future]
---

# US-078: Team Lead Assigns Learning Plans to Team Members

## User Story

**As a** engineering team lead
**I want to** assign a learning plan to one or more team members from the cloud
**So that** I can direct the team's skill development toward shared goals

## Acceptance Criteria

- **Given** I am a team lead with a team KB set up
  **When** I assign a learning plan to a team member
  **Then** the plan appears in that member's local robot-learns as an assigned plan, distinguishable from self-created plans

- **Given** a plan is assigned to me
  **When** I sync locally
  **Then** I can accept, defer, or decline the assignment, and my choice is reflected back to the team lead's dashboard (US-079)

- **Given** I accept an assigned plan
  **When** I make progress through sessions, quizzes, or flashcards
  **Then** progress is tracked against the assigned plan the same way self-created plans are tracked

## Notes
Future cloud scope, depends on US-076 and US-077. Declining an assignment must not be punitive or block local usage.
