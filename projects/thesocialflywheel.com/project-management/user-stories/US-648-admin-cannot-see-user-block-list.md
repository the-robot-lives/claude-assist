---
id: US-648
title: "Admin Cannot See User Block List"
slug: admin-cannot-see-user-block-list
personas: [P-007]
epic: "Safety: Blocking & Exclusions"
priority: could-have
complexity: high
tags: [safety, privacy, admin]
---

# US-648: Admin Cannot See User Block List

## User Story

**As a** channel moderator (who also holds elevated platform permissions)
**I want to** know that even admins and moderators cannot read individual users' block lists
**So that** user safety data is protected from internal misuse

## Acceptance Criteria

- **Given** a platform admin navigates to a user's account management page
  **When** they look for block or safety data
  **Then** individual block entries are not exposed — only aggregated safety signals available for trust and safety investigations

- **Given** a legal hold or safety escalation requires access
  **When** the request is processed
  **Then** access requires a formal internal approval workflow and is logged in the audit trail

## Notes
Aggregate data (e.g., "user has N active blocks") may be used for spam detection without exposing identities.
