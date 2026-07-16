---
id: US-004
title: "Auto-Save Query Answers to the KB"
slug: auto-save-query-answers-to-kb
personas: [P-001, P-002]
epic: "Calibrated Q&A"
priority: must-have
complexity: medium
tags: [auto-save, knowledge-article, query]
---

# US-004: Auto-Save Query Answers to the KB

## User Story

**As a** daily terminal-native learner
**I want to** have each `/query` answer automatically saved as a knowledge article in my KB
**So that** my knowledge base grows without any manual curation effort

## Acceptance Criteria

- **Given** I run `/query` and receive an answer
  **When** the response completes
  **Then** a new knowledge article is written to the KB without requiring an explicit save command

- **Given** the same or a near-duplicate question was already answered and saved
  **When** I run `/query` again
  **Then** the system updates or links to the existing article rather than creating a near-duplicate

- **Given** a query answer is saved
  **When** I inspect the KB
  **Then** the article file conforms to the knowledge-article YAML schema

- **Given** I want to opt out for a single sensitive query
  **When** I pass a no-save flag to `/query`
  **Then** no article is written for that answer

## Notes
Duplicate detection can be a fuzzy match on topic/title; exact dedup logic is an implementation detail for later stories.
