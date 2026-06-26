---
id: US-983
title: "Privacy Guardrails Prevent Graph De-anonymization"
slug: privacy-guardrails-prevent-graph-deanonymization
personas: [P-006]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: high
tags: [privacy, analytics, security, safety]
---

# US-983: Privacy Guardrails Prevent Graph De-anonymization

## User Story

**As a** Quiet Consumer
**I want to** the platform to enforce technical guardrails that prevent analytics or API responses from returning data that could be combined to identify individual users in the mutuals graph
**So that** my participation remains private even from creators analyzing their reach.

## Acceptance Criteria

- **Given** any analytics API response
  **When** the query would return data about fewer than 50 unique accounts in a cohort
  **Then** the response suppresses that cohort's data and returns a privacy_suppressed flag instead.

- **Given** repeated API calls that appear to be probing the graph (e.g., incrementally narrowing filter combinations)
  **When** the system detects the pattern
  **Then** rate limits are tightened for that key and an alert is logged for review.

- **Given** an analytics dashboard UI
  **When** audience data is rendered
  **Then** no combination of available filters can produce a view smaller than the 50-account minimum cohort.

## Notes
Differential privacy noise may be added to aggregate counts to further reduce re-identification risk. Privacy model is reviewed annually by a third-party auditor.
