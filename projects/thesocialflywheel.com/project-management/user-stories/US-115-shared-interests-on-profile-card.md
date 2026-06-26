---
id: US-115
title: "See shared interests on a profile card"
slug: shared-interests-on-profile-card
personas: [P-001]
epic: "Profile & Identity"
priority: must-have
complexity: medium
tags: [profile, interests, discovery]
---

# US-115: See Shared Interests On A Profile Card

## User Story

**As a** bridge-builder
**I want to** see which interests I share with another user on their profile card
**So that** I can find common ground before reaching out

## Acceptance Criteria

- **Given** I view another user's profile card
  **When** we have overlapping interests
  **Then** the shared interests are highlighted distinctly from their other interests

- **Given** an interest I excluded matches theirs
  **When** the card renders
  **Then** that excluded interest is not shown as shared

## Notes
Shared-interest computation must respect both users' exclusion lists.
