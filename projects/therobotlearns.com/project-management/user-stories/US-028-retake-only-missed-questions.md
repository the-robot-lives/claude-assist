---
id: US-028
title: "Retake Only Missed Questions"
slug: retake-only-missed-questions
personas: [P-002, P-005]
epic: "Quizzes"
priority: should-have
complexity: low
tags: [quiz, retake, weak-areas]
---

# US-028: Retake Only Missed Questions

## User Story

**As a** learner who just finished a quiz with some wrong answers
**I want to** retake only the questions I missed
**So that** I can focus my limited practice time on my actual gaps

## Acceptance Criteria

- **Given** a completed quiz attempt with at least one incorrect answer
  **When** I choose to retake missed questions
  **Then** only those questions are presented again

- **Given** I answer a previously missed question correctly on retake
  **When** the retake session ends
  **Then** the result is recorded as a distinct retake attempt without overwriting the original attempt's history

- **Given** I missed zero questions on a quiz
  **When** I try to retake missed questions
  **Then** I'm told there's nothing to retake

## Notes
