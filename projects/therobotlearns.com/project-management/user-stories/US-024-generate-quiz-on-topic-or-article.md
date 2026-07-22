---
id: US-024
title: "Generate a Quiz on a Topic or Article"
slug: generate-quiz-on-topic-or-article
personas: [P-002, P-005]
epic: "Quizzes"
priority: must-have
complexity: medium
tags: [quiz, agent, knowledge-base]
---

# US-024: Generate a Quiz on a Topic or Article

## User Story

**As a** mid-level dev preparing for certs and interviews
**I want to** generate a quiz on a topic or KB article via /quiz
**So that** I can test my understanding beyond simple recall

## Acceptance Criteria

- **Given** a topic name or KB article path
  **When** I run /quiz
  **Then** the quiz-generator agent produces a quiz covering that content's key concepts

- **Given** the generated quiz
  **When** it's created
  **Then** it conforms to the quiz YAML schema and is saved for later attempts

- **Given** my profile records a calibrated expertise level for the topic
  **When** the quiz is generated
  **Then** question difficulty is weighted toward that level

- **Given** the source content is too thin to support a full quiz
  **When** I run /quiz
  **Then** the agent tells me so instead of generating low-quality filler questions

## Notes
