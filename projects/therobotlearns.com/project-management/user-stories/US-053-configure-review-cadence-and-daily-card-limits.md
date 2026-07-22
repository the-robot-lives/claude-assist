---
id: US-053
title: "Configure Review Cadence and Daily Card Limits"
slug: configure-review-cadence-and-daily-card-limits
personas: [P-001, P-004]
epic: "Settings & Preferences"
priority: should-have
complexity: low
tags: [settings, flashcards, sm-2, cadence]
---

# US-053: Configure Review Cadence and Daily Card Limits

## User Story

**As a** busy engineer fitting learning around a full workload
**I want to** configure my review cadence and daily flashcard limits
**So that** the SM-2 scheduler respects the amount of time I actually have each day

## Acceptance Criteria

- **Given** I open flashcard settings
  **When** I set a daily new-card limit and a daily review limit
  **Then** the SM-2 scheduler caps each day's session at those limits.

- **Given** I change my review cadence (e.g., daily vs. every other day)
  **When** the change is saved
  **Then** future due-date calculations use the new cadence going forward.

- **Given** I have cards already scheduled under the old cadence
  **When** I change the cadence
  **Then** existing due dates are not silently discarded, and I'm told how the change affects my current queue.

- **Given** I set a daily limit of zero for new cards
  **When** my next review session runs
  **Then** only previously scheduled review cards appear, with no new cards introduced.
