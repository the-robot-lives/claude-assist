---
id: US-815
title: "Search Excludes Muted Channels and Topics"
slug: search-excludes-muted-content
personas: [P-006]
epic: "Search & Find"
priority: should-have
complexity: medium
tags: [search, exclusions, mute, filters]
---

# US-815: Search Excludes Muted Channels and Topics

## User Story

**As a** quiet consumer
**I want to** have muted channels and topics hidden from my search results by default
**So that** my searches stay focused on content I care about

## Acceptance Criteria

- **Given** I have muted channel C
  **When** I search for posts
  **Then** posts from C are excluded unless I explicitly toggle "Include muted"

- **Given** "Include muted" is toggled on
  **When** results reload
  **Then** muted channel posts appear with a "(muted)" label on their channel badge

## Notes
Muted topics and channels are managed from the user's Notification Settings.
