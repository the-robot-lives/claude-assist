---
id: US-257
title: "Recipient Sees My Posts After Right Swipe"
slug: recipient-sees-my-posts-after-right-swipe
personas: [P-001]
epic: "Swipe-to-Match"
priority: must-have
complexity: medium
tags: [visibility, one-way, feed, privacy]
---

# US-257: Recipient Sees My Posts After Right Swipe

## User Story

**As a** Bridge-Builder (P-001)
**I want to** have a pending-interest recipient be able to preview my posts
**So that** they can make an informed decision about whether to accept my interest

## Acceptance Criteria

- **Given** user A has swiped right on user B
  **When** user B opens user A's interest card in their inbox
  **Then** user B can see user A's last 10 public posts

- **Given** user A's posts are viewed by user B during evaluation
  **When** user B ultimately rejects the interest
  **Then** user B's access to user A's posts is revoked immediately

## Notes
Posts shown to pending recipient must respect the sender's channel-level privacy settings.
