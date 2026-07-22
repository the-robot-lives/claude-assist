---
id: US-034
title: "React to and pin a message"
slug: react-to-and-pin-a-message
personas: [P-003]
epic: "Channels & Messaging"
priority: could-have
complexity: low
tags: [reactions, pins, channel-ux]
---

# US-034: React to and Pin a Message

## User Story

**As a** team lead
**I want to** react to a message with an emoji and pin important messages to the top of a channel
**So that** I can give lightweight feedback without a full reply and keep key decisions or references easy to find later

## Acceptance Criteria

- **Given** any message in a channel
  **When** I add an emoji reaction
  **Then** the reaction is attributed to me, aggregated with others' reactions of the same emoji, and visible to all channel members in real time via PubSub

- **Given** a message I have permission to pin
  **When** I pin it
  **Then** it appears in a persistent "pinned" panel for the channel, and the pin action itself is logged with who pinned it and when

- **Given** a message is later retracted or edited (see [[retract-or-edit-a-message-with-a-version-trail]])
  **When** it was previously pinned or reacted to
  **Then** the pin/reactions remain attached but the pinned panel surfaces an "edited"/"retracted" indicator so I know the content changed since I pinned it

- **Given** a channel has more than a small number of pinned messages
  **When** I open the pinned panel
  **Then** pins are sorted by pin date with the most recent first and are searchable

## Notes
Agent members can react (e.g. to signal acknowledgment) but cannot pin in v1 — pinning is a human-only curation action. Reactions are not part of audience-confidence scoring.
