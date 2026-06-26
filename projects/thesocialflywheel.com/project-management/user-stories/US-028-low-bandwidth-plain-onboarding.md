---
id: US-028
title: "Low-Bandwidth Plain Onboarding Path"
slug: low-bandwidth-plain-onboarding
personas: [P-004, P-008, P-006]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: medium
tags: [accessibility, low-bandwidth, performance, onboarding]
---

# US-028: Low-Bandwidth Plain Onboarding Path

## User Story

**As a** user on a slow or metered connection
**I want to** a lightweight text-based onboarding path
**So that** I can complete setup without waiting for heavy assets to load

## Acceptance Criteria

- **Given** the app detects a connection slower than 1 Mbps or the user has enabled "Data saver" mode
  **When** onboarding loads
  **Then** illustrations and animations are replaced with simple icons and all non-essential media is deferred.

- **Given** I am on the plain path
  **When** I select interests
  **Then** the interest tiles load as text list items instead of image cards without any functional degradation.

## Notes
Plain path must support all mandatory steps. Auto-detect connection speed at app launch; also offer manual toggle in settings. Target < 50 KB for full onboarding flow on plain path.
