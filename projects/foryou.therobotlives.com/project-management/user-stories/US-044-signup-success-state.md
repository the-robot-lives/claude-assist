---
id: US-044
title: "See a clear signup success state"
slug: signup-success-state
personas: [P-001, P-007]
epic: "Signups & Subscriptions"
priority: should-have
complexity: low
tags: [signup, success, confirmation, a11y]
---

# US-044: See a clear signup success state

## User Story

**As a** person who just signed up
**I want to** see a clear confirmation of what happens next
**So that** I know my submission worked

## Acceptance Criteria

- **Given** I submit a signup successfully
  **When** the response returns
  **Then** I see a success message stating next steps (e.g. "check your email")
- **Given** the List uses double opt-in
  **When** success shows
  **Then** it clearly tells me to confirm via email
- **Given** I use assistive technology
  **When** success renders
  **Then** it is announced via a live region

## Notes
