---
id: US-259
title: "Reject Incoming Interest"
slug: reject-incoming-interest
personas: [P-001]
epic: "Swipe-to-Match"
priority: must-have
complexity: low
tags: [reject, inbox, privacy]
---

# US-259: Reject Incoming Interest

## User Story

**As a** Bridge-Builder (P-001)
**I want to** reject an incoming interest without the sender knowing why
**So that** I can maintain privacy while keeping my inbox clean

## Acceptance Criteria

- **Given** I have a pending interest in my inbox
  **When** I tap "Decline"
  **Then** the interest is removed from my inbox and the sender's access to my posts is revoked

- **Given** I decline an interest
  **When** the sender checks their outgoing interests
  **Then** the entry shows "No longer pending" without revealing that I explicitly declined

## Notes
No "you were rejected" push notification is sent to the sender.
