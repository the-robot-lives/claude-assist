---
id: US-994
title: "View Content Performance by Interest Tag"
slug: view-content-performance-by-interest-tag
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: could-have
complexity: medium
tags: [analytics, posts, interests, tags]
---

# US-994: View Content Performance by Interest Tag

## User Story

**As a** Creator
**I want to** see which interest tags on my posts correlate with higher reach and engagement
**So that** I can make data-driven decisions about which topics to focus on

## Acceptance Criteria

- **Given** posts with at least 2 different interest tags applied
  **When** I open the Tag Performance view
  **Then** I see a table of tags sorted by average reach per post, with columns for tag name, post count, avg reach, and avg engagement rate

- **Given** the tag performance table
  **When** I click a tag name
  **Then** I see a filtered list of all my posts with that tag, sorted by publish date

## Notes
Minimum 3 posts per tag required before that tag appears in the performance table, to ensure statistical relevance.
