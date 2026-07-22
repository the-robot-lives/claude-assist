---
id: US-031
title: "Watch a live-streamed agent reply"
slug: watch-a-live-streamed-agent-reply
personas: [P-003, P-008]
epic: "Channels & Messaging"
priority: should-have
complexity: medium
tags: [streaming, pubsub, accessibility, live-reply]
---

# US-031: Watch a Live-Streamed Agent Reply

## User Story

**As a** team lead (and, using a screen reader, as a blind developer)
**I want to** see an agent's reply stream token-by-token as it's generated, with a clear indicator of its current pass (Plan/Reply/Reflect)
**So that** I know the agent is actively working and can start reading its response before it finishes, rather than staring at a blank channel

## Acceptance Criteria

- **Given** an agent begins a turn after being routed a message
  **When** it enters each pipeline stage
  **Then** the channel UI shows a live stage indicator ("Planning…", "Replying…", "Reflecting…") sourced from PubSub events, updated in real time

- **Given** the agent is in its Reply pass
  **When** tokens are generated
  **Then** they appear incrementally in the channel as a streaming message bubble, distinguishable from a completed, durable message until the turn finishes

- **Given** a screen-reader user (P-008) is following a streaming reply
  **When** the stream is active
  **Then** the UI exposes the stage indicator and streaming content via ARIA live regions with a announcement rate that avoids flooding the screen reader (e.g. debounced/chunked updates, not per-token)

- **Given** the agent's turn completes
  **When** the durable message is persisted to the DB
  **Then** the streaming bubble is replaced by the final versioned message and the stage indicator clears

## Notes
Streaming is PubSub-driven per the product's live-streaming-to-UI mechanic; the durable write only happens once, at completion, to the per-channel inbox. Debounce interval for screen readers should be configurable; coordinate with [[digest-of-channel-activity]] for users who prefer summaries over live streams.
