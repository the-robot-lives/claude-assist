---
id: US-022
title: "See Due-Card Counts Per Deck Before Reviewing"
slug: due-card-counts-per-deck
personas: [P-002, P-001]
epic: "Flashcards & Spaced Repetition"
priority: should-have
complexity: low
tags: [flashcards, deck-index, review-queue]
---

# US-022: See Due-Card Counts Per Deck Before Reviewing

## User Story

**As a** learner managing multiple topic decks
**I want to** see how many cards are due in each deck before starting a review
**So that** I can decide which deck to prioritize given the time I have

## Acceptance Criteria

- **Given** multiple decks exist in the deck index
  **When** I check review status
  **Then** I see a per-deck breakdown of due, upcoming, and total card counts

- **Given** a deck has zero due cards
  **When** I view the breakdown
  **Then** it's listed with a due count of zero rather than omitted

- **Given** I choose to review a specific deck
  **When** I start the session
  **Then** only that deck's due cards are queued

## Notes
