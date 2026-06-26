---
id: US-652
title: "Report a User Profile"
slug: report-a-user-profile
personas: [P-004]
epic: "Moderation & Reporting"
priority: must-have
complexity: low
tags: [reporting, user-safety]
---

# US-652: Report a User Profile

## User Story

**As a** cautious newcomer
**I want to** report another user's profile (bio, avatar, or handle) for a rule violation
**So that** platform Trust & Safety can review the account independently of any specific post

## Acceptance Criteria

- **Given** I am viewing another user's profile page
  **When** I select "Report Profile" from the action menu
  **Then** I am shown a profile-specific reason list (impersonation, inappropriate avatar, hate-based bio, spam account, other) distinct from the post-report reason list

- **Given** I submit a profile report
  **When** the report is processed
  **Then** it is routed to platform T&S (not the channel mod) and I receive a confirmation notification

## Notes
Profile reports bypass channel moderation because the violation is account-level, not channel-scoped.
