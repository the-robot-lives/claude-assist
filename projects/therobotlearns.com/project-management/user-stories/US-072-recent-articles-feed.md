---
id: US-072
title: "Recently Added/Updated Articles Feed"
slug: recent-articles-feed
personas: [P-004, P-001]
epic: "Search & Discovery"
priority: should-have
complexity: low
tags: [feed, activity, recency]
---

# US-072: Recently Added/Updated Articles Feed

## User Story

**As a** engineering team lead keeping an eye on a shared KB
**I want to** see a feed of recently added or updated articles
**So that** I can stay current on what's new without re-browsing the whole KB each time

## Acceptance Criteria

- **Given** articles have been added or edited over the past week
  **When** I open the recent-activity feed
  **Then** they're listed newest-first with the article title, change type (added/updated), and timestamp

- **Given** I want a longer or shorter window
  **When** I pass a time-range option to the feed command
  **Then** only activity within that range is shown

- **Given** the same article was updated multiple times in the window
  **When** it appears in the feed
  **Then** it's shown once with its most recent update, not duplicated per edit

- **Given** no activity occurred in the requested window
  **When** the feed is requested
  **Then** I get a clear "nothing new" result

## Notes
Draws on the same session-log/timestamp data used for KB growth stats in [[US-060]].
