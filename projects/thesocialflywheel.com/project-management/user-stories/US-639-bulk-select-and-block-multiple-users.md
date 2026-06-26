---
id: US-639
title: "Bulk Select and Block Multiple Users"
slug: bulk-select-and-block-multiple-users
personas: [P-007]
epic: "Safety: Blocking & Exclusions"
priority: should-have
complexity: high
tags: [safety, blocking, bulk]
---

# US-639: Bulk Select and Block Multiple Users

## User Story

**As a** channel moderator
**I want to** select multiple users from a list and block them in a single action
**So that** I can quickly manage coordinated harassment or spam waves without blocking one at a time

## Acceptance Criteria

- **Given** I am on a list of accounts (e.g., recent commenters or followers)
  **When** I enable "Select multiple" mode
  **Then** checkboxes appear beside each account and I can select up to 100 at once

- **Given** I have selected 15 accounts
  **When** I tap "Block selected" and confirm
  **Then** all 15 are blocked simultaneously and a summary shows "15 users blocked"

- **Given** one or more accounts in a bulk block cannot be processed (e.g., already blocked)
  **When** the batch completes
  **Then** a breakdown lists successes and skipped entries with reasons

## Notes
Cascade default for bulk blocks follows the user's account-level cascade preference.
