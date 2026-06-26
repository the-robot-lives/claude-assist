---
id: US-960
title: "View Audience Composition by Broad Region"
slug: view-audience-composition-by-broad-region
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: could-have
complexity: medium
tags: [analytics, audience, geography, privacy]
---

# US-960: View Audience Composition by Broad Region

## User Story

**As a** Creator
**I want to** see a coarse geographic distribution of my engaged audience at the continent or country level
**So that** I can make informed decisions about content timing and localization without exposing individual locations.

## Acceptance Criteria

- **Given** an account with at least 50 engaged accounts from at least 2 distinct countries
  **When** I open the region breakdown
  **Then** I see country-level percentages with no sub-national granularity.

- **Given** a country that accounts for fewer than 5% of engagement
  **When** viewing region breakdown
  **Then** that country is grouped into an "Other" bucket.

## Notes
Location data is derived from coarse IP geolocation (country level only). No city, state, or precise location data is ever collected or displayed.
