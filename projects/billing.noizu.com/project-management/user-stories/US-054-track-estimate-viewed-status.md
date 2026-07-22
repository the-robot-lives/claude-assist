---
id: US-054
title: "Track estimate viewed status"
slug: track-estimate-viewed-status
personas: [P-003, P-006]
epic: "Estimates and Proposals"
priority: could-have
complexity: medium
tags: [estimates, approvals]
---

# US-054: Track estimate viewed status

## User Story

**As a** project delivery lead  
**I want to** record when a client opens an estimate  
**So that** preserve scope and reduce duplicate entry

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the track estimate viewed status flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
