---
id: US-020
title: "Daily SM-2 Review Queue"
slug: daily-sm2-review-queue
personas: [P-002, P-001]
epic: "Flashcards & Spaced Repetition"
priority: must-have
complexity: medium
tags: [flashcards, spaced-repetition, sm-2, review-queue]
---

# US-020: Daily SM-2 Review Queue

## User Story

**As a** terminal-native daily learner
**I want to** get a daily queue of cards that are due per the SM-2 algorithm
**So that** I review only what's necessary to maintain retention without wasting time on cards not yet due

## Acceptance Criteria

- **Given** cards across multiple decks with different next-review dates
  **When** I start a review session
  **Then** only cards whose due date is today or earlier are queued

- **Given** no cards are due
  **When** I start a review session
  **Then** I'm told there's nothing due today instead of being shown an empty or confusing queue

- **Given** a review session
  **When** cards are presented
  **Then** they are ordered so overdue cards surface before cards newly due today

- **Given** I close the CLI mid-session
  **When** I relaunch it later that day
  **Then** the remaining due cards are still queued for review

## Notes
