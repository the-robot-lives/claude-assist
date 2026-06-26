---
id: US-102
title: "Upload or change avatar"
slug: upload-change-avatar
personas: [P-004]
epic: "Profile & Identity"
priority: must-have
complexity: low
tags: [profile, identity, media]
---

# US-102: Upload or Change Avatar

## User Story

**As a** cautious newcomer
**I want to** upload or change my avatar image
**So that** I can present myself the way I choose without over-sharing personal details

## Acceptance Criteria

- **Given** I am editing my profile
  **When** I upload a supported image file within the size limit
  **Then** it is cropped to the avatar shape and set as my avatar everywhere I appear

- **Given** I upload a file of an unsupported type or oversized
  **When** I attempt to save
  **Then** I see a clear error and my previous avatar is unchanged

## Notes
Default placeholder avatar shown until a custom one is set.
