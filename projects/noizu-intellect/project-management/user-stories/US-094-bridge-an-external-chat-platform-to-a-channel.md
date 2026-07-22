---
id: US-094
title: "Bridge an external chat platform to a channel"
slug: bridge-an-external-chat-platform-to-a-channel
personas: [P-001, P-006]
epic: "Integration & API"
priority: could-have
complexity: high
tags: [integrations, slack, channels, inbound-bridge]
---

# US-094: Bridge an External Chat Platform to a Channel

## User Story

**As a** solo staff engineer
**I want to** connect a Slack workspace channel to a Noizu Intellect channel so messages flow both directions
**So that** I can @-mention agents and trigger parallel-path runs from Slack, where my team already lives, without making everyone adopt a new app

## Acceptance Criteria

- **Given** I install the Slack integration and authorize it for a workspace channel
  **When** I map that Slack channel to a Noizu Intellect channel
  **Then** the bridge is created as an external-type channel member per the channel-type mechanic, and a confirmation message posts on both sides

- **Given** a message is posted in the bridged Slack channel
  **When** it arrives via the inbound webhook
  **Then** it is ingested into the mapped internal channel's durable inbox with the Slack author preserved as a polymorphic human member, and audience-confidence routing applies normally (`@agent-slug` → 100, `@everyone` → 70)

- **Given** an agent replies or a path-pick summary is posted in the internal channel
  **When** the reply is generated
  **Then** it is relayed back to the Slack channel as a message from the bridge integration, attributed to the originating agent by name

- **Given** the Slack bridge loses connectivity or the bot token is revoked
  **When** delivery in either direction fails
  **Then** the bridge is marked degraded, an admin alert fires (reusing the health-alert path from [[US-079]]), and messages are queued for redelivery rather than silently dropped where the transport allows it

## Notes
Scoped to inbound bridging for one external platform as a could-have — full bidirectional parity (threads, reactions, file attachments) is likely out of scope for v1 and worth flagging as such. This is the first integration surface that has to reconcile an external identity model with the polymorphic human/agent channel membership mechanic.
