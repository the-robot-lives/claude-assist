---
id: US-443
title: "Show character count and limit in the composer"
slug: character-limit-indicator
personas: [P-009]
epic: "Posting & Content Creation"
priority: must-have
complexity: low
tags: [compose, character-limit, ux, feedback]
---

# US-443: Show Character Count and Limit in the Composer

## User Story

**As a** Creator
**I want to** see how many characters I have used and how many remain
**So that** I can keep my post within the allowed limit without guessing

## Acceptance Criteria

- **Given** I am composing a post
  **When** the composer is open
  **Then** a character counter shows remaining characters (e.g., "720 / 1000")

- **Given** I exceed 90% of the limit
  **When** the counter updates
  **Then** it turns amber; at 100% it turns red and the Publish button is disabled

## Notes
Character limit is 1000 for standard accounts, 5000 for Creator-tier accounts.
