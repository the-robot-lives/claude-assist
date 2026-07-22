---
id: US-008
title: "Complete billing setup checklist"
slug: complete-billing-setup-checklist
personas: [P-001, P-002, P-007]
epic: "Onboarding and Access"
priority: must-have
complexity: medium
tags: [auth, workspace]
---

# US-008: Complete billing setup checklist

## User Story

**As a** new owner  
**I want to** see required setup tasks for billing readiness  
**So that** know what blocks first invoice send

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the complete billing setup checklist flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
