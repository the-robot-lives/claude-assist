---
id: US-384
title: "Opposing View Discovery Lane"
slug: opposing-view-discovery-lane
personas: [P-005]
epic: "Discovery Engine"
priority: should-have
complexity: high
tags: [discovery, opposing-views, debate]
---

# US-384: Opposing View Discovery Lane

## User Story

**As a** Debate Seeker
**I want to** opt into an Opposing Views discovery lane that surfaces content presenting perspectives counter to my stated positions
**So that** I can intentionally engage with challenging viewpoints in a read-only context

## Acceptance Criteria

- **Given** I enable the Opposing Views lane in my Discovery Settings
  **When** the feed loads
  **Then** a clearly labeled "Opposing Views" section appears in my feed containing content that contrasts with my interest profile, sourced only from within my 4th-degree mutuals network

- **Given** I am viewing the Opposing Views lane
  **When** I attempt to comment or react
  **Then** comment and reaction controls are disabled; only sharing to my own notes is allowed

- **Given** I encounter a post in the Opposing Views lane from an author I have blocked
  **When** the feed renders
  **Then** that post is excluded from the lane consistent with all other blocking rules

## Notes
The read-only constraint prevents adversarial engagement spirals; this lane is for exposure, not debate.
