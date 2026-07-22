---
id: US-074
title: "Export a run's full record as structured data"
slug: export-a-runs-full-record-as-structured-data
personas: [P-005]
epic: "Memory & Knowledge"
priority: should-have
complexity: medium
tags: [export, api, research, reproducibility]
---

# US-074: Export a Run's Full Record as Structured Data

## User Story

**As a** researcher (Dr. Elias Thorn) building reproducible experiments on top of Noizu Intellect
**I want to** export a complete run's record — messages, plans, per-path grades, and decision-weight updates — as structured data via the API
**So that** I can analyze it offline or feed it into an external evaluation pipeline without scraping the UI

## Acceptance Criteria

- **Given** a completed run (picked, rejected, or still shortlisted)
  **When** I call the export endpoint for that run
  **Then** I receive a structured document containing all channel messages exchanged during the run, the full plan decomposition, each path's turn history and reflection patches, all Reviewer grade records, and any decision-weight updates triggered by the pick

- **Given** a run involving multiple agents and a long conversation history
  **When** the export is generated
  **Then** it is paginated or streamed rather than requiring the full payload to be built synchronously, so large runs don't time out the request

- **Given** an exported run record
  **When** I inspect its schema
  **Then** it is versioned (includes a schema version field) so downstream tooling can handle schema evolution across Noizu Intellect releases

## Notes
Complements the decision-weight history API in [[US-063]] — this export is the run-scoped superset, while [[US-063]] is the weight-store-scoped, cross-run view. Export should respect redaction state ([[US-071]]) so purged memories don't leak back out through an export.
