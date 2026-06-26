---
id: US-270
title: "Interest Expiry After No Response"
slug: interest-expiry-after-no-response
personas: [P-001]
epic: "Swipe-to-Match"
priority: must-have
complexity: medium
tags: [expiry, inbox, housekeeping, time-based]
---

# US-270: Interest Expiry After No Response

## User Story

**As a** Bridge-Builder (P-001)
**I want to** have unanswered interest signals automatically expire after 14 days
**So that** my inbox stays clean and senders are not left in indefinite limbo

## Acceptance Criteria

- **Given** a pending interest has not been accepted or rejected for 14 days
  **When** the nightly expiry job runs
  **Then** the interest is marked expired, removed from the recipient's inbox, and the sender's post access is revoked

- **Given** an interest has expired
  **When** the original sender views their outgoing interests
  **Then** the entry shows "Expired" status and they may choose to re-send after a 7-day cooldown
