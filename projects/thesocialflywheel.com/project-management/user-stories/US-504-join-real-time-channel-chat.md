---
id: US-504
title: "Join Real-Time Channel Chat"
slug: join-real-time-channel-chat
personas: [P-002]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: high
tags: [channel-chat, real-time, websocket]
---

# US-504: Join Real-Time Channel Chat

## User Story

**As a** Niche Enthusiast (P-002)
**I want to** enter a channel's chat room and see messages appear in real time without refreshing
**So that** I can participate in live discussions about my interest topic

## Acceptance Criteria

- **Given** I open a channel I follow
  **When** the chat tab loads
  **Then** I am connected via a live stream and new messages from other members appear without any manual refresh

- **Given** I am connected to a channel chat
  **When** my connection drops and then restores
  **Then** any messages I missed during the outage are loaded automatically so I see a complete history

## Notes
Real-time delivery target is under 300 ms end-to-end at p95 for same-region users.
