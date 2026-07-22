---
id: US-059
title: "Decline estimate with reason"
slug: decline-estimate-with-reason
personas: [P-003, P-006]
epic: "Estimates and Proposals"
priority: could-have
complexity: low
tags: [estimates, approvals]
---

# US-059: Decline estimate with reason

## User Story

**As a** project delivery lead  
**I want to** record declined estimate reasons  
**So that** preserve scope and reduce duplicate entry

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the decline estimate with reason flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
