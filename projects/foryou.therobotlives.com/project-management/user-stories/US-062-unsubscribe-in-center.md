---
id: US-062
title: "Unsubscribe from a list in the preference center"
slug: unsubscribe-in-center
personas: [P-001]
epic: "Preference Center"
priority: must-have
complexity: low
tags: [preference-center, unsubscribe, subscriptions]
---

# US-062: Unsubscribe from a list in the preference center

## User Story

**As a** signed-in subscriber
**I want to** unsubscribe from a list directly in my dashboard
**So that** I can manage lists without hunting for an email link

## Acceptance Criteria

- **Given** an active subscription in my dashboard
  **When** I choose "Unsubscribe"
  **Then** the subscription becomes `unsubscribed` and the UI updates
- **Given** I unsubscribe
  **When** the change applies
  **Then** it is reflected consistently with token-based unsubscribe (US-042)
- **Given** I change my mind
  **When** I choose to re-subscribe
  **Then** I can re-activate per the list's opt-in mode

## Notes
