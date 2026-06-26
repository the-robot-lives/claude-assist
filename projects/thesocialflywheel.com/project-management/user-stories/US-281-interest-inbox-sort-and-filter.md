---
id: US-281
title: "Interest Inbox Sort and Filter"
slug: interest-inbox-sort-and-filter
personas: [P-003]
epic: "Swipe-to-Match"
priority: should-have
complexity: medium
tags: [inbox, filter, sort, match-management]
---

# US-281: Interest Inbox Sort and Filter

## User Story

**As a** Social Connector (P-003)
**I want to** sort and filter my interest inbox by recency, shared interest count, or expiry
**So that** I can prioritize which incoming interests to review first

## Acceptance Criteria

- **Given** I have multiple pending interests
  **When** I open the sort options in my inbox
  **Then** I can sort by "Newest first," "Expiring soonest," or "Most shared interests"

- **Given** I apply an "Expiring soonest" sort
  **When** the inbox re-renders
  **Then** interests with fewer than 3 days remaining are pinned to the top with a red expiry badge
