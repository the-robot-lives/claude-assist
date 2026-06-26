---
id: US-193
title: "Archive a Channel Subtopic"
slug: archive-subtopic
personas: [P-007]
epic: "Interest Channels"
priority: could-have
complexity: low
tags: [channels, subtopics, moderation, archive]
---

# US-193: Archive a Channel Subtopic

## User Story

**As a** Channel Moderator
**I want to** archive subtopics that are no longer active
**So that** the channel navigation stays clean without permanently deleting historical content

## Acceptance Criteria

- **Given** I am in channel moderation settings with at least two active subtopics
  **When** I select a subtopic and tap "Archive"
  **Then** the subtopic is hidden from the active navigation list and new posts can no longer be assigned to it

- **Given** a subtopic is archived
  **When** a member searches within the channel or navigates to archived subtopics
  **Then** they can still read historical posts from the archived subtopic in a read-only view

## Notes
The default "General" subtopic cannot be archived. Archived subtopics do not count against the channel's 25-subtopic limit. Archived subtopics can be restored by a moderator at any time.
