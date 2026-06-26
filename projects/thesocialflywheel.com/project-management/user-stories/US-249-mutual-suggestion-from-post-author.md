---
id: US-249
title: "Mutual Suggestion from Post Author"
slug: mutual-suggestion-from-post-author
personas: [P-001]
epic: "Mutuals Graph & Degrees"
priority: could-have
complexity: medium
tags: [discovery, graph, feed]
---

# US-249: Mutual Suggestion from Post Author

## User Story

**As a** Bridge-Builder (P-001)
**I want to** see a contextual "Add Mutual" suggestion when I engage with a post from a 2nd–4th degree user
**So that** I can act on discovery moments without leaving the feed

## Acceptance Criteria

- **Given** I react to or comment on a post from a 2nd–4th degree mutual
  **When** my interaction is registered
  **Then** a contextual nudge appears beneath the post: "You liked this — want to add [Author] as a mutual?"

- **Given** the contextual suggestion appears
  **When** I tap "Add Mutual"
  **Then** a mutual request is sent immediately and the nudge updates to "Request sent"

- **Given** I dismiss the nudge by tapping "Not now"
  **When** the nudge is dismissed
  **Then** it does not reappear for that author for at least 7 days

## Notes
Frequency cap the nudge to avoid it appearing on every interaction — no more than once per user per feed session.
