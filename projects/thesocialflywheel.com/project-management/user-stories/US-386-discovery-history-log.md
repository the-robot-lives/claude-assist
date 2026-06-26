---
id: US-386
title: "Discovery History Log"
slug: discovery-history-log
personas: [P-001]
epic: "Discovery Engine"
priority: could-have
complexity: medium
tags: [discovery, transparency, history]
---

# US-386: Discovery History Log

## User Story

**As a** Bridge-Builder
**I want to** review a log of discovery items that were surfaced to me over the past 30 days
**So that** I can revisit content I may have skipped and understand how my discovery profile has evolved

## Acceptance Criteria

- **Given** I navigate to the Discovery History page
  **When** the page loads
  **Then** I see a chronological list of discovery items shown to me in the last 30 days, including which topics they belonged to and my recorded signal (liked, disliked, dismissed, no action)

- **Given** I am viewing the discovery history log
  **When** I tap an entry
  **Then** I am taken to the original post if it still exists, or shown a "content no longer available" message if it has been deleted

## Notes
History is retained for 30 days rolling; no user-accessible history beyond that window.
