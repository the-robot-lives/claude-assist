---
id: US-006
title: "Upload Profile Photo During Onboarding"
slug: upload-profile-photo
personas: [P-003, P-009]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: low
tags: [profile-photo, avatar, onboarding]
---

# US-006: Upload Profile Photo During Onboarding

## User Story

**As a** social connector
**I want to** upload a profile photo during setup
**So that** my profile is recognizable to people I already know

## Acceptance Criteria

- **Given** I am on the profile photo step
  **When** I select an image from my device and confirm
  **Then** the cropped image is uploaded and shown as my avatar.

- **Given** I skip the photo step
  **When** I proceed
  **Then** a generated default avatar (initials-based) is used and I can add a photo later from settings.

## Notes
Accept JPEG, PNG, WEBP. Max 10 MB before compression. Crop tool should default to 1:1. NSFW scan runs asynchronously and flags for review without blocking onboarding.
