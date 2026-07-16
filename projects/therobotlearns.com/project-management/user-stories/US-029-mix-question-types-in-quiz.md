---
id: US-029
title: "Mix Question Types in a Quiz"
slug: mix-question-types-in-quiz
personas: [P-002, P-006]
epic: "Quizzes"
priority: should-have
complexity: medium
tags: [quiz, question-types, quiz-generator]
---

# US-029: Mix Question Types in a Quiz

## User Story

**As a** learner practicing for real-world interviews and certs
**I want to** have quizzes mix multiple choice, true/false, and short-answer questions
**So that** my practice mirrors the variety of real assessments

## Acceptance Criteria

- **Given** a quiz is generated on a sufficiently broad topic
  **When** the quiz-generator agent builds it
  **Then** it includes at least two distinct question types

- **Given** a short-answer question
  **When** I submit a free-text response
  **Then** it's evaluated for semantic correctness rather than requiring an exact string match

- **Given** a quiz mixes question types
  **When** it's rendered in either quiz-cli or the SPA
  **Then** each question type uses an input method appropriate to it (select list, boolean toggle, free text)

## Notes
