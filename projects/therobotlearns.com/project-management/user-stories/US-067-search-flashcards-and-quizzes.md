---
id: US-067
title: "Search Flashcards and Quizzes by Topic"
slug: search-flashcards-and-quizzes
personas: [P-002, P-005]
epic: "Search & Discovery"
priority: should-have
complexity: low
tags: [search, flashcards, quizzes]
---

# US-067: Search Flashcards and Quizzes by Topic

## User Story

**As a** mid-level developer upskilling in a new area
**I want to** search my flashcard decks and quizzes by topic
**So that** I can jump straight to practice material instead of digging through the flashcard deck index by hand

## Acceptance Criteria

- **Given** flashcard decks tagged with various topics
  **When** I search by a topic keyword
  **Then** matching decks are returned along with their card counts and last-reviewed date

- **Given** quizzes exist covering the same topic as a search
  **When** the search runs
  **Then** both matching flashcard decks and matching quizzes are returned, clearly labeled by type

- **Given** I'm a career-switcher junior dev unfamiliar with exact terminology
  **When** my search term is a partial or approximate match to a topic name
  **Then** reasonably close topics are still surfaced rather than requiring an exact string match

- **Given** a topic search returns no flashcards or quizzes
  **When** results are shown
  **Then** I'm told none exist yet for that topic, rather than the command failing silently

## Notes
Complements full-text article search ([[US-066]]) but scoped to practice content rather than reading content.
