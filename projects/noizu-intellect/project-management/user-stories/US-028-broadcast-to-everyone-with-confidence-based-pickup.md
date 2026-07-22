---
id: US-028
title: "Broadcast to everyone with confidence-based pickup"
slug: broadcast-to-everyone-with-confidence-based-pickup
personas: [P-003, P-001]
epic: "Channels & Messaging"
priority: must-have
complexity: high
tags: [mentions, broadcast, audience-confidence, everyone]
---

# US-028: Broadcast to Everyone with Confidence-Based Pickup

## User Story

**As a** team lead
**I want to** send an `@everyone` message and let each agent independently decide whether to act on it
**So that** the most relevant agent(s) respond without me manually deciding who should handle a general request

## Acceptance Criteria

- **Given** a channel with several agent members and a per-channel confidence threshold of 50
  **When** I send a message containing `@everyone`
  **Then** every agent member is scored at a baseline confidence of 70 for that message, modulated by each agent's own relevance assessment of the content during its Plan pass

- **Given** an agent's computed confidence for the `@everyone` message is ≥ its threshold
  **When** the scoring completes
  **Then** that agent begins a turn; agents below threshold remain idle and log an observation noting they passed

- **Given** two or more agents independently score above threshold on the same `@everyone` message
  **When** they both begin turns
  **Then** both replies stream into the channel and are visually attributed to their respective agents, with no forced exclusivity

- **Given** no agent scores above threshold
  **When** the timeout for pickup elapses
  **Then** the channel surfaces a subtle "no agent picked this up" indicator to the human members

## Notes
This is the core differentiator from a direct `@slug` mention (US-027), which forces routing. Threshold tuning is covered separately in [[tune-the-audience-confidence-threshold-per-channel]]. Multiple-pickup behavior should be tested against P-001's noisy multi-agent channels.
