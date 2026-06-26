---
id: US-252
title: "Shared Interests on Swipe Card"
slug: shared-interests-on-swipe-card
personas: [P-002]
epic: "Swipe-to-Match"
priority: must-have
complexity: low
tags: [swipe-ui, interest-matching, card-layout]
---

# US-252: Shared Interests on Swipe Card

## User Story

**As a** Niche Enthusiast (P-002)
**I want to** see exactly which interests I share with a candidate on their swipe card
**So that** I can make an informed decision before swiping right

## Acceptance Criteria

- **Given** a candidate shares two of my interests
  **When** their card is displayed
  **Then** both shared interest tags are highlighted on the card

- **Given** a candidate shares more than four interests
  **When** their card is displayed
  **Then** the top four by overlap score are shown with a "+N more" indicator

## Notes
Interest tags should link to the corresponding channel so the viewer can preview activity.
