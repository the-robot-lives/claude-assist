---
id: US-607
title: "Block an Individual User"
slug: block-an-individual-user
personas: [P-004]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: low
tags: [safety, blocking]
---

# US-607: Block an Individual User

## User Story

**As a** cautious newcomer
**I want to** block another user on the platform
**So that** they can no longer interact with me or appear in my feeds

## Acceptance Criteria

- **Given** I am viewing a user's profile
  **When** I select "Block [username]" from the options menu
  **Then** the block is confirmed, the user is removed from my feeds, and I am removed from theirs

- **Given** a block is in place
  **When** the blocked user attempts to comment on my post
  **Then** their comment is not visible to me

## Notes
Default block is direct-only; cascade options are covered in US-609/US-610.
