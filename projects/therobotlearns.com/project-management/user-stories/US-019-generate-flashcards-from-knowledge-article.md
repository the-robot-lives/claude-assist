---
id: US-019
title: "Generate Flashcards From a Knowledge Article"
slug: generate-flashcards-from-knowledge-article
personas: [P-002, P-005]
epic: "Flashcards & Spaced Repetition"
priority: must-have
complexity: medium
tags: [flashcards, agent, knowledge-base]
---

# US-019: Generate Flashcards From a Knowledge Article

## User Story

**As a** mid-level dev upskilling for certs/interviews
**I want to** generate flashcards from a KB article via /flashcard
**So that** I can turn what I just learned into spaced-repetition practice without hand-authoring cards

## Acceptance Criteria

- **Given** a KB article exists in my local knowledge base
  **When** I run /flashcard against that article
  **Then** the flashcard-generator agent produces a set of question/answer cards covering the article's key concepts

- **Given** the generated cards
  **When** I review them before saving
  **Then** each card is tagged with its source article and topic

- **Given** I accept the generated deck
  **When** the command completes
  **Then** the cards are added to the deck index and scheduled for initial SM-2 review

- **Given** an article is too short or lacks substantive content
  **When** I run /flashcard on it
  **Then** the agent tells me it could not generate meaningful cards rather than fabricating filler

## Notes
