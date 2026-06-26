---
id: US-540
title: "Opposing-View DM Blocked"
slug: opposing-view-dm-blocked
personas: [P-005]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [opposing-views, dm, safety, lane-rules]
---

# US-540: Opposing-View DM Blocked

## User Story

**As a** Debate Seeker (P-005)
**I want to** understand that users in my Opposing-Views lane cannot DM me, even if they are mutuals
**So that** the debate stays in structured public channels rather than moving to private pressure

## Acceptance Criteria

- **Given** a user is categorized as an opposing-view source for me
  **When** either party tries to initiate a DM
  **Then** the Message button is absent or disabled and a tooltip reads "DMs are not available with users in your Opposing-Views lane"

- **Given** a user was previously a mutual DM contact and is then reclassified into Opposing-Views
  **When** the reclassification takes effect
  **Then** the existing DM thread is locked (compose field disabled) and neither party can send new messages

- **Given** I remove a user from my Opposing-Views lane
  **When** the lane change is saved
  **Then** normal mutual DM rules apply again and the compose field re-enables after a 24-hour cooling period

## Notes
Opposing-Views classification is bidirectional; if either party assigns the other to that lane, messaging is blocked.
