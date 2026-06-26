---
id: US-582
title: "Save a Reply Draft"
slug: save-reply-draft
personas: [P-001]
epic: "Reactions & Engagement"
priority: could-have
complexity: medium
tags: [drafts, reply, UX]
---

# US-582: Save a Reply Draft

## User Story

**As a** Bridge-Builder
**I want to** my in-progress reply to be saved as a draft if I navigate away
**So that** I don't lose carefully crafted responses when I switch context

## Acceptance Criteria

- **Given** I have typed text in the reply box
  **When** I navigate away from the post
  **Then** a draft is saved locally and a "Draft" badge appears on the post in my feed

- **Given** I return to the post
  **Then** the reply box is pre-filled with my draft and I can edit and submit or discard it

## Notes
Drafts expire after 7 days. One draft is allowed per user per post to keep the model simple.
