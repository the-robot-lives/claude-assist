---
id: US-631
title: "Report Prefills Block Confirmation"
slug: report-prefills-block-confirmation
personas: [P-005]
epic: "Safety: Blocking & Exclusions"
priority: should-have
complexity: low
tags: [safety, reporting, blocking]
---

# US-631: Report Prefills Block Confirmation

## User Story

**As a** debate seeker
**I want to** have the report flow pre-select the block confirmation step when I report for harassment
**So that** the safest default is already chosen for high-severity reports without extra clicks

## Acceptance Criteria

- **Given** I select "Harassment" or "Threats" as the report category
  **When** the confirmation step appears
  **Then** the "Block this user" checkbox is pre-checked

- **Given** the pre-check is in place
  **When** I uncheck it and submit
  **Then** the report is filed without a block being applied

## Notes
Pre-check applies only to high-severity categories; other categories default to unchecked.
