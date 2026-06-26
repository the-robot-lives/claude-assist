---
id: US-414
title: "Add a content warning to a post"
slug: add-content-warning
personas: [P-009]
epic: "Posting & Content Creation"
priority: must-have
complexity: medium
tags: [content-warning, safety, sensitive]
---

# US-414: Add a Content Warning to a Post

## User Story

**As a** Creator
**I want to** add a content warning label to my post
**So that** readers can make an informed choice before viewing potentially distressing material

## Acceptance Criteria

- **Given** I am composing a post
  **When** I add a content warning and enter a brief label (e.g., "grief", "violence")
  **Then** the post is collapsed behind the warning text by default in all recipient feeds

- **Given** a post has a content warning
  **When** a recipient taps "Show anyway"
  **Then** the full post content is revealed inline

## Notes
Content warning text is limited to 100 characters. Warning labels persist through edits.
