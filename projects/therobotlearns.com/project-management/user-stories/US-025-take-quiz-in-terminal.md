---
id: US-025
title: "Take a Quiz in the Terminal"
slug: take-quiz-in-terminal
personas: [P-001, P-002, P-007]
epic: "Quizzes"
priority: must-have
complexity: medium
tags: [quiz, quiz-cli, terminal, accessibility]
---

# US-025: Take a Quiz in the Terminal

## User Story

**As a** terminal-native learner
**I want to** take a generated quiz directly in the terminal using interactive prompts
**So that** I can practice without leaving my normal workflow

## Acceptance Criteria

- **Given** a saved quiz
  **When** I launch quiz-cli against it
  **Then** each question is presented one at a time using @inquirer/prompts appropriate to its type

- **Given** I answer a question
  **When** I submit it
  **Then** I receive immediate correct/incorrect feedback before moving to the next question

- **Given** the quiz-cli runs in a screen-reader-driven terminal session
  **When** prompts render
  **Then** all question text, options, and feedback are exposed as plain readable text with no reliance on color alone

- **Given** I complete all questions
  **When** the quiz ends
  **Then** a summary of score and per-question results is displayed and saved

## Notes
