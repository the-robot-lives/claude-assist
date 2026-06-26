---
id: US-628
title: "Allow Only Specific Degrees to Swipe"
slug: allow-only-specific-degrees-to-swipe
personas: [P-001]
epic: "Safety: Blocking & Exclusions"
priority: should-have
complexity: medium
tags: [safety, matching, privacy]
---

# US-628: Allow Only Specific Degrees to Swipe

## User Story

**As a** bridge-builder
**I want to** set the maximum degree of connection that can see me in Swipe-to-Match
**So that** I can expand discovery beyond direct mutuals while still bounding exposure to my extended network

## Acceptance Criteria

- **Given** I set Swipe-to-Match visibility to "Up to 2nd degree"
  **When** a third-degree connection opens Swipe-to-Match
  **Then** my profile is not in their deck

- **Given** the setting is changed from 2nd to 3rd degree
  **When** the deck refreshes
  **Then** third-degree connections begin to see my profile

## Notes
Degree options: mutuals only (1st), up to 2nd, up to 3rd, up to 4th, everyone.
