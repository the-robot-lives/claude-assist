---
id: US-915
title: "Real-Time Chat Delivery Under High Concurrent Load"
slug: realtime-message-delivery-under-load
personas: [P-007]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: high
tags: [real-time, websocket, chat, scale, load]
---

# US-915: Real-Time Chat Delivery Under High Concurrent Load

## User Story

**As a** channel moderator running a large active community
**I want to** have chat messages delivered to all members in real time even during peak activity
**So that** conversations don't stall when hundreds of users are posting simultaneously

## Acceptance Criteria

- **Given** a channel has 500 concurrent active users
  **When** a member sends a message
  **Then** 95% of connected members receive the message within 500 ms

- **Given** the WebSocket server is under load
  **When** message queue depth exceeds 1,000 messages
  **Then** the server sheds non-critical background events first and preserves chat message delivery priority

## Notes
Use fan-out via pub/sub (Redis Streams or similar). Prioritize chat over feed update events. Horizontal WebSocket scaling via sticky sessions or shared pub/sub.
