---
id: US-070
title: "See a helpful empty state with no subscriptions"
slug: preference-center-empty-state
personas: [P-001]
epic: "Preference Center"
priority: should-have
complexity: low
tags: [preference-center, empty-state, onboarding]
---

# US-070: See a helpful empty state with no subscriptions

## User Story

**As a** signed-in user with no subscriptions yet
**I want to** see a clear empty state
**So that** I understand the page and what to do next

## Acceptance Criteria

- **Given** I have no subscriptions or inquiries
  **When** I open the preference center
  **Then** I see an explanatory empty state rather than a blank page
- **Given** the empty state
  **When** it renders
  **Then** it explains that subscriptions appear here after I sign up on a site
- **Given** I later sign up somewhere
  **When** I return
  **Then** the new subscription appears (post-reconcile)

## Notes
