---
id: US-064
title: "Group my subscriptions by site"
slug: cross-site-grouping
personas: [P-001]
epic: "Preference Center"
priority: must-have
complexity: medium
tags: [preference-center, cross-site, grouping]
---

# US-064: Group my subscriptions by site

## User Story

**As a** subscriber across several portfolio sites
**I want to** my subscriptions grouped by Service/site
**So that** I can reason about each site's contact separately

## Acceptance Criteria

- **Given** subscriptions across multiple Services
  **When** my dashboard renders
  **Then** they are grouped by Service with the site's branding/name
- **Given** a group
  **When** I act on it
  **Then** I can manage or unsubscribe from all lists in that Service at once
- **Given** I belong to one site only
  **When** the dashboard renders
  **Then** grouping still displays cleanly with a single group

## Notes
Cross-site unified view is the core value of the preference center.
