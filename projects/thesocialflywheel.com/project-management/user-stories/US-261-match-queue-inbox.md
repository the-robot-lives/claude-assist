---
id: US-261
title: "Match Queue Inbox"
slug: match-queue-inbox
personas: [P-003]
epic: "Swipe-to-Match"
priority: must-have
complexity: medium
tags: [inbox, queue, match-management]
---

# US-261: Match Queue Inbox

## User Story

**As a** Social Connector (P-003)
**I want to** see a dedicated inbox listing all pending incoming interests
**So that** I can review and act on them at my own pace

## Acceptance Criteria

- **Given** I have pending incoming interests
  **When** I open the Match Inbox
  **Then** each interest is shown as a card with the sender's display name, shared interests, and the date received

- **Given** the inbox has more than 20 pending items
  **When** I scroll to the bottom
  **Then** additional items load via pagination without losing my scroll position
