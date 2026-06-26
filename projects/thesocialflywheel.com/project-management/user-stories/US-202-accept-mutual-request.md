---
id: US-202
title: "Accept Mutual Request"
slug: accept-mutual-request
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: low
tags: [graph, requests]
---

# US-202: Accept Mutual Request

## User Story

**As a** Social Connector (P-003)
**I want to** accept an incoming mutual request from another user
**So that** we become 1st-degree mutuals and can each see each other's full posts in our feeds

## Acceptance Criteria

- **Given** I have a pending incoming mutual request
  **When** I tap "Accept" on the request notification or the pending requests list
  **Then** the connection becomes a 1st-degree mutual, the requester's posts appear unfiltered in my feed, and mine in theirs

- **Given** I accept a mutual request
  **When** the connection is established
  **Then** both users receive a confirmation notification and the requester's pending state clears
