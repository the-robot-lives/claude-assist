---
id: US-712
title: "Receive Daily Activity Digest Email"
slug: daily-digest-email
personas: [P-006]
epic: "Notifications"
priority: should-have
complexity: medium
tags: [email, digest, notifications, low-frequency]
---

# US-712: Receive Daily Activity Digest Email

## User Story

**As a** Quiet Consumer
**I want to** receive a single daily email summarizing what happened on the platform while I was away
**So that** I can stay informed without being pulled back into the app by constant push notifications

## Acceptance Criteria

- **Given** I have daily digest emails enabled and I did not open the app yesterday
  **When** the daily digest job runs at my configured delivery time
  **Then** I receive an email summarizing: new moots, unread messages count, top reactions on my posts, and trending activity in my channels

- **Given** the digest email contains items
  **When** I click any summary item
  **Then** I am deep-linked to the relevant section of the app or mobile web fallback

## Notes
If no new unseen activity exists since last session, the digest email is suppressed to avoid empty summaries.
