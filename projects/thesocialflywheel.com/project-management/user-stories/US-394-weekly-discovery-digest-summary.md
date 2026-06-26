---
id: US-394
title: "Weekly Discovery Digest Summary"
slug: weekly-discovery-digest-summary
personas: [P-006]
epic: "Discovery Engine"
priority: could-have
complexity: medium
tags: [discovery, digest, notifications]
---

# US-394: Weekly Discovery Digest Summary

## User Story

**As a** Quiet Consumer
**I want to** receive a weekly in-app digest summarizing the discovery topics and channels surfaced to me
**So that** I can review the week's discovery activity at a time of my choosing rather than during my live feed

## Acceptance Criteria

- **Given** I have opted into the weekly discovery digest
  **When** the digest is generated each Monday
  **Then** I receive an in-app notification with a summary card listing the top three topic clusters surfaced, my engagement rate, and any new channels suggested

- **Given** the digest is available
  **When** I tap the digest card
  **Then** I can see each surfaced topic, the number of items shown, and my signals for that topic, with quick links to exclude or boost each topic

## Notes
Digest is in-app only; no email digest in v1. Digest generation should be asynchronous and not block feed loading.
