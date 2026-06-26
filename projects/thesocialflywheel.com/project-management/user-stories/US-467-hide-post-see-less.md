---
id: US-467
title: "Hide a post and signal 'see less like this'"
slug: hide-post-see-less
personas: [P-006, P-004]
epic: "Feed & Ranking"
priority: must-have
complexity: medium
tags: [hide, see-less, feed-control, personalization]
---

# US-467: Hide a Post and Signal "See Less Like This"

## User Story

**As a** quiet consumer (P-006)
**I want to** hide individual posts and tell the feed I want less content like it
**So that** my feed improves over time without requiring manual channel unsubscription

## Acceptance Criteria

- **Given** I see an unwanted post in the feed
  **When** I tap "Hide" on the post menu
  **Then** the post collapses immediately with an undo option visible for 5 seconds

- **Given** I confirm hiding a post
  **When** subsequent feed loads occur
  **Then** posts from the same channel by the same author are down-ranked for 7 days (not permanently blocked)

- **Given** I hide 3 or more posts from the same channel within a session
  **When** the next feed load occurs
  **Then** I receive a prompt: "Show fewer posts from #channel-name?" with Yes/No options

## Notes
"See less" is a soft signal, not a block. Hard blocks are managed separately in privacy settings.
