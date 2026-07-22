---
id: US-009
title: "Preview sample invoice during setup"
slug: preview-sample-invoice-during-setup
personas: [P-001, P-004]
epic: "Onboarding and Access"
priority: should-have
complexity: medium
tags: [auth, workspace]
---

# US-009: Preview sample invoice during setup

## User Story

**As a** new owner  
**I want to** preview a sample branded invoice  
**So that** catch branding and payment issues before sending

## Acceptance Criteria

- **Given** relevant workspace data exists  
  **When** I complete the preview sample invoice during setup flow  
  **Then** the result is saved, visible in the correct workspace scope, and reflected in audit or activity history where financial state changes occur

## Notes
Keep the flow precise, auditable, and recoverable. Financial state changes must preserve history rather than silently overwriting prior records.
