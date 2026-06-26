---
id: US-496
title: "Guide a brand-new user through an empty feed"
slug: new-user-empty-feed-onboarding
personas: [P-004, P-010]
epic: "Feed & Ranking"
priority: must-have
complexity: medium
tags: [onboarding, empty-state, new-user, feed]
---

# US-496: Guide a Brand-New User Through an Empty Feed

## User Story

**As a** cautious newcomer (P-004)
**I want to** see a friendly onboarding experience when my feed is empty on first sign-up
**So that** I understand how to build my network and don't feel like the app is broken

## Acceptance Criteria

- **Given** I have just completed sign-up with zero mutuals and zero channel subscriptions
  **When** I open the home feed for the first time
  **Then** an onboarding checklist appears: "Add 3 interests → Find your first moot → Post an intro" with completion indicators

- **Given** I complete the first onboarding step (add an interest channel)
  **When** I return to the feed
  **Then** the checklist updates to show that step complete and a sample Discovery post from that channel appears

- **Given** I have at least one mutual and one channel subscription
  **When** I return to the feed
  **Then** the onboarding checklist is dismissed and the standard blended feed appears

## Notes
The onboarding checklist is shown a maximum of once; dismissing it permanently removes it.
