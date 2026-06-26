---
id: US-704
title: "Notify User When Someone Expresses Swipe Interest"
slug: interest-expressed-notification
personas: [P-006]
epic: "Notifications"
priority: should-have
complexity: low
tags: [swipe-to-match, notifications, discovery]
---

# US-704: Notify User When Someone Expresses Swipe Interest

## User Story

**As a** Quiet Consumer
**I want to** receive a discreet notification when someone swipes right on my profile
**So that** I can decide whether to reciprocate without feeling pressured

## Acceptance Criteria

- **Given** I have "interest received" notifications enabled
  **When** another user swipes right on my profile
  **Then** I receive a low-priority notification reading "Someone is interested in connecting — visit Discovery to see who"

- **Given** I have "interest received" notifications disabled
  **When** another user swipes right on me
  **Then** no notification is sent and the interest is recorded silently until I open the swipe lane

## Notes
Identity of the interested party is intentionally withheld until the user reciprocates, preserving the matching mechanic.
