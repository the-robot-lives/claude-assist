---
id: US-312
title: "Screen Reader Announcement for Opposing Context"
slug: screen-reader-opposing-context-announcement
personas: [P-008]
epic: "Opposing-Views Lane"
priority: must-have
complexity: medium
tags: [opposing-views, accessibility, screen-reader, a11y]
---

# US-312: Screen Reader Announcement for Opposing Context

## User Story

**As an** accessibility-first user
**I want to** have my screen reader announce the opposing-view context before reading the post content
**So that** I understand the framing before encountering the opposing viewpoint

## Acceptance Criteria

- **Given** I am navigating with a screen reader
  **When** focus enters an opposing-view post
  **Then** the reader announces "Opposing view on [Interest Name]" before reading the post body

- **Given** the opposing-view label is announced
  **When** I navigate to the next post
  **Then** the label announcement does not repeat for the same post if I return focus to it during the same session

## Notes
Use aria-label or a visually hidden span with role="note" prepended to the post container. Must pass WCAG 2.1 AA.
