---
id: US-773
title: "Select Region"
slug: select-region
personas: [P-004]
epic: "Settings & Preferences"
priority: could-have
complexity: low
tags: [locale, region, content, geo]
---

# US-773: Select Region

## User Story

**As a** cautious newcomer
**I want to** set my region
**So that** locally relevant content, community guidelines, and legal disclosures are applied correctly.

## Acceptance Criteria

- **Given** I open Language & Locale
  **When** I choose my country/region
  **Then** content moderation rules and any region-specific feature flags update to match that region.

## Notes
Region is auto-detected on first launch from IP geolocation but can always be overridden by the user.
