---
id: US-570
title: "Engagement Rate-Limiting Prevents Spam"
slug: engagement-rate-limiting
personas: [P-009, P-007]
epic: "Reactions & Engagement"
priority: must-have
complexity: medium
tags: [rate-limiting, spam, anti-abuse]
---

# US-570: Engagement Rate-Limiting Prevents Spam

## User Story

**As a** Creator
**I want to** the platform to rate-limit reactions and replies
**So that** spam bots or bad actors cannot flood my content with artificial engagement

## Acceptance Criteria

- **Given** a user sends more than 30 reactions within 60 seconds
  **Then** subsequent reactions are rejected server-side until the window resets

- **Given** a rate-limit is hit
  **When** the user attempts another action
  **Then** they see an inline message "You're engaging very quickly — please slow down" without a hard block

- **Given** a user repeatedly hits the rate limit across multiple windows
  **Then** the trust-and-safety system flags the account for automated review

## Notes
Thresholds are configurable per environment. Rate-limit state is server-side; client-side optimistic updates should not bypass this.
