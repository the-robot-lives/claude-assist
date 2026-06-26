---
id: US-278
title: "Block User From Swipe Card"
slug: block-user-from-swipe-card
personas: [P-004]
epic: "Swipe-to-Match"
priority: must-have
complexity: low
tags: [block, safety, abuse-resistance]
---

# US-278: Block User From Swipe Card

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** block a user directly from their swipe card
**So that** they never appear in my queue again and cannot send me interest signals in the future

## Acceptance Criteria

- **Given** I am viewing a swipe card
  **When** I select "Block" from the card overflow menu
  **Then** the card is dismissed, the user is added to my block list, and no interest is logged

- **Given** I have blocked a user via swipe card
  **When** the blocked user opens the swipe lane
  **Then** my profile does not appear in their candidate pool
