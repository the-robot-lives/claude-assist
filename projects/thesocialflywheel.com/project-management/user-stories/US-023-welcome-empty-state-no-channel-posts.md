---
id: US-023
title: "Welcome Empty State — No Channel Posts Yet"
slug: welcome-empty-state-no-channel-posts
personas: [P-006, P-004]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: low
tags: [empty-state, channel, onboarding]
---

# US-023: Welcome Empty State — No Channel Posts Yet

## User Story

**As a** quiet consumer
**I want to** a helpful empty state when I join a channel that has no recent posts from my network
**So that** I know the channel is active and understand how to engage

## Acceptance Criteria

- **Given** I join a channel whose Mutuals lane has no posts from my network
  **When** I view that lane
  **Then** I see a message explaining there is no network activity here yet, with a link to the Swipe-to-Match lane to expand my web.

- **Given** the Opposing Views lane also has no content
  **When** I view it
  **Then** I see "Check back soon — we're surfacing relevant perspectives" instead of a blank screen.

## Notes
Distinguish between "no content exists" and "content exists but none reaches your degree." Different empty state copy for each case.
