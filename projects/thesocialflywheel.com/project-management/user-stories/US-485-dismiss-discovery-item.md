---
id: US-485
title: "Dismiss a Discovery item from the feed"
slug: dismiss-discovery-item
personas: [P-006, P-004]
epic: "Feed & Ranking"
priority: should-have
complexity: low
tags: [discovery, dismiss, feed-control, personalization]
---

# US-485: Dismiss a Discovery Item from the Feed

## User Story

**As a** cautious newcomer (P-004)
**I want to** dismiss Discovery posts I'm not interested in
**So that** the Discovery algorithm learns my preferences over time

## Acceptance Criteria

- **Given** a Discovery post appears in my feed
  **When** I tap the X / "Not interested" on it
  **Then** the post collapses with a brief "Got it — we'll show fewer like this" confirmation

- **Given** I dismiss 3 Discovery posts from the same channel
  **When** the next feed refresh occurs
  **Then** that channel is suppressed from Discovery for 14 days

## Notes
Dismissal signals influence Discovery recommendations but never affect posts from my actual subscriptions.
