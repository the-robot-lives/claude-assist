---
id: US-282
title: "Daily Limit Resets at Midnight"
slug: daily-limit-resets-at-midnight
personas: [P-003]
epic: "Swipe-to-Match"
priority: must-have
complexity: low
tags: [daily-limit, reset, rate-limiting]
---

# US-282: Daily Limit Resets at Midnight

## User Story

**As a** Social Connector (P-003)
**I want to** have my daily swipe allowance reset at midnight in my local timezone
**So that** I know exactly when I can swipe again without confusion

## Acceptance Criteria

- **Given** I have exhausted my daily swipe limit
  **When** midnight passes in my device's timezone
  **Then** my swipe counter resets to the full daily allowance without requiring an app restart

- **Given** my timezone changes (e.g., while travelling)
  **When** I open the swipe lane
  **Then** the reset time displayed reflects my current device timezone
