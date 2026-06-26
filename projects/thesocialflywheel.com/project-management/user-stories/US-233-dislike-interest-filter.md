---
id: US-233
title: "Dislike Interest Filter"
slug: dislike-interest-filter
personas: [P-006]
epic: "Mutuals Graph & Degrees"
priority: should-have
complexity: medium
tags: [feed, interests, filtering]
---

# US-233: Dislike Interest Filter

## User Story

**As a** Quiet Consumer (P-006)
**I want to** mark specific interests as "disliked" to suppress them from my outer-degree feed
**So that** I can fine-tune my content diet without unfollowing people

## Acceptance Criteria

- **Given** a post appears in my feed from a 2nd–4th degree mutual
  **When** I open the post menu and tap "I don't like this topic"
  **Then** the matched interest is added to my dislikes list and I am shown a brief undo option

- **Given** I have disliked an interest
  **When** future posts from outer-degree mutuals match that interest
  **Then** those posts do not appear in my feed

- **Given** I visit my interests settings
  **When** I view the dislikes section
  **Then** I can see and remove any disliked interest to restore that content

## Notes
Dislikes are a softer signal than interest exclusions (US-220) and may be used to tune recommendation weight rather than hard-filter — implementation may vary.
