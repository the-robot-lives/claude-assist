---
id: US-033
title: "Submit a Project for Grader Agent Evaluation"
slug: submit-project-for-grader-evaluation
personas: [P-002, P-005, P-004]
epic: "Simulations & Projects"
priority: must-have
complexity: high
tags: [projects, grader-agent, rubric]
---

# US-033: Submit a Project for Grader Agent Evaluation

## User Story

**As a** learner who has completed a project assignment
**I want to** submit it and have the grader agent evaluate it against the assignment's rubric
**So that** I get objective, actionable feedback on my work

## Acceptance Criteria

- **Given** a completed project assignment
  **When** I submit it for grading
  **Then** the grader agent evaluates it against each rubric criterion and returns a per-criterion score

- **Given** the grading is complete
  **When** results are shown
  **Then** overall feedback explains specific strengths and shortfalls tied to rubric items, not just a numeric score

- **Given** my submission fails to meet a required criterion
  **When** feedback is generated
  **Then** it clearly flags that criterion as not met rather than averaging it away in an aggregate score

- **Given** a team lead wants to spot-check a team member's submission and rubric outcome
  **When** they view the graded result
  **Then** the rubric and scoring are presented in a reviewable, non-opaque format

## Notes
