---
id: US-161
title: "Browse Subtopics Within a Channel"
slug: browse-channel-subtopics
personas: [P-002]
epic: "Interest Channels"
priority: should-have
complexity: low
tags: [channels, subtopics, browse, organization]
---

# US-161: Browse Subtopics Within a Channel

## User Story

**As a** Niche Enthusiast
**I want to** browse and filter a channel's feed by subtopic
**So that** I can focus on the specific facet of the community that interests me most right now

## Acceptance Criteria

- **Given** I am inside a channel that has subtopics defined
  **When** I select a subtopic from the navigation list
  **Then** the feed updates to show only posts tagged with that subtopic

- **Given** I am viewing a subtopic feed
  **When** I return to the channel root
  **Then** the feed returns to showing all subtopics interleaved

## Notes
The active subtopic selection should persist during my session. Posts not assigned to any subtopic by their author appear only in the default "General" subtopic view.
