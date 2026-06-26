---
id: US-258
title: "Accept Interest to Become Mutuals"
slug: accept-interest-become-mutuals
personas: [P-003]
epic: "Swipe-to-Match"
priority: must-have
complexity: high
tags: [accept, mutuals, graph, core-flow]
---

# US-258: Accept Interest to Become Mutuals

## User Story

**As a** Social Connector (P-003)
**I want to** accept an incoming interest signal
**So that** we become mutuals and I gain access to their posts and moot-of-moot graph expansion

## Acceptance Criteria

- **Given** I have a pending interest in my inbox
  **When** I tap "Accept"
  **Then** both users are added to each other's mutuals graph at degree-1 and each can see the other's posts

- **Given** the mutual link is created
  **When** the ranking algorithm next runs
  **Then** the new mutual's existing connections are weighted as degree-2 candidates in my feed

- **Given** I accept an interest
  **When** the other user's app is active
  **Then** they receive a real-time notification that we are now mutuals
