---
id: US-337
title: "Skip or Hide an Individual Opposing-View Post"
slug: skip-individual-opposing-post
personas: [P-006]
epic: "Opposing-Views Lane"
priority: should-have
complexity: low
tags: [opposing-views, hide, skip, user-control]
---

# US-337: Skip or Hide an Individual Opposing-View Post

## User Story

**As a** quiet consumer
**I want to** hide a specific opposing-view post I do not want to see without reporting it or changing my settings
**So that** I have lightweight control over individual pieces of content without altering my long-term preferences

## Acceptance Criteria

- **Given** I view an opposing-view post
  **When** I select "Hide this post" from the action menu
  **Then** the post is immediately removed from my lane and does not reappear in future sessions

- **Given** I hide a post
  **When** the system fills the lane
  **Then** a replacement post (if available) is shown in its place on the next render

## Notes
Hiding is per-user and per-post. It does not affect the author's post appearing for other users and does not count as a report.
