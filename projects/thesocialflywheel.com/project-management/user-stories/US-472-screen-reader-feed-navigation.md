---
id: US-472
title: "Use a screen reader to browse the feed"
slug: screen-reader-feed-navigation
personas: [P-008]
epic: "Feed & Ranking"
priority: must-have
complexity: high
tags: [accessibility, screen-reader, WCAG, feed]
---

# US-472: Use a Screen Reader to Browse the Feed

## User Story

**As an** accessibility-first user (P-008)
**I want to** navigate the feed using VoiceOver or TalkBack
**So that** I have a fully equivalent experience to sighted users

## Acceptance Criteria

- **Given** VoiceOver is enabled on iOS
  **When** I swipe to a feed post
  **Then** the screen reader announces: author name, post age, channel, degree distance (e.g., "2nd-degree"), and the first 100 characters of post text

- **Given** the "Why am I seeing this" badge is focused
  **When** screen reader activates it
  **Then** the full ranking explanation is read aloud without requiring a visual modal

- **Given** the new-post indicator badge appears
  **When** it becomes visible
  **Then** an accessibility announcement ("X new posts available") fires without disrupting the current focus

## Notes
All interactive elements meet WCAG 2.1 AA contrast and tap-target-size requirements.
