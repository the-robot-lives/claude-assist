---
id: US-415
title: "Tag post as sensitive or NSFW"
slug: tag-post-sensitive
personas: [P-009]
epic: "Posting & Content Creation"
priority: must-have
complexity: low
tags: [sensitive, nsfw, safety, media]
---

# US-415: Tag Post as Sensitive or NSFW

## User Story

**As a** Creator
**I want to** mark my post as containing sensitive or NSFW content
**So that** the platform can apply appropriate visibility filters for underage or opted-out users

## Acceptance Criteria

- **Given** I am composing a post with sensitive content
  **When** I toggle the "Sensitive / NSFW" flag
  **Then** the post is hidden behind a blur/click-through for users who have opted out of sensitive content

- **Given** a post is marked NSFW
  **When** a user with "Hide Sensitive Content" enabled views their feed
  **Then** only the warning label is shown; the content requires an explicit tap to reveal

## Notes
Sensitive flag is separate from content warning (US-414) and can be used together.
