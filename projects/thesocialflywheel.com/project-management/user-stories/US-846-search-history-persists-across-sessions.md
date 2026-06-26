---
id: US-846
title: "Search History Persists Across Sessions"
slug: search-history-persists-across-sessions
personas: [P-006]
epic: "Search & Find"
priority: should-have
complexity: low
tags: [search, history, persistence, sessions]
---

# US-846: Search History Persists Across Sessions

## User Story

**As a** quiet consumer
**I want to** have my recent search history sync across devices
**So that** I can pick up where I left off when I switch devices

## Acceptance Criteria

- **Given** I performed searches on device A
  **When** I log in on device B
  **Then** my recent search history (up to 20 entries) is available

- **Given** I clear search history on one device
  **When** I open the search bar on another device
  **Then** the cleared state is reflected within 30 seconds via sync

## Notes
History is stored per account server-side; local-only history is not supported.
