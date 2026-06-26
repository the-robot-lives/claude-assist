---
id: US-271
title: "Swipe Card Shows Mutual Channels"
slug: swipe-card-shows-mutual-channels
personas: [P-002]
epic: "Swipe-to-Match"
priority: should-have
complexity: low
tags: [card-layout, channels, interest-matching]
---

# US-271: Swipe Card Shows Mutual Channels

## User Story

**As a** Niche Enthusiast (P-002)
**I want to** see which channels a candidate and I are both active in
**So that** I can gauge whether we actually engage with the same communities, not just share a listed interest

## Acceptance Criteria

- **Given** a candidate and I both follow and have posted in the same channel
  **When** their swipe card is shown
  **Then** those shared active channels appear as a secondary section below shared interests

- **Given** there are no shared active channels
  **When** the card is shown
  **Then** the mutual-channels section is hidden rather than showing an empty placeholder
