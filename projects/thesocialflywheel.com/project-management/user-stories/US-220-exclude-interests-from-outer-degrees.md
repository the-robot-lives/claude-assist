---
id: US-220
title: "Exclude Interests from Outer Degrees"
slug: exclude-interests-from-outer-degrees
personas: [P-006]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: medium
tags: [feed, interests, filtering]
---

# US-220: Exclude Interests from Outer Degrees

## User Story

**As a** Quiet Consumer (P-006)
**I want to** exclude specific interests from appearing in content from 2nd–4th degree mutuals
**So that** I can block topics I find unwanted from distant connections without affecting my direct mutuals' posts

## Acceptance Criteria

- **Given** I navigate to interest settings and mark an interest as "Excluded from outer degrees"
  **When** a 2nd–4th degree mutual posts content tagged with that interest
  **Then** the post does not appear in my feed

- **Given** I have excluded an interest from outer degrees
  **When** a 1st-degree mutual posts content with that interest tag
  **Then** the post still appears normally in my Mutuals lane (exclusion does not affect 1st degree)

- **Given** I remove an interest exclusion
  **When** my feed is next refreshed
  **Then** matching outer-degree posts become eligible to appear again
