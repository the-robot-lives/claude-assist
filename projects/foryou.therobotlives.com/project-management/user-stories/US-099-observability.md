---
id: US-099
title: "Observe signups, rate-limits, and abuse"
slug: observability
personas: [P-003, P-008]
epic: "Infrastructure"
priority: should-have
complexity: medium
tags: [infra, observability, metrics, monitoring]
---

# US-099: Observe signups, rate-limits, and abuse

## User Story

**As a** platform operator
**I want to** metrics, logs, and dashboards for the signup platform
**So that** I can monitor health and detect abuse

## Acceptance Criteria

- **Given** the public endpoint is live
  **When** signups occur
  **Then** signup volume, success/failure, and latency are recorded as metrics
- **Given** rate-limiting is active (US-100)
  **When** limits trip
  **Then** rate-limit hits and abuse signals are visible in dashboards/alerts
- **Given** an incident
  **When** I investigate
  **Then** logs correlate a request to its outcome without leaking PII

## Notes
Feeds abuse monitoring for the adversarial persona (P-008).
