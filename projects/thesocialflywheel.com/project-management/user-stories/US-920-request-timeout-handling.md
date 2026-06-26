---
id: US-920
title: "Request Timeout Handling and User Feedback"
slug: request-timeout-handling
personas: [P-010]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: low
tags: [timeout, error-handling, feedback, ux]
---

# US-920: Request Timeout Handling and User Feedback

## User Story

**As a** skeptical switcher on a slow or unreliable connection
**I want to** be notified when a request is taking too long rather than seeing an endless spinner
**So that** I can decide to retry or continue browsing cached content

## Acceptance Criteria

- **Given** an API request has been in-flight for more than 8 seconds
  **When** no response has arrived
  **Then** the spinner is replaced with a timeout message and a "Retry" button

- **Given** I tap "Retry" after a timeout
  **When** the retry succeeds
  **Then** the content loads normally and the timeout message disappears without a full page reload

## Notes
8-second threshold is a starting point; tune based on p95 API latency in production. Timeouts must cancel the original request to avoid duplicate server processing.
