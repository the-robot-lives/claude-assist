---
id: US-251
title: "View First Swipe Card"
slug: view-first-swipe-card
personas: [P-003]
epic: "Swipe-to-Match"
priority: must-have
complexity: medium
tags: [swipe-ui, onboarding, card-layout]
---

# US-251: View First Swipe Card

## User Story

**As a** Social Connector (P-003)
**I want to** see a swipe card for a user who shares one of my interests
**So that** I can quickly evaluate whether to connect with them

## Acceptance Criteria

- **Given** I have at least one interest set on my profile
  **When** I open the Swipe-to-Match lane
  **Then** I see a card showing the candidate's display name, avatar, and the interest(s) we share

- **Given** the swipe lane is open
  **When** the card loads
  **Then** swipe-right, swipe-left, and skip controls are visible and labeled

## Notes
Card must not expose email, phone, or any direct-contact field.
