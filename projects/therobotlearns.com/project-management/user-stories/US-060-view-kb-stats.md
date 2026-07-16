---
id: US-060
title: "View KB Stats and Growth Over Time"
slug: view-kb-stats
personas: [P-001, P-003, P-004]
epic: "KB Maintenance"
priority: should-have
complexity: medium
tags: [stats, dashboard, cli]
---

# US-060: View KB Stats and Growth Over Time

## User Story

**As a** staff backend engineer who wants visibility into what I know
**I want to** see stats on my KB — article counts, flashcard deck sizes, topic coverage, and growth over time
**So that** I can gauge how my knowledge base is developing without reading every file

## Acceptance Criteria

- **Given** my KB has articles, flashcard decks, quizzes, and simulations accumulated over months
  **When** I run the stats command
  **Then** I see counts per content type, plus a breakdown of articles by topic/tag

- **Given** session logs exist with timestamps
  **When** I request the growth-over-time view
  **Then** I see a trend (e.g., articles added per week/month) rather than only a current-state snapshot

- **Given** I'm an SRE tracking coverage across multiple tools and domains
  **When** I filter stats by tag or category
  **Then** the counts and coverage numbers update to reflect only that filtered subset

- **Given** the stats command is run on an empty or newly-initialized KB
  **When** it completes
  **Then** it reports zero counts clearly instead of erroring

## Notes
Output should support both a human-readable summary and a machine-readable (JSON) mode for scripting.
