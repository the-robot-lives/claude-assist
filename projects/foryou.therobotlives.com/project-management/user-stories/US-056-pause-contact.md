---
id: US-056
title: "Pause all contact temporarily"
slug: pause-contact
personas: [P-001]
epic: "Contact Preferences"
priority: could-have
complexity: low
tags: [preferences, snooze, pause]
---

# US-056: Pause all contact temporarily

## User Story

**As a** subscriber
**I want to** snooze all contact for a period without unsubscribing
**So that** I can take a break and resume later

## Acceptance Criteria

- **Given** I have active subscriptions
  **When** I set a pause until a chosen date
  **Then** no messages are sent until the pause ends
- **Given** a pause is active
  **When** the end date passes
  **Then** contact resumes at my prior preferences
- **Given** I am paused
  **When** I choose to resume early
  **Then** the pause is lifted immediately

## Notes
Distinct from unsubscribe; retains subscription and settings.
