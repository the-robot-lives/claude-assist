---
id: US-981
title: "View API Rate Limit Status"
slug: view-api-rate-limit-status
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: low
tags: [api, developer, rate-limits]
---

# US-981: View API Rate Limit Status

## User Story

**As a** Creator
**I want to** see my current API rate-limit consumption, reset time, and per-key quotas in the developer dashboard and in API response headers
**So that** I can avoid hitting limits and plan my integration accordingly.

## Acceptance Criteria

- **Given** any authenticated API request
  **When** the response is returned
  **Then** it includes X-RateLimit-Limit, X-RateLimit-Remaining, and X-RateLimit-Reset headers with current values.

- **Given** the Developer Dashboard
  **When** I navigate to the Rate Limits section
  **Then** I see a table of all my API keys with each key's current call count, limit, and next reset timestamp.

## Notes
Rate limits are per-key per-minute and per-key per-day. Default limits for new keys: 60 req/min, 5000 req/day.
