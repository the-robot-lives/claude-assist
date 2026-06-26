---
id: US-288
title: "Interest Expiry Notification to Sender"
slug: interest-expiry-notification-to-sender
personas: [P-001]
epic: "Swipe-to-Match"
priority: should-have
complexity: low
tags: [expiry, notification, sender, housekeeping]
---

# US-288: Interest Expiry Notification to Sender

## User Story

**As a** Bridge-Builder (P-001)
**I want to** be notified when one of my expressed interests is about to expire
**So that** I am not caught off-guard when the recipient's window closes

## Acceptance Criteria

- **Given** I have an outgoing interest that expires in 48 hours
  **When** the 48-hour mark is reached
  **Then** I receive an in-app notification that the interest will expire soon and the recipient has not yet responded

- **Given** an outgoing interest expires
  **When** the expiry job runs
  **Then** I receive a final notification saying the interest has expired and suggesting I can re-engage after the cooldown

## Notes
Do not notify the recipient that their window is closing — only the sender.
