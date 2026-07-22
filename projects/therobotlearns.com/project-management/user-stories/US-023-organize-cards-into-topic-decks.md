---
id: US-023
title: "Organize Cards Into Topic Decks"
slug: organize-cards-into-topic-decks
personas: [P-002, P-006]
epic: "Flashcards & Spaced Repetition"
priority: must-have
complexity: low
tags: [flashcards, deck-index, organization]
---

# US-023: Organize Cards Into Topic Decks

## User Story

**As a** learner accumulating flashcards across many topics
**I want to** have cards organized into topic decks tracked in a central deck index
**So that** related cards stay grouped and I can navigate my growing collection

## Acceptance Criteria

- **Given** a new flashcard is generated
  **When** it's saved
  **Then** it's assigned to an existing deck matching its topic or a new deck is created if none matches

- **Given** the deck index
  **When** I list decks
  **Then** each entry shows deck name, topic, and card count

- **Given** I want to move a card to a different deck
  **When** I reassign it
  **Then** the deck index updates both decks' card counts accordingly

- **Given** a deck ends up empty after cards are moved out
  **When** I view the deck index
  **Then** the empty deck is flagged so I can prune it

## Notes
