---
id: US-127
title: "Add alt text for avatar and banner images"
slug: alt-text-avatar-banner
personas: [P-008]
epic: "Profile & Identity"
priority: must-have
complexity: low
tags: [profile, accessibility, a11y, images]
---

# US-127: Add Alt Text For Avatar And Banner Images

## User Story

**As an** accessibility-first user
**I want to** read alt text for profile avatar and banner images
**So that** I understand the imagery others present without seeing it

## Acceptance Criteria

- **Given** I am editing my profile
  **When** I upload an avatar or banner image
  **Then** I can enter alt text that describes the image

- **Given** a profile image has alt text
  **When** a screen reader encounters it
  **Then** the alt text is announced, and decorative images are marked so they are skipped

## Notes
Offer an optional AI-suggested description the user can edit before saving.
