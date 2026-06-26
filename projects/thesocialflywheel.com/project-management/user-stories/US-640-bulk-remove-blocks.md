---
id: US-640
title: "Bulk Remove Blocks"
slug: bulk-remove-blocks
personas: [P-007]
epic: "Safety: Blocking & Exclusions"
priority: could-have
complexity: medium
tags: [safety, blocking, bulk]
---

# US-640: Bulk Remove Blocks

## User Story

**As a** channel moderator
**I want to** select and remove multiple blocks at once from my blocked users list
**So that** I can clean up stale blocks efficiently after reviewing the list

## Acceptance Criteria

- **Given** I am on the Blocked Users page with select mode enabled
  **When** I check several accounts and tap "Unblock selected"
  **Then** all selected blocks are removed in one network call and the list updates

- **Given** bulk unblock completes
  **When** I view the updated list
  **Then** the removed entries are gone and a toast confirms "X users unblocked"

## Notes
Bulk unblock does not re-mutual removed users; see US-618 notes.
