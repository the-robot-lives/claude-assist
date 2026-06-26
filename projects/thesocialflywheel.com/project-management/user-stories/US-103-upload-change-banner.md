---
id: US-103
title: "Upload or change banner image"
slug: upload-change-banner
personas: [P-009]
epic: "Profile & Identity"
priority: should-have
complexity: low
tags: [profile, creator, media]
---

# US-103: Upload or Change Banner Image

## User Story

**As a** creator
**I want to** upload or change the banner image at the top of my profile
**So that** I can showcase my brand and work to anyone who views my profile

## Acceptance Criteria

- **Given** I am editing my profile
  **When** I upload a supported banner image within the size limit
  **Then** it is fitted to the banner aspect ratio and displayed at the top of my profile

- **Given** I have no banner set
  **When** my profile is viewed
  **Then** a neutral default banner is shown

## Notes
Banner should degrade gracefully on narrow/mobile layouts.
