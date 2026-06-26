---
id: US-919
title: "Graceful API Error Recovery With Retry"
slug: api-error-recovery
personas: [P-004]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: medium
tags: [error-handling, retry, api, resilience]
---

# US-919: Graceful API Error Recovery With Retry

## User Story

**As a** cautious newcomer who is not tech-savvy
**I want to** see a clear, friendly error message and a retry option when an API call fails
**So that** I understand what happened and know what to do next without feeling like the app is broken

## Acceptance Criteria

- **Given** an API request returns a 5xx error
  **When** the error is received
  **Then** the app automatically retries up to 3 times with exponential backoff before showing an error UI

- **Given** all retries are exhausted
  **When** the error UI appears
  **Then** it displays a plain-language message (no technical codes) and a "Try again" button

## Notes
Do not retry on 4xx errors (user errors). Log retry exhaustion events to observability dashboard. Error copy must pass reading-age audit (Flesch-Kincaid grade ≤ 8).
