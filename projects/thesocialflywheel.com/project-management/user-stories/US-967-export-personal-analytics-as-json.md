---
id: US-967
title: "Export Personal Analytics as JSON"
slug: export-personal-analytics-as-json
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: medium
tags: [analytics, export, api, portability]
---

# US-967: Export Personal Analytics as JSON

## User Story

**As a** Creator
**I want to** download my full analytics dataset as a machine-readable JSON file
**So that** I can analyze my data with custom tools or store it independently of the platform

## Acceptance Criteria

- **Given** an authenticated Creator account
  **When** I request a JSON analytics export
  **Then** a download is prepared containing all post metrics, reach-by-degree breakdowns, engagement events, and mutuals growth data for the past 12 months

- **Given** the export request
  **When** the file is ready (within 5 minutes)
  **Then** I receive an in-app notification and email with a time-limited download link (valid 48 hours)

## Notes
JSON schema is documented in the developer portal. PII of other users is never included; audience data is aggregate only.
