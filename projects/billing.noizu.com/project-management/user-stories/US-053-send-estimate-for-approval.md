---
id: US-053
title: "Send estimate for approval"
slug: send-estimate-for-approval
personas: [P-003, P-004]
epic: "Estimates and Proposals"
priority: should-have
complexity: high
tags: [estimates, approvals]
---

# US-053: Send estimate for approval

## User Story

**As a** project delivery lead  
**I want to** email an estimate to the client approver  
**So that** preserve scope and reduce duplicate entry

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the send estimate for approval flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
