---
id: US-203
title: "Decline Mutual Request"
slug: decline-mutual-request
personas: [P-004]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: low
tags: [graph, requests, privacy]
---

# US-203: Decline Mutual Request

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** decline an incoming mutual request without the requester being notified
**So that** I can manage my network safely without creating social awkwardness

## Acceptance Criteria

- **Given** I have a pending incoming mutual request
  **When** I tap "Decline"
  **Then** the request is removed from my pending list and the requester sees no explicit rejection — their button returns to "Add Mutual" after a cooldown period

- **Given** I decline a request
  **When** the same user sends another request within the cooldown window
  **Then** the system silently drops it and they see "Request Sent" as normal (no escalation to the recipient)

## Notes
Silent decline preserves dignity for both parties. Cooldown window (suggested: 30 days) is configurable at the platform level.
