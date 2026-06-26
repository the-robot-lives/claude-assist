---
id: US-828
title: "Show Shared Interests on People Result Cards"
slug: shared-interests-in-people-results
personas: [P-003]
epic: "Search & Find"
priority: must-have
complexity: medium
tags: [search, people, interests, shared, social-graph]
---

# US-828: Show Shared Interests on People Result Cards

## User Story

**As a** social connector
**I want to** see which interests I share with each person in search results
**So that** I can quickly identify who is most relevant to connect with

## Acceptance Criteria

- **Given** I view a people search result card
  **When** the card renders
  **Then** up to 3 shared interests appear as tags below the person's name

- **Given** a person shares no interests with me
  **When** their card renders
  **Then** no shared interest tags appear and their top 3 public interests are shown instead

## Notes
Interest tags are clickable and run a new interest search for that topic.
