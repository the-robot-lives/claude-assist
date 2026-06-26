---
id: US-963
title: "Analyze Report Queue Patterns"
slug: analyze-report-queue-patterns
personas: [P-007]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: medium
tags: [analytics, moderation, reports, safety]
---

# US-963: Analyze Report Queue Patterns

## User Story

**As a** Channel Moderator
**I want to** see a breakdown of report categories, average resolution times, and appeal rates
**So that** I can identify recurring problem areas and improve moderation efficiency

## Acceptance Criteria

- **Given** a channel with at least 10 resolved reports
  **When** I open Report Queue Analytics
  **Then** I see a bar chart of report counts by category (spam, harassment, misinformation, other) for the past 30 days

- **Given** the report analytics view
  **When** I hover over a category bar
  **Then** I see the average time-to-resolution and appeal rate for that category

## Notes
Only aggregate statistics are shown; individual reporter or reported-user identities are not surfaced in the analytics view.
