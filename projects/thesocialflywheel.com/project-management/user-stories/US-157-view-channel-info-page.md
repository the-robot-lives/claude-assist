---
id: US-157
title: "View Channel Info Page"
slug: view-channel-info-page
personas: [P-006]
epic: "Interest Channels"
priority: must-have
complexity: low
tags: [channels, info, discovery]
---

# US-157: View Channel Info Page

## User Story

**As a** Quiet Consumer
**I want to** view a channel's info page before joining
**So that** I can evaluate whether the community matches my interests without committing to membership

## Acceptance Criteria

- **Given** I tap a channel card in the directory
  **When** the channel info page loads
  **Then** I see the channel name, avatar, banner, description, member count, interest tags, and a preview of recent public posts

- **Given** I am viewing a channel info page
  **When** the channel has published rules
  **Then** a "Rules" section is visible and expandable on the same page

## Notes
Non-members can view the info page but cannot see the full feed. The preview should show at most 3 recent posts to encourage joining. Member count should reflect only joined members, not pending/approval requests.
