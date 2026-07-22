---
id: US-086
title: "Validate inquiry fields"
slug: validate-inquiry-fields
personas: [P-005]
epic: "Inquiries & Lead Capture"
priority: should-have
complexity: low
tags: [inquiry, validation]
---

# US-086: Validate inquiry fields

## User Story

**As a** person submitting an inquiry
**I want to** clear validation on the inquiry fields
**So that** I submit correct information the first time

## Acceptance Criteria

- **Given** the inquiry form
  **When** I enter an invalid email or exceed a field limit
  **Then** I see a field-level error before submission
- **Given** optional fields (company/project/budget/timeline)
  **When** I leave them blank
  **Then** submission still succeeds
- **Given** a valid submission
  **When** the server validates
  **Then** it re-checks the fields authoritatively

## Notes
