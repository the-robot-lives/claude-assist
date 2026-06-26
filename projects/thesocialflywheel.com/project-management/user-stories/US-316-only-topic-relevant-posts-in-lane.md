---
id: US-316
title: "Only Topic-Relevant Posts Appear in Lane"
slug: only-topic-relevant-posts-in-lane
personas: [P-005]
epic: "Opposing-Views Lane"
priority: must-have
complexity: high
tags: [opposing-views, relevance, filtering, interests]
---

# US-316: Only Topic-Relevant Posts Appear in Lane

## User Story

**As a** debate seeker
**I want to** see only posts that are specifically about a shared interest topic
**So that** I am not shown someone's unrelated content just because they hold different views

## Acceptance Criteria

- **Given** a user holds opposing views on topic T which I also care about
  **When** they post about an unrelated topic U
  **Then** that post does not appear in my Opposing-Views Lane

- **Given** a post is about topic T
  **When** topic T is one of my registered interests
  **Then** the post may appear in my lane only if the poster's position on T is detectably different from mine

## Notes
Topic detection uses interest tags on the post, not free-text NLP inference. The platform must require posters to tag topics for posts to be eligible for the Opposing-Views Lane.
