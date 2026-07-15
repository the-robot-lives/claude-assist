---
id: US-093
title: "Bulk export run data with anonymization options"
slug: bulk-export-run-data-with-anonymization
personas: [P-005, P-006]
epic: "Integration & API"
priority: should-have
complexity: medium
tags: [export, anonymization, api, provenance]
---

# US-093: Bulk Export Run Data With Anonymization Options

## User Story

**As a** researcher
**I want to** bulk export runs, paths, turns, grades, and picks for a date range or project via the API, with an option to anonymize human identities
**So that** I can analyze decomposition/pick patterns offline or share a sanitized dataset without exposing who said what

## Acceptance Criteria

- **Given** I request a bulk export for a project and date range
  **When** the export job completes
  **Then** I receive a downloadable archive (e.g. NDJSON) containing runs, their paths, per-turn records, Reviewer grades, and pick decisions with rationale, matching the same data model exposed by [[US-090]]

- **Given** I set the anonymize option on export
  **When** the export is generated
  **Then** human user identifiers (names, emails) are replaced with stable pseudonymous ids consistent within that export, while agent handles and identities remain intact since they are the object of study

- **Given** an export includes pinned-experiment runs from [[US-092]]
  **When** I inspect the export
  **Then** provenance data (exact model ids, prompt version hashes) is preserved even under anonymization, since it's not personally identifying

- **Given** an export is large
  **When** I request it
  **Then** the API returns a job id immediately and I poll for completion rather than the request blocking or timing out

## Notes
Nadia (P-006) also benefits from this for compliance-driven data extraction, sharing the anonymization option with Ken's (P-007) redaction concerns elsewhere in the admin epic. Should respect the retention/deletion boundaries set in the admin ops epic — an export cannot resurrect data already purged under a retention policy.
