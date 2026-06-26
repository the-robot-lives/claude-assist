---
id: US-507
title: "View Another User's Online Status"
slug: view-online-status
personas: [P-001]
epic: "Chat & Real-time Messaging"
priority: should-have
complexity: low
tags: [presence, online-status, direct-messages]
---

# US-507: View Another User's Online Status

## User Story

**As a** Bridge-Builder (P-001)
**I want to** see whether a mutual is currently online, recently active, or offline
**So that** I can gauge when to expect a reply before starting a conversation

## Acceptance Criteria

- **Given** I open a DM thread with a mutual
  **When** the thread header renders
  **Then** a presence badge shows "Online," "Active [N] min ago," or "Offline" based on their last activity

- **Given** a mutual has set their status to "Invisible"
  **When** I view their profile or DM header
  **Then** they always appear as "Offline" regardless of actual activity

## Notes
Presence data should not be surfaced to non-mutuals.
