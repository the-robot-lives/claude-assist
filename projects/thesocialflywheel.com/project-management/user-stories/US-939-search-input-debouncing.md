---
id: US-939
title: "Debounced Search Input to Reduce API Calls"
slug: search-input-debouncing
personas: [P-002]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: low
tags: [search, debounce, api-efficiency, performance]
---

# US-939: Debounced Search Input to Reduce API Calls

## User Story

**As a** niche enthusiast who frequently searches for specific interest channels
**I want to** have search suggestions appear quickly without every keystroke triggering a separate API call
**So that** the search experience is fast and doesn't create unnecessary server load

## Acceptance Criteria

- **Given** I am typing in the channel or user search box
  **When** I type each character
  **Then** the search API is not called until I have paused typing for at least 300 ms

- **Given** I type and then delete quickly
  **When** the debounce fires
  **Then** only the final search term at the time of debounce is sent, and stale results from cancelled requests are never shown

## Notes
Cancel previous in-flight request when new debounced request fires (use AbortController). Minimum query length: 2 characters. Show loading indicator only after 300 ms, not on every keystroke.
