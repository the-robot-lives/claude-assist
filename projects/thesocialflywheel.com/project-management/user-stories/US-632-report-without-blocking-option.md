---
id: US-632
title: "Report Without Blocking Option"
slug: report-without-blocking-option
personas: [P-001]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: low
tags: [safety, reporting]
---

# US-632: Report Without Blocking Option

## User Story

**As a** bridge-builder
**I want to** file a content report without being forced to block the user
**So that** I can flag rule violations while maintaining the possibility of future dialogue

## Acceptance Criteria

- **Given** I open the report flow for a post
  **When** I reach the block-offer step
  **Then** a clearly labelled "Skip — report only" option is available

- **Given** I choose "Skip" and submit
  **When** the report is processed
  **Then** no block is applied and the relationship remains unchanged

## Notes
Blocking must never be a prerequisite for submitting a report.
