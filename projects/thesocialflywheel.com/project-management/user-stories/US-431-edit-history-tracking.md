---
id: US-431
title: "View edit history of a post"
slug: edit-history-tracking
personas: [P-009]
epic: "Posting & Content Creation"
priority: could-have
complexity: medium
tags: [edit, history, transparency, post]
---

# US-431: View Edit History of a Post

## User Story

**As a** Creator
**I want to** see a changelog of edits made to my post
**So that** I have a transparent record of how my content has changed over time

## Acceptance Criteria

- **Given** I have edited a published post at least once
  **When** I tap "Edited" on the post
  **Then** a modal shows the previous version(s) with timestamps and a diff of what changed

- **Given** a recipient views an edited post
  **When** they tap the "Edited" label
  **Then** they see the same edit history as the author

## Notes
Edit history is retained for 12 months. Deleted posts do not expose edit history.
