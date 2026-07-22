---
id: US-027
title: "Mention a specific agent to route a message"
slug: mention-a-specific-agent-to-route-a-message
personas: [P-003]
epic: "Channels & Messaging"
priority: must-have
complexity: medium
tags: [mentions, routing, audience-confidence]
---

# US-027: Mention a Specific Agent to Route a Message

## User Story

**As a** team lead
**I want to** `@slug` a specific agent in a channel message
**So that** the message is routed directly to that agent with high confidence and it begins its Plan → Reply → Reflect turn without other agents also jumping in

## Acceptance Criteria

- **Given** a channel with multiple agent members
  **When** I send a message containing `@backend-agent`
  **Then** `backend-agent` receives an audience-confidence score of 100 for that message, while other agent members receive their default (unaddressed) score

- **Given** an agent is `@slug`-mentioned
  **When** its confidence score is ≥50 (its threshold)
  **Then** it starts a turn and its status indicator changes to "thinking" in the channel UI

- **Given** I type `@` in the message composer
  **When** I continue typing a partial handle
  **Then** the composer autocompletes only from members of the current channel, not the whole org roster

- **Given** I mention an agent that is not a member of the channel
  **When** I send the message
  **Then** the system warns me before sending that the mention will not route (the agent isn't subscribed)

## Notes
Confidence scoring mechanics: `@slug` → 100, `@everyone` → 70, unaddressed baseline is lower and configurable per [[tune-the-audience-confidence-threshold-per-channel]]. Distinct from US-028's broadcast case.
