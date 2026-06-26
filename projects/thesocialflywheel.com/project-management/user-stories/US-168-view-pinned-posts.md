---
id: US-168
title: "View Pinned Posts in Channel"
slug: view-pinned-posts
personas: [P-006]
epic: "Interest Channels"
priority: should-have
complexity: low
tags: [channels, pinned-posts, feed]
---

# US-168: View Pinned Posts in Channel

## User Story

**As a** Quiet Consumer
**I want to** see pinned posts when I open a channel
**So that** I don't miss important announcements or reference materials placed there by the moderator

## Acceptance Criteria

- **Given** a channel has pinned posts and I open it
  **When** the channel feed loads
  **Then** a collapsible "Pinned" section appears above the main feed showing up to 5 pinned posts

- **Given** I have already viewed the pinned section in a previous session
  **When** I return to the channel
  **Then** the pinned section is collapsed by default unless new pins have been added since my last visit

## Notes
The collapsed/expanded state of the pinned section should persist per channel per device. New pin additions should trigger a subtle notification dot on the channel icon in my channels list.
