---
id: US-009
title: "Refresh a Stale Article"
slug: refresh-a-stale-article
personas: [P-001, P-003]
epic: "Calibrated Q&A"
priority: must-have
complexity: medium
tags: [refresh, staleness, re-query]
---

# US-009: Refresh a Stale Article

## User Story

**As a** developer working with fast-moving tools
**I want to** refresh a stale article by re-querying when its info is outdated
**So that** my KB doesn't mislead me with obsolete guidance

## Acceptance Criteria

- **Given** an article is flagged or suspected stale (e.g., a referenced tool version changed since it was written)
  **When** I run the refresh command on it
  **Then** a new `/query` is issued on the original topic and the article is updated with current information

- **Given** an article is refreshed
  **When** the update completes
  **Then** the article retains a record of its prior version or revision history

- **Given** my machine profile's tool versions have changed since an article was written
  **When** I browse that article
  **Then** the system flags it as potentially stale

## Notes
Staleness detection can key off machine-profile version drift or an explicit "last verified" timestamp in the article.
