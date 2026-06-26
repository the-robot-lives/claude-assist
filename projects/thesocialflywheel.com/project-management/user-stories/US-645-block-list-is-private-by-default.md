---
id: US-645
title: "Block List is Private by Default"
slug: block-list-is-private-by-default
personas: [P-004]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: low
tags: [safety, privacy]
---

# US-645: Block List is Private by Default

## User Story

**As a** cautious newcomer
**I want to** know that my block list is private and visible only to me
**So that** I can block freely without worrying about social consequences or retaliation

## Acceptance Criteria

- **Given** I have blocked several users
  **When** any other user — including my mutuals — visits my profile
  **Then** there is no indication of how many people I have blocked or who they are

- **Given** a blocked user views my profile (as allowed by platform settings before full block enforcement)
  **When** they look for block-related information
  **Then** nothing on my profile page reveals that a block exists

## Notes
Block list privacy is enforced at API level, not just UI; see US-646 for blocked-user perspective.
