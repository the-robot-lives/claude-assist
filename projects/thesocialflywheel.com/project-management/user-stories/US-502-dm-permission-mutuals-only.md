---
id: US-502
title: "DM Permission Mutuals Only"
slug: dm-permission-mutuals-only
personas: [P-004]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: low
tags: [direct-messages, permissions, safety, mutuals]
---

# US-502: DM Permission Mutuals Only

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** know that only my mutuals can send me direct messages
**So that** I do not receive unsolicited messages from strangers

## Acceptance Criteria

- **Given** a user who is not my mutual attempts to initiate a DM
  **When** they try to open a message thread with me
  **Then** the "Message" action is hidden or disabled and no thread is created

- **Given** I receive a DM
  **When** I check the sender
  **Then** the sender is always confirmed to be one of my current mutuals

## Notes
Swipe-to-Match connections that have not yet reciprocated cannot DM. Opposing-view lane users are always blocked from DMing regardless of mutual status.
