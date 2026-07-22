---
id: US-032
title: "Request a Graded Project Assignment Matched to My Level"
slug: request-graded-project-matched-to-level
personas: [P-002, P-005]
epic: "Simulations & Projects"
priority: must-have
complexity: medium
tags: [projects, grader-agent, calibration]
---

# US-032: Request a Graded Project Assignment Matched to My Level

## User Story

**As a** learner ready to apply what I've studied
**I want to** request a graded project assignment matched to my current level
**So that** I get hands-on practice that's neither trivially easy nor overwhelming

## Acceptance Criteria

- **Given** my user profile records expertise levels per domain
  **When** I request a project assignment
  **Then** the generated project's difficulty aligns with my recorded level for that domain

- **Given** the assignment is generated
  **When** it's presented
  **Then** it includes clear requirements, constraints, and the rubric criteria it will be graded against

- **Given** I feel the assignment is miscalibrated
  **When** I request a different difficulty
  **Then** a regenerated assignment reflects the adjusted level

## Notes
