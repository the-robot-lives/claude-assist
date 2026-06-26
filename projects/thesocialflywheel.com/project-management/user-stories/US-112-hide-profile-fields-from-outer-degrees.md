---
id: US-112
title: "Hide specific fields from outer-degree viewers"
slug: hide-profile-fields-from-outer-degrees
personas: [P-004]
epic: "Profile & Identity"
priority: should-have
complexity: medium
tags: [profile, privacy, identity]
---

# US-112: Hide Specific Fields From Outer-Degree Viewers

## User Story

**As a** cautious newcomer
**I want to** hide individual profile fields from viewers beyond a chosen degree
**So that** I can share some details broadly while keeping sensitive ones close

## Acceptance Criteria

- **Given** I edit a profile field's visibility
  **When** I set it to "2nd-degree and closer"
  **Then** 3rd- and 4th-degree mutuals do not see that field

- **Given** a field is hidden from a viewer
  **When** they load my profile
  **Then** the field is omitted entirely with no placeholder revealing its existence

## Notes
Per-field visibility overrides the profile-level default from US-111 where stricter.
