---
id: US-850
title: "Opt Out of Appearing in Search Results"
slug: opt-out-of-search-results
personas: [P-006]
epic: "Search & Find"
priority: could-have
complexity: high
tags: [search, privacy, opt-out, discoverability]
---

# US-850: Opt Out of Appearing in Search Results

## User Story

**As a** quiet consumer
**I want to** opt out of appearing in other users' people search results
**So that** I can use the platform without being discoverable to strangers

## Acceptance Criteria

- **Given** I enable "Hidden from search" in Privacy Settings
  **When** any non-connected user searches my name or username
  **Then** I do not appear in their people search results

- **Given** I am hidden from search
  **When** one of my existing moots searches for me
  **Then** I still appear in their results since we are already connected

## Notes
Hidden users can still search for others; this is a one-way discoverability control and does not affect existing mutual relationships.
