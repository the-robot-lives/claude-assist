---
id: US-217
title: "Third-Degree Interest Filter"
slug: third-degree-interest-filter
personas: [P-006]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: medium
tags: [feed, degrees, interests]
---

# US-217: Third-Degree Interest Filter

## User Story

**As a** Quiet Consumer (P-006)
**I want to** receive posts from 3rd-degree mutuals only when they strongly match my subscribed interests
**So that** content from near-strangers is tightly curated and doesn't overwhelm my feed

## Acceptance Criteria

- **Given** a 3rd-degree mutual posts content that matches one or more of my interests
  **When** my feed is built
  **Then** the post is eligible to appear, ranked below 2nd-degree content by the degree weight

- **Given** a 3rd-degree mutual posts content that does not match any of my interests
  **When** my feed is built
  **Then** the post is excluded entirely from my feed

## Notes
3rd-degree posts may optionally require a higher interest-match confidence threshold than 2nd-degree to reduce noise further — a platform-tunable parameter.
