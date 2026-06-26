---
id: US-155
title: "Leave a Channel"
slug: leave-channel
personas: [P-006]
epic: "Interest Channels"
priority: must-have
complexity: low
tags: [channels, leave, membership]
---

# US-155: Leave a Channel

## User Story

**As a** Quiet Consumer
**I want to** leave a channel I no longer find relevant
**So that** its posts stop appearing in my feed without requiring me to block or report anything

## Acceptance Criteria

- **Given** I am a member of a channel
  **When** I open the channel's settings menu and select "Leave Channel"
  **Then** I am shown a brief confirmation dialog before my membership is removed

- **Given** I confirm leaving a channel
  **When** the action completes
  **Then** the channel no longer appears in my joined channels list and its posts are removed from my feed

## Notes
Leaving does not delete the user's past posts within the channel. If the user is the channel owner, leaving requires transferring ownership first (US-178).
