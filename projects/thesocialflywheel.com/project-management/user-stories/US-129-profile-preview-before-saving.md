---
id: US-129
title: "Preview profile before saving changes"
slug: profile-preview-before-saving
personas: [P-009]
epic: "Profile & Identity"
priority: should-have
complexity: medium
tags: [profile, identity, creator]
---

# US-129: Preview Profile Before Saving Changes

## User Story

**As a** creator
**I want to** preview how my profile looks before saving
**So that** I can confirm the presentation is right before others see it

## Acceptance Criteria

- **Given** I have unsaved profile edits
  **When** I choose preview
  **Then** I see a rendered view of my profile as a viewer would, without committing changes

- **Given** I am previewing
  **When** I switch the simulated viewer degree
  **Then** the preview reflects what each mutual degree would see

## Notes
Let the user discard or continue editing directly from the preview.
