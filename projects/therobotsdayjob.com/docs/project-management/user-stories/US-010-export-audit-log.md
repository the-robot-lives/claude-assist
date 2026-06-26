---
id: US-010
title: "Export audit logs for one project"
slug: export-audit-log
personas: [P-006, P-005]
epic: "Compliance"
priority: should-have
complexity: medium
tags: [audit, export, compliance]
---

# US-010: Export audit logs for one project

## User Story

**As a** compliance steward  
**I want to** export project audit logs for a selected date range  
**So that** I can provide evidence for internal review.

## Acceptance Criteria

- **Given** I choose a project and range, **When** I export, **Then** output includes approvals, revisions, escalations, and tool trace.
- **Given** sensitive fields exist, **When** export runs, **Then** redaction settings are applied consistently.

