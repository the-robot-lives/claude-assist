---
id: US-985
title: "Opt Out of Analytics Collection"
slug: opt-out-of-analytics-collection
personas: [P-006]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: medium
tags: [privacy, analytics, opt-out, settings]
---

# US-985: Opt Out of Analytics Collection

## User Story

**As a** Quiet Consumer
**I want to** toggle off Flywheel's behavioral analytics collection about my usage
**So that** my interactions are not tracked for platform analytics purposes beyond what is strictly necessary to deliver the service.

## Acceptance Criteria

- **Given** Settings > Privacy
  **When** I disable "Allow behavioral analytics collection"
  **Then** my subsequent interactions (views, dwell time, reaction types) are excluded from all analytics datasets including creator audience reports and platform-wide trend analysis.

- **Given** opt-out enabled
  **When** a creator views their audience composition
  **Then** my engagement is counted in impression totals (necessary for service delivery) but excluded from all behavioral segmentation breakdowns.

## Notes
Opt-out is stored per-account and persists across devices. Functional data required for service delivery (e.g., notification delivery, moderation) is unaffected by this toggle.
