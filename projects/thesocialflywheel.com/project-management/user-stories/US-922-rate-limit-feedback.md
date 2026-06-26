---
id: US-922
title: "Clear Rate-Limit Feedback to Users"
slug: rate-limit-feedback
personas: [P-005]
epic: "Performance, Scale & Reliability"
priority: should-have
complexity: low
tags: [rate-limiting, feedback, toast, api, ux]
---

# US-922: Clear Rate-Limit Feedback to Users

## User Story

**As a** debate seeker who posts and reacts rapidly in high-volume discussions
**I want to** receive a clear message when I have been rate-limited
**So that** I understand why my action failed and know when I can try again

## Acceptance Criteria

- **Given** my actions have triggered a rate limit (HTTP 429)
  **When** the rate-limit response is received
  **Then** a toast message appears saying "You're posting too fast — wait a few seconds and try again" with the retry-after time

- **Given** a rate limit is active
  **When** I attempt another action of the same type
  **Then** the button is disabled with a countdown timer showing seconds until the limit clears

## Notes
Read `Retry-After` header to display accurate countdown. Never expose internal rate-limit buckets or thresholds to users. Distinguish per-action limits (post, like, follow) with tailored messages.
