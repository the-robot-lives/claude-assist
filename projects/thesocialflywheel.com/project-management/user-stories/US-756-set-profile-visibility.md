---
id: US-756
title: "Set Profile Visibility"
slug: set-profile-visibility
personas: [P-001]
epic: "Settings & Preferences"
priority: should-have
complexity: low
tags: [privacy, profile, visibility]
---

# US-756: Set Profile Visibility

## User Story

**As a** bridge-builder
**I want to** control whether my profile is visible to users outside my network
**So that** I can selectively open myself to new connections from discovery.

## Acceptance Criteria

- **Given** I navigate to Privacy Settings
  **When** I toggle profile visibility to "Anyone on Flywheel"
  **Then** users in the Discovery lane can view my profile and request a match.

- **Given** my profile is set to "Mutuals only"
  **When** a non-mutual visits my profile URL
  **Then** they see only my handle and a locked-profile placeholder.

## Notes
Profile visibility is independent of post visibility; a user can share posts publicly while keeping their profile locked.
