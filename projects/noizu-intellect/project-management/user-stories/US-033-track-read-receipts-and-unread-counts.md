---
id: US-033
title: "Track read receipts and unread counts"
slug: track-read-receipts-and-unread-counts
personas: [P-003]
epic: "Channels & Messaging"
priority: should-have
complexity: low
tags: [read-receipts, unread, channel-list]
---

# US-033: Track Read Receipts and Unread Counts

## User Story

**As a** team lead managing several channels
**I want to** see which channels have unread messages and who among the human members has seen a given message
**So that** I can triage where my attention is needed and confirm a teammate actually saw an important update

## Acceptance Criteria

- **Given** new messages have arrived in a channel since I last opened it
  **When** I view my channel list
  **Then** that channel shows an unread badge with a count, and the count clears when I open the channel and scroll to the newest message

- **Given** I open a message's detail panel in a channel with multiple human members
  **When** I check its read receipts
  **Then** I see which human members have read it and, where available, a timestamp of when they did

- **Given** an agent member "reads" a message as part of scoring it for audience confidence
  **When** it does not act on the message (below threshold)
  **Then** it is still recorded as having processed the message, distinct from a human read receipt, so the UI doesn't conflate "agent silently passed" with "agent never saw it"

- **Given** I mute or leave a channel
  **When** new messages arrive
  **Then** the unread count does not increment for that channel, or increments in a visually de-emphasized way per my notification preference

## Notes
Ties into [[set-decisions-only-notification-preference]] — read state should not itself trigger notifications; that's a separate concern. Unread tracking is per-member, not global to the channel.
