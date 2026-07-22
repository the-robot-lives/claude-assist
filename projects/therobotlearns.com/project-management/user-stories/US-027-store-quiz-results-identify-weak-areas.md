---
id: US-027
title: "Store Quiz Results and Identify Weak Areas"
slug: store-quiz-results-identify-weak-areas
personas: [P-002, P-004]
epic: "Quizzes"
priority: must-have
complexity: medium
tags: [quiz, results, analytics]
---

# US-027: Store Quiz Results and Identify Weak Areas

## User Story

**As a** learner tracking my progress
**I want to** have my quiz results stored and analyzed for weak areas
**So that** I know which topics need more attention

## Acceptance Criteria

- **Given** I complete a quiz
  **When** results are saved
  **Then** each question's outcome is recorded with its topic tag and timestamp

- **Given** enough quiz history exists for a topic
  **When** I request a weak-areas summary
  **Then** topics with below-threshold accuracy are surfaced and ranked

- **Given** a team lead reviewing aggregate trends for their own learning
  **When** they view results over time
  **Then** they can see accuracy trending up or down per topic across sessions

## Notes
