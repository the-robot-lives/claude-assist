---
id: US-499
title: "View feed data usage statistics"
slug: feed-data-usage-stats
personas: [P-008, P-006]
epic: "Feed & Ranking"
priority: could-have
complexity: low
tags: [data-usage, stats, low-bandwidth, settings]
---

# US-499: View Feed Data Usage Statistics

## User Story

**As an** accessibility-first user (P-008)
**I want to** see how much data the feed has consumed in the current session and month
**So that** I can make informed decisions about enabling low-bandwidth mode on a metered connection

## Acceptance Criteria

- **Given** I navigate to Settings → Data & Storage
  **When** the page loads
  **Then** I see this session's feed data usage (MB), this month's total, and a breakdown by media type (images, video, text)

- **Given** I have low-bandwidth mode disabled
  **When** I view the stats
  **Then** a suggestion appears: "Enable low-bandwidth mode to reduce usage by ~70%"

## Notes
Stats are estimates based on payload sizes; they are informational only and may differ from carrier-reported usage.
