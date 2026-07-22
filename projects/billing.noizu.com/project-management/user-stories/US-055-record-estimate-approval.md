---
id: US-055
title: "Record estimate approval"
slug: record-estimate-approval
personas: [P-003, P-004]
epic: "Estimates and Proposals"
priority: should-have
complexity: medium
tags: [estimates, approvals]
---

# US-055: Record estimate approval

## User Story

**As a** project delivery lead  
**I want to** capture approval status and timestamp  
**So that** preserve scope and reduce duplicate entry

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the record estimate approval flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
