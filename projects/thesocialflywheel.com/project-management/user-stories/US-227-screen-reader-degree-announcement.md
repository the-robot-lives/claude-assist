---
id: US-227
title: "Screen Reader Degree Announcement"
slug: screen-reader-degree-announcement
personas: [P-008]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: medium
tags: [accessibility, degrees, a11y]
---

# US-227: Screen Reader Degree Announcement

## User Story

**As an** Accessibility-First user (P-008)
**I want to** have degree information announced by my screen reader whenever I navigate to a user profile or encounter a degree badge
**So that** I receive the same connection context that sighted users get visually

## Acceptance Criteria

- **Given** I navigate to a user profile using a screen reader
  **When** the profile header is read
  **Then** the degree is announced as part of the user's identity region (e.g., "Alice, 2nd-degree mutual")

- **Given** a degree badge is rendered inline in a post or list
  **When** my screen reader focuses the badge element
  **Then** it announces "Nth-degree mutual" (not just the number)

- **Given** a user is outside my web
  **When** their profile is announced
  **Then** the screen reader says "Outside your web" rather than skipping the field

## Notes
Degree badges must use aria-label rather than relying on visible text alone. Test with VoiceOver (iOS/macOS) and TalkBack (Android).
