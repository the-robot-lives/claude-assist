---
id: US-015
title: "Control telemetry and data retention"
slug: consent-telemetry
personas: [P-006]
epic: "Privacy and Data"
priority: could-have
complexity: medium
tags: [privacy, retention, controls]
---

# US-015: Control telemetry and data retention

## User Story

**As a** compliance steward  
**I want to** set telemetry and retention policy at workspace level  
**So that** I meet policy requirements without forcing technical intervention.

## Acceptance Criteria

- **Given** policy settings page is open, **When** I set retention and masking options, **Then** existing data is migrated to the new policy window.
- **Given** a policy prevents external telemetry, **When** a workflow executes, **Then** only local logs are retained.

