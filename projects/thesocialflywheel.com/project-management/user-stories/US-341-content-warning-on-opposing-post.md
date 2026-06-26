---
id: US-341
title: "Content Warning on Sensitive Opposing Post"
slug: content-warning-on-opposing-post
personas: [P-004]
epic: "Opposing-Views Lane"
priority: should-have
complexity: medium
tags: [opposing-views, content-warning, safety, sensitive]
---

# US-341: Content Warning on Sensitive Opposing Post

## User Story

**As a** cautious newcomer
**I want to** see a content warning before I read an opposing-view post on a topic flagged as sensitive
**So that** I can choose whether to expand and read the post or pass it by

## Acceptance Criteria

- **Given** a post is tagged with a platform-designated sensitive topic (e.g. grief, trauma, mental health)
  **When** it appears in the Opposing-Views Lane
  **Then** the post body is collapsed behind a content warning that names the sensitive topic

- **Given** the content warning is shown
  **When** I tap "Show anyway"
  **Then** the post expands and the Save and Report actions become available

## Notes
The content warning UI must remain accessible: the "Show anyway" trigger must have a visible focus indicator and be reachable by keyboard.
