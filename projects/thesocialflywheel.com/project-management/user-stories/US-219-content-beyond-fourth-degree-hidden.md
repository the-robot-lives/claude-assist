---
id: US-219
title: "Content Beyond Fourth Degree Hidden"
slug: content-beyond-fourth-degree-hidden
personas: [P-004]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: medium
tags: [feed, degrees, reachability]
---

# US-219: Content Beyond Fourth Degree Hidden

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** be confident that content from users with no connection path to me never appears in my main feed
**So that** my feed remains anchored in trusted social proximity

## Acceptance Criteria

- **Given** a user who is 5 or more degrees away from me (or entirely disconnected) publishes a post
  **When** my feed is built
  **Then** that post does not appear in my Mutuals lane under any condition, including interest matches

- **Given** I search for a user outside my web and view their profile
  **When** I look at their posts tab
  **Then** individual posts may be browsable via direct profile visit, but are not surfaced in my feed

## Notes
Content beyond 4th degree may still be discoverable via the Opposing-Views lane (US-238) or direct channel browsing — this story concerns the main Mutuals feed only.
