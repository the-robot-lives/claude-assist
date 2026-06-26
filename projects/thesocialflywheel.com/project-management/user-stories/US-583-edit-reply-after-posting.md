---
id: US-583
title: "Edit a Reply After Posting"
slug: edit-reply-after-posting
personas: [P-003]
epic: "Reactions & Engagement"
priority: should-have
complexity: medium
tags: [reply, edit, corrections]
---

# US-583: Edit a Reply After Posting

## User Story

**As a** Social Connector
**I want to** edit a reply I've already posted
**So that** I can fix typos or clarify my intent without deleting and re-posting

## Acceptance Criteria

- **Given** I tap options on my own reply
  **When** I select Edit
  **Then** the reply text becomes editable inline with a character counter

- **Given** I save the edit
  **Then** the reply shows an "Edited" label with the edit timestamp visible to all readers

## Notes
Edits are allowed within 30 minutes of posting; after that the post is locked. Edit history is not publicly exposed in v1.
