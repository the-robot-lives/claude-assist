---
id: US-068
title: "Request account and data deletion"
slug: request-account-deletion
personas: [P-001]
epic: "Preference Center"
priority: could-have
complexity: medium
tags: [preference-center, gdpr, deletion, privacy]
---

# US-068: Request account and data deletion

## User Story

**As a** subscriber
**I want to** request deletion of my account and data
**So that** I can exercise my right to be forgotten

## Acceptance Criteria

- **Given** I am signed in
  **When** I request deletion
  **Then** I am asked to confirm and told what will be removed
- **Given** I confirm deletion
  **When** it is processed
  **Then** my personal data is erased or irreversibly anonymized per policy
- **Given** legal retention applies
  **When** deletion runs
  **Then** only permissible data is retained and I am informed

## Notes
Deletion is a request/confirm flow, not an instant destructive UI action.
