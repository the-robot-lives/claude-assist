---
id: US-067
title: "Export my data"
slug: export-my-data
personas: [P-001]
epic: "Preference Center"
priority: should-have
complexity: medium
tags: [preference-center, gdpr, export, privacy]
---

# US-067: Export my data

## User Story

**As a** subscriber
**I want to** download the data foryou holds about me
**So that** I can exercise data-portability rights

## Acceptance Criteria

- **Given** I am signed in
  **When** I request an export
  **Then** I receive a machine-readable file of my subscriptions, preferences, and inquiries
- **Given** the export is generated
  **When** it completes
  **Then** it contains only my data, never another person's
- **Given** an export is requested repeatedly
  **When** I exceed a reasonable rate
  **Then** requests are throttled

## Notes
Supports GDPR-style portability.
