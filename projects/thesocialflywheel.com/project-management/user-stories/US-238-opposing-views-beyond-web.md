---
id: US-238
title: "Opposing Views Beyond Web"
slug: opposing-views-beyond-web
personas: [P-005]
epic: "Mutuals Graph & Degrees"
priority: should-have
complexity: medium
tags: [opposing-views, feed, reachability]
---

# US-238: Opposing Views Beyond Web

## User Story

**As a** Debate Seeker (P-005)
**I want to** access a dedicated Opposing-Views lane that surfaces content from users entirely outside my mutual web
**So that** I can encounter different perspectives without collapsing my curated mutual network

## Acceptance Criteria

- **Given** I navigate to the Opposing-Views lane
  **When** the feed loads
  **Then** I see posts from users who are outside my 4th-degree reachability boundary, surfaced by interest-topic overlap

- **Given** content in the Opposing-Views lane
  **When** I interact (react, comment)
  **Then** no mutual connection is implied; the interaction does not convert to a mutual or swipe match

- **Given** I view a post in the Opposing-Views lane
  **When** I tap "Why am I seeing this?"
  **Then** the explanation states "This person is outside your web — shown here for perspective"

## Notes
Opposing-Views is read-heavy; reactions and comments are permitted but mutual-request initiation from this lane may be restricted or rate-limited.
